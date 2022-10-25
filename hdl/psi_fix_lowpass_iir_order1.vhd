------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- purpose	: smoothing block for pre-correction error
-- scalable generically (wd) / real coef parameter 
--                    ____
--	______  X  _ + ___|dff|___________
--	             |    |___|       |
--               |_________ X ____|
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
-- @formatter:off
use work.psi_fix_pkg.all;
-- $$ processes=stimuli,check $$
entity psi_fix_lowpass_iir_order1 is
  generic(
    FSampleHz_g     : real        := 10_000_000.0;                  -- $$constant=100.0e6$$
    FCutoffHz_g     : real        := 30_000.0;                      -- $$constant=1.0e6$$
    InFmt_g         : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 15)'$$
    OutFmt_g        : psi_fix_fmt_t := (1, 0, 15);                  -- $$constant='(1, 0, 14)'$$
    IntFmt_g        : psi_fix_fmt_t := (1, 0, 24);                  -- Number format for calculations, for details see documentation
    CoefFmt_g       : psi_fix_fmt_t := (1, 0, 17);                  -- coef format
    Round_g         : psi_fix_rnd_t := PsiFixRound;                 -- round or trunc
    Sat_g           : psi_fix_sat_t := PsiFixSat;                   -- sat or wrap
    Pipeline_g      : boolean     := True;                          -- True = Optimize for clock speed, False = Optimize for latency	$$ export=true $$
    ResetPolarity_g : std_logic   := '1'                            -- reset polarity active high = '1'
  );
  port(
    clk_i : in  std_logic;                                          -- clock input									$$ type=clk; freq=100e6 $$
    rst_i : in  std_logic;                                          -- sync. reset									$$ type=rst; clk=clk_i $$
    dat_i : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0); -- data in
    vld_i : in  std_logic;                                          -- input valid signal
    dat_o : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);-- data out
    vld_o : out std_logic                                           -- output valid signal
  );
end entity;
-- @formatter:on
architecture rtl of psi_fix_lowpass_iir_order1 is
  --function declaration
  function coef_alpha_func(freq_sampling : real;
                           freq_cut_off  : real) return real is
    variable tau : real;
  begin
    tau := 1.0 / (2.0*MATH_PI*freq_cut_off);
    return exp(-(1.0/freq_sampling)/tau);
  end function;

  --constant computation at compilation process
  constant alpha_raw_c  : real                                                 := coef_alpha_func(FSampleHz_g, FCutoffHz_g);
  constant alpha_c      : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0) := PsiFixFromReal(alpha_raw_c, CoefFmt_g);
  constant beta_c       : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0) := PsiFixFromReal(1.0 - alpha_raw_c, CoefFmt_g);
  --internal signals delaration
  signal mulIn, mulInFF : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal add            : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal fb, fbFF       : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
  signal res            : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  signal strb           : std_logic_vector(0 to 3);

begin
  pipe_gene : if Pipeline_g  generate
    p_filter : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = ResetPolarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0
          strb(0)              <= vld_i;
          mulIn                <= PsiFixMult(dat_i, InFmt_g, beta_c, CoefFmt_g, IntFmt_g, Round_g, Sat_g);
          -- stage 1
          mulInFF              <= mulIn;
          -- stage 2
          add                  <= PsiFixAdd(mulInFF, IntFmt_g, fbFF, IntFmt_g, IntFmt_g, PsiFixTrunc, Sat_g);
          -- stage 3
          res                  <= PsiFixResize(add, IntFmt_g, OutFmt_g, Round_g, Sat_g);
          if strb(2) = '1' then
            fb <= PsiFixMult(add, IntFmt_g, alpha_c, CoefFmt_g, IntFmt_g, Round_g, Sat_g);
          end if;
          -- stage 4
          fbFF                 <= fb;
          -- strobe pipeline				
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    dat_o <= res;
    vld_o <= strb(3);
  end generate;

  nopipe_gene : if Pipeline_g = false generate
    p_filter : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = ResetPolarity_g then
          fb   <= (others => '0');
          strb <= (others => '0');
        else
          -- stage 0 
          strb(0)              <= vld_i;
          mulIn                <= PsiFixMult(dat_i, InFmt_g, beta_c, CoefFmt_g, IntFmt_g, Round_g, Sat_g);
          -- stage 1
          add                  <= PsiFixAdd(mulIn, IntFmt_g, fb, IntFmt_g, IntFmt_g, PsiFixTrunc, Sat_g);
          -- stage 2
          res                  <= PsiFixResize(add, IntFmt_g, OutFmt_g, Round_g, Sat_g);
          if strb(1) = '1' then
            fb <= PsiFixMult(add, IntFmt_g, alpha_c, CoefFmt_g, IntFmt_g, Round_g, Sat_g);
          end if;
          -- strobe pipeline				
          strb(1 to strb'high) <= strb(0 to strb'high - 1);
        end if;

      end if;
    end process p_filter;
    dat_o <= res;
    vld_o <= strb(2);
  end generate;

end architecture;
