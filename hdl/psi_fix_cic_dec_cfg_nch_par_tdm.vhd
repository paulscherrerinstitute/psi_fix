------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Paramter Calculations
------------------------------------------------------------------------------
-- CIC_GAIN = (Ratio*DifDelay)^Order
-- CIC_GROWTH = ceil(log2(CIC_GAIN))
-- SHIFT = CIC_GROWTH         --> Apply this to CfgShift
-- GAINCORR = 2^CIC_GROWTH/CIC_GAIN   --> Apply this to CfgGainCorr
------------------------------------------------------------------------------

entity psi_fix_cic_dec_cfg_nch_par_tdm is
  generic(
    channels_g       : integer              := 3; -- Min. 2
    order_g          : integer              := 4; -- filter order
    max_ratio_g      : natural              := 12; -- maximaum decimation ratio
    diff_delay_g     : natural range 1 to 2 := 1; -- differential delay
    in_fmt_g         : psi_fix_fmt_t        := (1, 0, 15); -- input fomrat FP
    out_fmt_g        : psi_fix_fmt_t        := (1, 0, 15); -- output fromat FP
    rst_pol_g        : std_logic            := '1'; -- reset polarity active high ='1'
    auto_gain_corr_g : boolean              := True -- Use CfgGainCorr for fine-grained gain correction (beyond pure shifting)
  );
  port(
    -- Control Signals
    clk_i           : in  std_logic;    -- clk system
    rst_i           : in  std_logic;    -- rst system
    -- Configuration (only change when in reset!)
    cfg_ratio_i     : in  std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0); -- Ratio-1 (0 --> no decimation, 3 --> decimation by 4)
    cfg_shift_i     : in  std_logic_vector(7 downto 0); -- Shifting by more than 255 bits is not supported, this would lead to timing issues anyways
    cfg_gain_corr_i : in  std_logic_vector(16 downto 0); -- Gain correction factor in format [0,1,16]
    -- Data Ports
    dat_i           : in  std_logic_vector(psi_fix_size(in_fmt_g) * channels_g - 1 downto 0); -- data input
    vld_i           : in  std_logic;    -- valid input
    dat_o           : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- data output
    vld_o           : out std_logic;    -- valid otuput
    -- Status output
    busy_o          : out std_logic     --  busy signal output active high
  );
end entity;

