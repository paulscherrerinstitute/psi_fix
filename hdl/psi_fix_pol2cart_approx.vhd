------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
-- @formatter:off
-- $$ processes=stim, resp $$
entity psi_fix_pol2cart_approx is
  generic(
    in_abs_fmt_g   : psi_fix_fmt_t := (0, 0, 15);     -- Must be unsigned   $$ constant=(0,0,16) $$
    in_angle_fmt_g : psi_fix_fmt_t := (0, 0, 15);     -- Must be unsigned   $$ constant=(0,0,15) $$
    out_fmt_g      : psi_fix_fmt_t := (1, 0, 16);     -- Usually signed      $$ constant=(1,0,16) $$
    round_g        : psi_fix_rnd_t := psi_fix_round;  -- round or trunc
    sat_g          : psi_fix_sat_t := psi_fix_sat;    -- sat or wrap
    rst_pol_g      : std_logic     :='1'              -- reset polarity
  );
  port(
    -- Control Signals
    clk_i     : in  std_logic;                                                  -- clk system $$ type=clk; freq=100e6 $$
    rst_i     : in  std_logic;                                                  -- rst system $$ type=rst; clk=clk_i $$
    dat_abs_i : in  std_logic_vector(psi_fix_size(in_abs_fmt_g) - 1 downto 0);  -- data amplitude
    dat_ang_i : in  std_logic_vector(psi_fix_size(in_angle_fmt_g) - 1 downto 0);-- data phase
    vld_i     : in  std_logic;                                                  -- valid input signal freqeucy sampling
    dat_inp_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);     -- data inphase
    dat_qua_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);     -- data quadrature
    vld_o     : out std_logic                                                   -- valid output
  );
end entity;
-- @formatter:on
architecture rtl of psi_fix_pol2cart_approx is
  -- Constants
  constant SinOutFmt_c : psi_fix_fmt_t                                           := (1, 0, 17);
  constant SinInFmt_c  : psi_fix_fmt_t                                           := (0, 0, 20);
  constant MultFmt_c   : psi_fix_fmt_t                                           := (1, in_abs_fmt_g.I + SinOutFmt_c.I, in_abs_fmt_g.F + SinOutFmt_c.F);
  constant CosOffs_c   : std_logic_vector(psi_fix_size(SinInFmt_c) - 1 downto 0) := psi_fix_from_real(0.25, SinInFmt_c);

  -- Types
  type Abs_t is array (natural range <>) of std_logic_vector(dat_abs_i'range);

  -- Two Process Method
  type two_process_r is record
    VldIn      : std_logic_vector(0 to 10);
    AbsPipe    : Abs_t(0 to 8);
    PhaseIn_0  : std_logic_vector(psi_fix_size(in_angle_fmt_g) - 1 downto 0);
    PhaseSin_1 : std_logic_vector(psi_fix_size(SinInFmt_c) - 1 downto 0);
    PhaseCos_1 : std_logic_vector(psi_fix_size(SinInFmt_c) - 1 downto 0);
    MultI_9    : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
    MultQ_9    : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
    OutI_10    : std_logic_vector(dat_inp_o'range);
    OutQ_10    : std_logic_vector(dat_qua_o'range);
  end record;
  signal r, r_next : two_process_r;

  -- Component Connection Signals
  signal SinVld_8, CosVld_8   : std_logic;
  signal SinData_8, CosData_8 : std_logic_vector(psi_fix_size(SinOutFmt_c) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  assert in_angle_fmt_g.S = 0 report "psi_fix_pol2cart_approx: in_angle_fmt_g must be unsigned" severity error;
  assert in_abs_fmt_g.S = 0 report "psi_fix_pol2cart_approx: in_angle_fmt_g must be unsigned" severity error;
  assert in_angle_fmt_g.I <= 0 report "psi_fix_pol2cart_approx: in_angle_fmt_g must be (1,0,x)" severity error;

  p_assert : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        assert SinVld_8 = CosVld_8 report "###ERROR###: psi_fix_pol2cart_approx: SinVld / CosVld mismatch" severity error;
        assert SinVld_8 = r.VldIn(8) report "###ERROR###: psi_fix_pol2cart_approx: SinVld / Pipeline Vld mismatch" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i, dat_abs_i, dat_ang_i, SinVld_8, CosVld_8, SinData_8, CosData_8)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.VldIn(v.VldIn'low + 1 to v.VldIn'high)       := r.VldIn(r.VldIn'low to r.VldIn'high - 1);
    v.AbsPipe(v.AbsPipe'low + 1 to v.AbsPipe'high) := r.AbsPipe(r.AbsPipe'low to r.AbsPipe'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.VldIn(0)   := vld_i;
    v.AbsPipe(0) := dat_abs_i;
    v.PhaseIn_0  := dat_ang_i;

    -- *** Stage 1 ***
    -- Sine and cosine phase
    v.PhaseSin_1 := psi_fix_resize(r.PhaseIn_0, in_angle_fmt_g, SinInFmt_c, round_g, psi_fix_wrap);
    v.PhaseCos_1 := psi_fix_add(r.PhaseIn_0, in_angle_fmt_g,
                              CosOffs_c, SinInFmt_c,
                              SinInFmt_c, round_g, psi_fix_wrap);

    -- *** Stages 2 - 8 ***
    -- Reserved for Linear approximation

    -- *** Stage 9 ***
    -- Output Multiplications
    v.MultI_9 := psi_fix_mult(r.AbsPipe(8), in_abs_fmt_g, CosData_8, SinOutFmt_c, MultFmt_c, psi_fix_trunc, psi_fix_wrap); -- Format is sufficient, so no rounding/truncation occures
    v.MultQ_9 := psi_fix_mult(r.AbsPipe(8), in_abs_fmt_g, SinData_8, SinOutFmt_c, MultFmt_c, psi_fix_trunc, psi_fix_wrap); -- Format is sufficient, so no rounding/truncation occures

    -- *** Stage 10 ***
    -- Output Format conversion
    v.OutI_10 := psi_fix_resize(r.MultI_9, MultFmt_c, out_fmt_g, round_g, sat_g);
    v.OutQ_10 := psi_fix_resize(r.MultQ_9, MultFmt_c, out_fmt_g, round_g, sat_g);

    -- *** Outputs ***
    vld_o     <= r.VldIn(10);
    dat_qua_o <= r.OutQ_10;
    dat_inp_o <= r.OutI_10;

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.VldIn <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------
  i_sincos : entity work.psi_fix_lin_approx_sin18b_dual
    generic map(rst_pol_g => rst_pol_g)
    port map(
      -- Control Signals
      clk_i      => clk_i,
      rst_i      => rst_i,
      -- Input
      vld_a_i   => r.VldIn(1),
      dat_a_i  => r.PhaseSin_1,
      vld_b_i   => r.VldIn(1),
      dat_b_i  => r.PhaseCos_1,
      -- Output
      vld_a_o  => SinVld_8,
      dat_a_o => SinData_8,
      vld_b_o  => CosVld_8,
      dat_b_o => CosData_8
    );

end architecture;
