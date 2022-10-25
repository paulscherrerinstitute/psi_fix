------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Add or Sub of two complex numbers

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
-- @formatter:off
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim, resp $$
entity psi_fix_complex_addsub is
  generic(RstPol_g   : std_logic   := '1';                                      -- set reset polarity                $$ constant='1' $$
          Pipeline_g : boolean     := false;                                    -- when false 3 pipes stages, when false 6 pipes (increase Fmax)			$$ export=true $$
          InAFmt_g   : psi_fix_fmt_t := (1, 0, 15);                             -- Input A Fixed Point format   $$ constant=(1,0,15) $$
          InBFmt_g   : psi_fix_fmt_t := (1, 0, 24);                             -- Input B Fixed Point format   $$ constant=(1,0,24) $$
          OutFmt_g   : psi_fix_fmt_t := (1, 0, 20);                             -- Output Fixed Point format    $$ constant=(1,0,20) $$
          Round_g    : psi_fix_rnd_t := PsiFixRound;                            -- Round or trunc  $$ constant=PsiFixRound $$
          Sat_g      : psi_fix_sat_t := PsiFixSat;                              -- Adder or Subtracter  $$ constant=PsiFixSat $$
          AddSub_g   : string      := "ADD");
  port(clk_i         : in  std_logic;                                           -- clk    $$ type=clk; freq=100e6 $$
       rst_i         : in  std_logic;                                           -- sync. rst    $$ type=rst; clk=clk_i $$
       dat_inA_inp_i : in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- Inphase input of signal A
       dat_inA_qua_i : in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- Quadrature input of signal A
       dat_inB_inp_i : in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- Inphase input of signal B
       dat_inB_qua_i : in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- Quadrature input of signal B
       vld_i         : in  std_logic;                                           -- strobe input
       dat_out_inp_o : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output I
       dat_out_qua_o : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output Q
       vld_o         : out std_logic                                            -- strobe output
      );
begin
  assert AddSub_g = "ADD" or AddSub_g = "SUB"
  report "AddSub generic value is wrong! must be ADD or SUB" severity error;
end entity;
-- @formatter:on
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_complex_addsub is

  constant SumFmt_c : psi_fix_fmt_t := (max(InAFmt_g.S, InBFmt_g.S), max(InAFmt_g.I, InBFmt_g.I) + 1, max(InAFmt_g.F, InBFmt_g.F));
  constant RndFmt_c : psi_fix_fmt_t := (SumFmt_c.S, SumFmt_c.I + 1, OutFmt_g.F);

  -- Two process method
  type two_process_r is record
    -- Registers always present
    Vld   : std_logic_vector(0 to 3);

    AddII : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);
    AddQQ : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);

    OutI  : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    OutQ  : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    -- Additional registers for pipelined version
    AiIn  : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
    AqIn  : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
    BiIn  : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
    BqIn  : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
    --
    RndI  : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
    RndQ  : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(r, dat_inA_inp_i, dat_inA_qua_i, dat_inB_inp_i, dat_inB_qua_i, vld_i)
    variable v : two_process_r;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Vld Handling ***
    v.Vld(0)      := vld_i;
    v.Vld(1 to 3) := r.Vld(0 to 2);

    -- *** pipeline ***
    if Pipeline_g then
      v.AiIn := dat_inA_inp_i;
      v.AqIn := dat_inA_qua_i;
      v.BiIn := dat_inB_inp_i;
      v.BqIn := dat_inB_qua_i;
    end if;
    --*** Add or Sub ***
    if AddSub_g = "ADD" then
      v.AddII := PsiFixAdd(choose(Pipeline_g, r.AiIn, dat_inA_inp_i), InAFmt_g,
                           choose(Pipeline_g, r.BiIn, dat_inB_inp_i), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
      v.AddQQ := PsiFixAdd(choose(Pipeline_g, r.AqIn, dat_inA_qua_i), InAFmt_g,
                           choose(Pipeline_g, r.BqIn, dat_inB_qua_i), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
    elsif AddSub_g = "SUB" then
      v.AddII := PsiFixSub(choose(Pipeline_g, r.AiIn, dat_inA_inp_i), InAFmt_g,
                           choose(Pipeline_g, r.BiIn, dat_inB_inp_i), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
      v.AddQQ := PsiFixSub(choose(Pipeline_g, r.AqIn, dat_inA_qua_i), InAFmt_g,
                           choose(Pipeline_g, r.BqIn, dat_inB_qua_i), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
    end if;
    -- *** Resize ***
    if Pipeline_g then
      v.RndI := PsiFixResize(r.AddII, SumFmt_c, RndFmt_c, Round_g, PsiFixWrap); -- Never wrapps
      v.RndQ := PsiFixResize(r.AddQQ, SumFmt_c, RndFmt_c, Round_g, PsiFixWrap); -- Never wrapps
      v.OutI := PsiFixResize(r.RndI, RndFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
      v.OutQ := PsiFixResize(r.RndQ, RndFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
    else
      v.OutI := PsiFixResize(r.AddII, SumFmt_c, OutFmt_g, Round_g, Sat_g);
      v.OutQ := PsiFixResize(r.AddQQ, SumFmt_c, OutFmt_g, Round_g, Sat_g);
    end if;

    -- *** Assign to signal ***
    r_next <= v;

  end process;

  -- *** Outputs ***
  g_pl : if Pipeline_g generate
    vld_o <= r.Vld(3);
  end generate;
  g_npl : if not Pipeline_g generate
    vld_o <= r.Vld(1);
  end generate;
  dat_out_inp_o <= r.OutI;
  dat_out_qua_o <= r.OutQ;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = RstPol_g then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