architecture rtl of psi_fix_cic_dec_cfg_nch_par_tdm is
  -- Constants
  constant MaxCicGain_c    : real          := (real(max_ratio_g) * real(diff_delay_g))**real(order_g);
  constant MaxCicAddBits_c : integer       := log2ceil(MaxCicGain_c - 0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
  constant MaxShift_c      : integer       := MaxCicAddBits_c;
  constant AccuFmt_c       : psi_fix_fmt_t := (in_fmt_g.S, in_fmt_g.I + MaxCicAddBits_c, in_fmt_g.F);
  constant DiffFmt_c       : psi_fix_fmt_t := (out_fmt_g.S, in_fmt_g.I, out_fmt_g.F + order_g + 1);
  constant GcInFmt_c       : psi_fix_fmt_t := (1, out_fmt_g.I, work.psi_common_math_pkg.min(24 - out_fmt_g.I, DiffFmt_c.F));
  constant GcCoefFmt_c     : psi_fix_fmt_t := (0, 1, 16);
  constant GcMultFmt_c     : psi_fix_fmt_t := (1, GcInFmt_c.I + GcCoefFmt_c.I, GcInFmt_c.F + GcCoefFmt_c.F);
  constant SftFmt_c        : psi_fix_fmt_t := (AccuFmt_c.S, AccuFmt_c.I, max(AccuFmt_c.F, DiffFmt_c.F));

  -- Types
  type AccuStage_t is array (natural range <>) of std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  type Accus_t is array (natural range <>) of AccuStage_t(0 to channels_g - 1);
  type Diff_t is array (natural range <>) of std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
  type InputStage_t is array (natural range <>) of std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    -- GainCorr Registers
    GcCoef      : std_logic_vector(psi_fix_size(GcCoefFmt_c) - 1 downto 0);
    -- Accu Section
    Input_0     : InputStage_t(channels_g - 1 downto 0);
    VldAccu     : std_logic_vector(0 to order_g);
    Accu        : Accus_t(1 to order_g);
    Rcnt        : integer range 0 to max_ratio_g - 1;
    SftVldCnt   : unsigned(4 downto 0); -- Maximum shift is 255
    -- Diff Section
    VldParTdm   : std_logic;
    VldDiff     : std_logic_vector(1 to order_g);
    DiffVal     : Diff_t(1 to order_g);
    -- GC Stages
    GcVld       : std_logic_vector(0 to 2);
    GcIn_0      : std_logic_vector(psi_fix_size(GcInFmt_c) - 1 downto 0);
    GcMult_1    : std_logic_vector(psi_fix_size(GcMultFmt_c) - 1 downto 0);
    GcOut_2     : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    -- Output
    Outp        : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutVld      : std_logic;
    -- Status
    CalcOngoing : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- Component Connection Signals
  signal ParTdmIn     : std_logic_vector(psi_fix_size(AccuFmt_c) * channels_g - 1 downto 0);
  signal ParTdmOut    : std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  signal ParTdmOutVld : std_logic;
  signal DiffIn_0     : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
  signal VldDiff_0    : std_logic;
  signal DiffDel      : Diff_t(0 to order_g - 1);

  signal ShiftSel     : std_logic_vector(log2ceil(MaxShift_c + 1) - 1 downto 0);
  signal ShiftVld     : std_logic;
  signal ShiftDataIn  : std_logic_vector(psi_fix_size(SftFmt_c) - 1 downto 0);
  signal ShiftDataOut : std_logic_vector(psi_fix_size(SftFmt_c) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i, DiffIn_0, VldDiff_0, DiffDel, cfg_ratio_i, ParTdmOutVld, ShiftVld, cfg_gain_corr_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.VldAccu(v.VldAccu'low + 1 to v.VldAccu'high) := r.VldAccu(r.VldAccu'low to r.VldAccu'high - 1);
    v.VldDiff(v.VldDiff'low + 1 to v.VldDiff'high) := r.VldDiff(r.VldDiff'low to r.VldDiff'high - 1);
    v.GcVld(v.GcVld'low + 1 to v.GcVld'high)       := r.GcVld(r.GcVld'low to r.GcVld'high - 1);

    -- *** Stage Accu 0 ***
    -- Input Registers
    v.VldAccu(0) := vld_i;
    for ch in 0 to channels_g - 1 loop
      v.Input_0(ch) := dat_i(psi_fix_size(in_fmt_g) * (ch + 1) - 1 downto psi_fix_size(in_fmt_g) * ch);
    end loop;

    -- *** Stage Accu 1 ***
    -- First accumulator
    if r.VldAccu(0) = '1' then
      for ch in 0 to channels_g - 1 loop
        v.Accu(1)(ch) := psi_fix_add(r.Accu(1)(ch), AccuFmt_c,
                                     r.Input_0(ch), in_fmt_g,
                                     AccuFmt_c);
      end loop;
    end if;

    -- *** Accumuator Stages (2 to Order) ***
    for stage in 1 to order_g - 1 loop
      if r.VldAccu(stage) = '1' then
        for ch in 0 to channels_g - 1 loop
          v.Accu(stage + 1)(ch) := psi_fix_add(r.Accu(stage + 1)(ch), AccuFmt_c,
                                               r.Accu(stage)(ch), AccuFmt_c,
                                               AccuFmt_c);
        end loop;
      end if;
    end loop;

    -- *** Shift ***
    -- Shifter implemented as separate component, see below
    if ParTdmOutVld = '1' then
      v.SftVldCnt := r.SftVldCnt + 1;
    end if;
    if ShiftVld = '1' then
      v.SftVldCnt := v.SftVldCnt - 1;
    end if;

    -- *** Downsampling ***
    -- Decimate
    v.VldParTdm := '0';
    if r.VldAccu(order_g - 1) = '1' then
      if r.Rcnt = 0 then
        v.VldParTdm := '1';
        v.Rcnt      := to_integer(unsigned(cfg_ratio_i));
      else
        v.Rcnt := r.Rcnt - 1;
      end if;
    end if;

    -- *** Stage Diff 1 ***
    v.VldDiff(1) := VldDiff_0;
    -- First differentiator
    if VldDiff_0 = '1' then
      -- Differentiate
      v.DiffVal(1) := psi_fix_sub(DiffIn_0, DiffFmt_c,
                                  DiffDel(0), DiffFmt_c,
                                  DiffFmt_c);
    end if;

    -- *** Diff Stages ***
    -- Differentiators
    for stage in 1 to order_g - 1 loop
      if r.VldDiff(stage) = '1' then
        -- Differentiate
        v.DiffVal(stage + 1) := psi_fix_sub(r.DiffVal(stage), DiffFmt_c,
                                            DiffDel(stage), DiffFmt_c,
                                            DiffFmt_c);
      end if;
    end loop;

    if auto_gain_corr_g then
      -- *** Gain Coefficient Register ***
      v.GcCoef := cfg_gain_corr_i;

      -- *** Gain Correction Stage 0 ***
      v.GcVld(0) := r.VldDiff(order_g);
      v.GcIn_0   := psi_fix_resize(r.DiffVal(order_g), DiffFmt_c, GcInFmt_c, psi_fix_round, psi_fix_sat);

      -- *** Gain Correction Stage 1 ***
      v.GcMult_1 := psi_fix_mult(r.GcIn_0, GcInFmt_c,
                                 cfg_gain_corr_i, GcCoefFmt_c,
                                 GcMultFmt_c, psi_fix_trunc, psi_fix_wrap); -- Round/Truncation in next stage
      v.GcOut_2  := psi_fix_resize(r.GcMult_1, GcMultFmt_c, out_fmt_g, psi_fix_round, psi_fix_sat);
    end if;

    -- *** Status Output ***
    if (unsigned(r.VldAccu) /= 0) or (ParTdmOutVld = '1') or (unsigned(r.VldDiff) /= 0) or (unsigned(r.GcVld) /= 0) or (r.SftVldCnt /= 0) then -- OutVld omitted because of 1 cycle PL delay
      v.CalcOngoing := '1';
    else
      v.CalcOngoing := '0';
    end if;

    -- *** Output Assignment ***
    if auto_gain_corr_g then
      v.Outp   := r.GcOut_2;
      v.OutVld := r.GcVld(2);
    else
      v.Outp   := psi_fix_resize(r.DiffVal(order_g), DiffFmt_c, out_fmt_g, psi_fix_round, psi_fix_sat);
      v.OutVld := r.VldDiff(order_g);
    end if;
    busy_o <= r.CalcOngoing or r.VldAccu(0);

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Output Assignment
  --------------------------------------------------------------------------
  vld_o <= r.OutVld;
  dat_o <= r.Outp;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      assert channels_g >= 2 report "###ERROR###: psi_fix_cic_dec_fix_nch_tdm_tdm: channels_g must be >= 2" severity error;
      r <= r_next;
      if rst_i = rst_pol_g then
        r.VldAccu     <= (others => '0');
        r.Accu        <= (others => (others => (others => '0')));
        r.Rcnt        <= 0;
        r.VldDiff     <= (others => '0');
        r.GcVld       <= (others => '0');
        r.OutVld      <= '0';
        r.VldParTdm   <= '0';
        r.CalcOngoing <= '0';
        r.SftVldCnt   <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiations
  --------------------------------------------------------------------------

  -- *** Parallel to TDM conversion before diff-stages ***
  g_partdmin : for ch in 0 to channels_g - 1 generate
    ParTdmIn(psi_fix_size(AccuFmt_c) * (ch + 1) - 1 downto psi_fix_size(AccuFmt_c) * ch) <= r.Accu(order_g)(ch);
  end generate;

  i_partdm : entity work.psi_common_par_tdm
    generic map(
      ch_nb_g    => channels_g,
      ch_width_g => psi_fix_size(AccuFmt_c),
      rst_pol_g  => rst_pol_g
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      dat_i => ParTdmIn,
      vld_i => r.VldParTdm,
      dat_o => ParTdmOut,
      vld_o => ParTdmOutVld
    );

  -- *** Dynamic Shifter ***
  ShiftSel    <= cfg_shift_i(ShiftSel'range);
  ShiftDataIn <= psi_fix_resize(ParTdmOut, AccuFmt_c, SftFmt_c);
  i_sft : entity work.psi_common_dyn_sft
    generic map(
      direction_g         => "RIGHT",
      sel_bit_per_stage_g => 4,
      max_shift_g         => MaxShift_c,
      width_g             => psi_fix_size(SftFmt_c),
      sign_extend_g       => true,
      rst_pol_g           => rst_pol_g
    )
    port map(
      clk_i   => clk_i,
      rst_i   => rst_i,
      vld_i   => ParTdmOutVld,
      shift_i => ShiftSel,
      dat_i   => ShiftDataIn,
      vld_o   => ShiftVld,
      dat_o   => ShiftDataOut
    );
  VldDiff_0   <= ShiftVld;
  DiffIn_0    <= psi_fix_resize(ShiftDataOut, SftFmt_c, DiffFmt_c, psi_fix_trunc, psi_fix_wrap);

  -- *** Diff-delays ***
  g_diffdel : for stage in 0 to order_g - 1 generate
    signal DiffDelIn : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
    signal DiffVldIn : std_logic;
  begin
    DiffDelIn <= DiffIn_0 when stage = 0 else r.DiffVal(max(stage, 1));
    DiffVldIn <= VldDiff_0 when stage = 0 else r.VldDiff(max(stage, 1));

    i_del : entity work.psi_common_delay
      generic map(
        width_g     => psi_fix_size(DiffFmt_c),
        delay_g     => channels_g * diff_delay_g,
        rst_state_g => true
      )
      port map(
        clk_i => clk_i,
        rst_i => rst_i,
        -- Data
        dat_i => DiffDelIn,
        vld_i => DiffVldIn,
        dat_o => DiffDel(stage)
      );
  end generate;

end architecture;
