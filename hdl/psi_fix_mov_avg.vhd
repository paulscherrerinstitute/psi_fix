------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a moving average with different options for the
-- gain correction (none, rough by shifting, exact by shifting and multiplication).
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

-- $$ processes=stim,check $$
entity psi_fix_mov_avg is
  generic(
    in_fmt_g    : psi_fix_fmt_t;                                        -- input format   $$ constant=(1,0,10) $$
    out_fmt_g   : psi_fix_fmt_t;                                        -- output format  $$ constant=(1,1,12) $$
    taps_g      : positive;                                             -- number of Taps $$ constant=7 $$
    gain_corr_g : string      := "ROUGH";                               -- gain coorection either:= ROUGH, NONE or EXACT $$ export=true $$
    round_g     : psi_fix_rnd_t := psi_fix_round;                       -- round or trunc
    sat_g       : psi_fix_sat_t := psi_fix_sat;                         -- saturate or wrap
    out_regs_g  : natural     := 1                                      -- add number of output register $$ export=true $$
  );
  port(
    -- Control Signals
    clk_i : in  std_logic;                                              -- system clock $$ type=clk; freq=100e6 $$
    rst_i : in  std_logic;                                              -- system reset $$ type=rst; clk=clk_i $$
    dat_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);  -- data input
    vld_i : in  std_logic;                                              -- valid input sampling frequency
    dat_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- data output
    vld_o : out std_logic                                               -- valid output sampling frequency
  );
end entity;

architecture rtl of psi_fix_mov_avg is

  -- Constants
  constant Gain_c           : integer := taps_g;
  constant AdditionalBits_c : integer := log2ceil(Gain_c);

  -- Formats
  constant DiffFmt_c   : psi_fix_fmt_t := (1, in_fmt_g.I + 1, in_fmt_g.F);
  constant SumFmt_c    : psi_fix_fmt_t := (1, in_fmt_g.I + AdditionalBits_c, in_fmt_g.F);
  constant GcInFmt_c   : psi_fix_fmt_t := (1, in_fmt_g.I, work.psi_common_math_pkg.min(24 - in_fmt_g.I, SumFmt_c.F + AdditionalBits_c));
  constant GcCoefFmt_c : psi_fix_fmt_t := (0, 1, 16);

  -- Gain correction coefficient calculation
  constant Gc_c : std_logic_vector(psi_fix_size(GcCoefFmt_c) - 1 downto 0) := psi_fix_from_real(2.0**real(AdditionalBits_c) / real(Gain_c), GcCoefFmt_c);

  -- types
  type OutReg_t is array (natural range <>) of std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    Vld         : std_logic_vector(0 to 2);
    Diff_0      : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
    Sum_1       : std_logic_vector(psi_fix_size(SumFmt_c) - 1 downto 0);
    RoughCorr_2 : std_logic_vector(psi_fix_size(GcInFmt_c) - 1 downto 0);
    OutRegs     : OutReg_t(0 to out_regs_g - 1);
    VldOutRegs  : std_logic_vector(0 to out_regs_g - 1);
  end record;
  signal r, r_next : two_process_r;

  -- Component instantiation signals
  signal DataDel : std_logic_vector(dat_i'range);

begin

  assert gain_corr_g = "NONE" or gain_corr_g = "ROUGH" or gain_corr_g = "EXACT" report "###ERROR###: psi_fix_mov_avg: gain_corr_g must be NONE, ROUGH or EXACT" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i, dat_i, DataDel)
    variable v         : two_process_r;
    variable CalcOut_v : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    variable CalcVld_v : std_logic;
  begin
    -- Variable initialization
    CalcOut_v := (others => '0');
    CalcVld_v := '0';

    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high)                      := r.Vld(r.Vld'low to r.Vld'high - 1);
    v.VldOutRegs(v.VldOutRegs'low + 1 to v.VldOutRegs'high) := r.VldOutRegs(r.VldOutRegs'low to r.VldOutRegs'high - 1);
    v.OutRegs(v.OutRegs'low + 1 to v.OutRegs'high)          := r.OutRegs(r.OutRegs'low to r.OutRegs'high - 1);

    -- *** Stage 0 ***
    v.Diff_0 := psi_fix_sub(dat_i, in_fmt_g, DataDel, in_fmt_g, DiffFmt_c, psi_fix_trunc, psi_fix_wrap);
    v.Vld(0) := vld_i;

    -- *** Stage 1 ***
    if r.Vld(0) = '1' then
      v.Sum_1 := psi_fix_add(r.Sum_1, SumFmt_c, r.Diff_0, DiffFmt_c, SumFmt_c, psi_fix_trunc, psi_fix_wrap);
    end if;

    -- *** Stage 2 ***
    if gain_corr_g = "NONE" then
      CalcOut_v := psi_fix_resize(r.Sum_1, SumFmt_c, out_fmt_g, round_g, sat_g);
      CalcVld_v := r.Vld(1);
    elsif gain_corr_g = "ROUGH" then
      CalcOut_v := psi_fix_shift_right(r.Sum_1, SumFmt_c, AdditionalBits_c, AdditionalBits_c, out_fmt_g, round_g, sat_g);
      CalcVld_v := r.Vld(1);
    else
      v.RoughCorr_2 := psi_fix_shift_right(r.Sum_1, SumFmt_c, AdditionalBits_c, AdditionalBits_c, GcInFmt_c, psi_fix_trunc, psi_fix_wrap);
    end if;

    -- *** Stage 3 ***
    if gain_corr_g = "EXACT" then
      CalcOut_v := psi_fix_mult(r.RoughCorr_2, GcInFmt_c, Gc_c, GcCoefFmt_c, out_fmt_g, round_g, sat_g);
      CalcVld_v := r.Vld(2);
    end if;

    -- *** Output Registers ***
    if out_regs_g = 0 then
      vld_o <= CalcVld_v;
      dat_o <= CalcOut_v;
    else
      v.OutRegs(0)    := CalcOut_v;
      v.VldOutRegs(0) := CalcVld_v;
      dat_o           <= r.OutRegs(r.OutRegs'high);
      vld_o           <= r.VldOutRegs(r.VldOutRegs'high);
    end if;

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
      if rst_i = '1' then
        r.Vld        <= (others => '0');
        r.VldOutRegs <= (others => '0');
        r.Sum_1      <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------
  i_del : entity work.psi_common_delay
    generic map(
      width_g    => psi_fix_size(in_fmt_g),
      delay_g    => taps_g,
      resource_g => "AUTO",
      rst_state_g => True
    )
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      dat_i  => dat_i,
      vld_i   => vld_i,
      dat_o => DataDel
    );

end architecture;
