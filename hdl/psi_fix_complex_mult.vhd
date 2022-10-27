------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Multiplication of two complex numbers
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
-- @formatter:off
-- $$ processes=stim, resp $$
entity psi_fix_complex_mult is
  generic(
    rst_pol_g      : std_logic   := '1';                                      -- set reset polarity                             $$ constant='1' $$
    pipeline_g    : boolean     := false;                                    -- when false 3 pipes stages, when false 6 pipes (increase Fmax)			$$ export=true $$
    in_a_fmt_g      : psi_fix_fmt_t := (1, 0, 15);                             -- Input A Fixed Point format                     $$ constant=(1,0,15) $$
    in_b_fmt_g      : psi_fix_fmt_t := (1, 0, 24);                             -- Input B Fixed Point format                     $$ constant=(1,0,24) $$
    internal_fmt_g : psi_fix_fmt_t := (1, 1, 24);                             -- Internal Calc. Fixed Point format              $$ constant=(1,1,24) $$
    out_fmt_g      : psi_fix_fmt_t := (1, 0, 20);                             -- Output Fixed Point format                      $$ constant=(1,0,20) $$
    round_g       : psi_fix_rnd_t := psi_fix_round;                            -- Trunc or Round                                 $$ constant=psi_fix_round $$
    sat_g         : psi_fix_sat_t := psi_fix_sat;                              -- Sat or wrap                                    $$ constant=psi_fix_sat $$
    in_a_is_cplx_g   : boolean     := true;                                     -- Complex number?
    in_b_is_cplx_g   : boolean     := true                                      -- Complex number?
  );
  port(
    clk_i         : in  std_logic;                                           -- clk        $$ type=clk; freq=100e6 $$
    rst_i         : in  std_logic;                                           -- sync. rst  $$ type=rst; clk=clk_i $$
    dat_inA_inp_i : in  std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0); -- Inphase input of signal A
    dat_inA_qua_i : in  std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0); -- Quadrature input of signal A
    dat_inB_inp_i : in  std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0); -- Inphase input of signal B
    dat_inB_qua_i : in  std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0); -- Quadrature input of signal B
    vld_i         : in  std_logic;                                           -- strobe input

    dat_inp_o     : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- data output I
    dat_qua_o     : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- data output Q
    vld_o         : out std_logic                                            -- strobe output
  );
end entity;
-- @formatter:on
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_complex_mult is

  constant SumFmt_c : psi_fix_fmt_t := (internal_fmt_g.S, internal_fmt_g.I + 1, internal_fmt_g.F);
  constant RndFmt_c : psi_fix_fmt_t := (SumFmt_c.S, SumFmt_c.I + 1, out_fmt_g.F);

  -- Two process method
  type two_process_r is record
    -- Registers always present
    Vld    : std_logic_vector(0 to 5);
    MultIQ : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MultQI : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MultII : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MultQQ : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    SumI   : std_logic_vector(psi_fix_size(SumFmt_c) - 1 downto 0);
    SumQ   : std_logic_vector(psi_fix_size(SumFmt_c) - 1 downto 0);
    OutI   : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutQ   : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    -- Additional registers for pipelined version
    AiIn   : std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0);
    AqIn   : std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0);
    BiIn   : std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0);
    BqIn   : std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0);
    MrIQ   : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MrQI   : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MrII   : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    MrQQ   : std_logic_vector(psi_fix_size(internal_fmt_g) - 1 downto 0);
    RndI   : std_logic_vector(psi_fix_size(RndFmt_c) - 1 downto 0);
    RndQ   : std_logic_vector(psi_fix_size(RndFmt_c) - 1 downto 0);
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
    v.Vld(1 to 5) := r.Vld(0 to 4);

    -- *** Multiplications ***
    if pipeline_g then
      v.AiIn := dat_inA_inp_i;
      v.AqIn := dat_inA_qua_i;
      v.BiIn := dat_inB_inp_i;
      v.BqIn := dat_inB_qua_i;
      v.MrIQ := r.MultIQ;
      v.MrQI := r.MultQI;
      v.MrII := r.MultII;
      v.MrQQ := r.MultQQ;
    end if;
    v.MultII := psi_fix_mult(choose(pipeline_g, r.AiIn, dat_inA_inp_i), in_a_fmt_g,
                           choose(pipeline_g, r.BiIn, dat_inB_inp_i), in_b_fmt_g, internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    if in_b_is_cplx_g then
      v.MultIQ := psi_fix_mult(choose(pipeline_g, r.AiIn, dat_inA_inp_i), in_a_fmt_g,
                             choose(pipeline_g, r.BqIn, dat_inB_qua_i), in_b_fmt_g, internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      v.MultIQ := (others => '0');
    end if;
    if in_a_is_cplx_g then
      v.MultQI := psi_fix_mult(choose(pipeline_g, r.AqIn, dat_inA_qua_i), in_a_fmt_g,
                             choose(pipeline_g, r.BiIn, dat_inB_inp_i), in_b_fmt_g, internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      v.MultQI := (others => '0');
    end if;
    if in_a_is_cplx_g and in_b_is_cplx_g then
      v.MultQQ := psi_fix_mult(choose(pipeline_g, r.AqIn, dat_inA_qua_i), in_a_fmt_g,
                             choose(pipeline_g, r.BqIn, dat_inB_qua_i), in_b_fmt_g, internal_fmt_g, psi_fix_trunc, psi_fix_wrap);
    else
      v.MultQQ := (others => '0');
    end if;

    -- *** Additions ***
    v.SumI := psi_fix_sub(choose(pipeline_g, r.MrII, r.MultII), internal_fmt_g,
                        choose(pipeline_g, r.MrQQ, r.MultQQ), internal_fmt_g, SumFmt_c, psi_fix_trunc, psi_fix_wrap); -- no saturation/truncation occurs, format sufficient
    v.SumQ := psi_fix_add(choose(pipeline_g, r.MrIQ, r.MultIQ), internal_fmt_g,
                        choose(pipeline_g, r.MrQI, r.MultQI), internal_fmt_g, SumFmt_c, psi_fix_trunc, psi_fix_wrap); -- no saturation/truncation occurs, format sufficient

    -- *** Resize ***
    if pipeline_g then
      v.RndI := psi_fix_resize(r.SumI, SumFmt_c, RndFmt_c, round_g, psi_fix_wrap); -- Never wrapps
      v.RndQ := psi_fix_resize(r.SumQ, SumFmt_c, RndFmt_c, round_g, psi_fix_wrap); -- Never wrapps
      v.OutI := psi_fix_resize(r.RndI, RndFmt_c, out_fmt_g, psi_fix_trunc, sat_g);
      v.OutQ := psi_fix_resize(r.RndQ, RndFmt_c, out_fmt_g, psi_fix_trunc, sat_g);
    else
      v.OutI := psi_fix_resize(r.SumI, SumFmt_c, out_fmt_g, round_g, sat_g);
      v.OutQ := psi_fix_resize(r.SumQ, SumFmt_c, out_fmt_g, round_g, sat_g);
    end if;

    -- *** Assign to signal ***
    r_next <= v;

  end process;

  -- *** Outputs ***
  g_pl : if pipeline_g generate
    vld_o <= r.Vld(5);
  end generate;
  g_npl : if not pipeline_g generate
    vld_o <= r.Vld(2);
  end generate;
  dat_inp_o <= r.OutI;
  dat_qua_o <= r.OutQ;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
