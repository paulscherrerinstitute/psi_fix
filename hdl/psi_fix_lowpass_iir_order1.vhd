------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- purpose	: smoothing block for pre-correction error	
--			  scalable generically (wd) / real coef parameter 		
--				                   ____
--				______  X  _ + ___|dff|___________
--				  	     |        |___|   |
--						     |_________ X ____|
--	                    

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stimuli,check $$
entity psi_fix_lowpass_iir_order1 is
  generic(
    CoefAuto_g      : boolean     := true;          -- if true coef auto computed else enter A/B coef
    FSampleHz_g     : real        := 10_000_000.0;  -- $$constant=100.0e6$$
    FCutoffHz_g     : real        := 30_000.0;      -- $$constant=1.0e6$$
    InFmt_g         : PsiFixFmt_t := (1, 0, 15);    -- $$constant='(1, 0, 15)'$$
    OutFmt_g        : PsiFixFmt_t := (1, 0, 15);    -- $$constant='(1, 0, 14)'$$
    IntFmt_g        : PsiFixFmt_t := (1, 0, 24);    -- Number format for calculations, for details see documentation
    CoefFmtA_g      : PsiFixFmt_t := (1, 0, 17);    -- insert coef Alpha
    CoefFmtB_g      : PsiFixFmt_t := (1, 0, 17);    -- insert coef Beta
    Round_g         : PsiFixRnd_t := PsiFixRound;
    Sat_g           : PsiFixSat_t := PsiFixSat;
    Pipeline_g      : boolean     := True;          -- True = Optimize for clock speed, False = Optimize for latency	$$ export=true $$
    ResetPolarity_g : std_logic   := '1'
  );
  port(
    InClk   : in  std_logic;            -- clock input									$$ type=clk; freq=100e6 $$
    InRst   : in  std_logic;            -- sync. reset									$$ type=rst; clk=clk_i $$
    InVld   : in  std_logic;            -- input strobe
    InDat   : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0); -- data in
    InCoefA : in  std_logic_vector(PsiFixSize(CoefFmtA_g) - 1 downto 0); -- coef A
    InCoefB : in  std_logic_vector(PsiFixSize(CoefFmtB_g) - 1 downto 0); -- coef B
    OutVld  : out std_logic;            -- output strobe
    OutDat  : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0) -- data out
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_lowpass_iir_order1 is
  --function declaration
  function coef_alpha_func(freq_sampling : real;
                           freq_cut_off  : real) return real is
    variable tau : real;
  begin
    tau := 1.0 / (2.0 * MATH_PI * freq_cut_off);
    return exp(-(1.0 / freq_sampling) / tau);
  end function;

  --constant computation at compilation process
  constant alpha_raw_c  : real                                                  := coef_alpha_func(FSampleHz_g, FCutoffHz_g);
  constant alpha_c      : std_logic_vector(PsiFixSize(CoefFmtA_g) - 1 downto 0) := PsiFixFromReal(alpha_raw_c, CoefFmtA_g);
  constant beta_c       : std_logic_vector(PsiFixSize(CoefFmtB_g) - 1 downto 0) := PsiFixFromReal(1.0 - alpha_raw_c, CoefFmtB_g);
  --internal signals delaration
  signal mulIn, mulInFF : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal add            : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal fb, fbFF       : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal res            : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  signal strb           : std_logic_vector(0 to 3);

begin
  pipe_gene : if Pipeline_g = true generate
    p_filter : process(InClk)
    begin
      if rising_edge(InClk) then
        if InRst = ResetPolarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0
          strb(0) <= InVld;
          if CoefAuto_g then
            mulIn <= PsiFixMult(InDat, InFmt_g, beta_c, CoefFmtB_g, IntFmt_g, Round_g, Sat_g);
          else
            mulIn <= PsiFixMult(InDat, InFmt_g, InCoefB, CoefFmtB_g, IntFmt_g, Round_g, Sat_g);
          end if;
          -- stage 1
          mulInFF <= mulIn;
          -- stage 2
          add     <= PsiFixAdd(mulInFF, IntFmt_g, fbFF, IntFmt_g, IntFmt_g, PsiFixTrunc, Sat_g);
          -- stage 3
          res     <= PsiFixResize(add, IntFmt_g, OutFmt_g, Round_g, Sat_g);
          if strb(2) = '1' then
            if CoefAuto_g then
              fb <= PsiFixMult(add, IntFmt_g, alpha_c, CoefFmtA_g, IntFmt_g, Round_g, Sat_g);
            else
              fb <= PsiFixMult(add, IntFmt_g, InCoefA, CoefFmtA_g, IntFmt_g, Round_g, Sat_g);
            end if;
          end if;
          -- stage 4
          fbFF    <= fb;

          -- strobe pipeline				
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    OutDat <= res;
    OutVld <= strb(3);
  end generate;

  nopipe_gene : if Pipeline_g = false generate
    p_filter : process(InClk)
    begin
      if rising_edge(InClk) then
        if InRst = ResetPolarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0 
          strb(0) <= InVld;
          if CoefAuto_g then
            mulIn <= PsiFixMult(InDat, InFmt_g, beta_c, CoefFmtB_g, IntFmt_g, Round_g, Sat_g);
          else
            mulIn <= PsiFixMult(InDat, InFmt_g, InCoefB, CoefFmtB_g, IntFmt_g, Round_g, Sat_g);
          end if;
          -- stage 1
          add     <= PsiFixAdd(mulIn, IntFmt_g, fb, IntFmt_g, IntFmt_g, PsiFixTrunc, Sat_g);
          -- stage 2
          res     <= PsiFixResize(add, IntFmt_g, OutFmt_g, Round_g, Sat_g);
          if strb(1) = '1' then
            if CoefAuto_g then
              fb <= PsiFixMult(add, IntFmt_g, alpha_c, CoefFmtA_g, IntFmt_g, Round_g, Sat_g);
            else
              fb <= PsiFixMult(add, IntFmt_g, InCoefA, CoefFmtA_g, IntFmt_g, Round_g, Sat_g);
            end if;
          end if;

          -- strobe pipeline				
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    OutDat <= res;
    OutVld <= strb(2);
  end generate;

end architecture;
