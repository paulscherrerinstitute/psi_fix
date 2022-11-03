---------------------------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
--  https://github.com/paulscherrerinstitute/psi_fix/blob/refactor/hdl/psi_fix_cic_dec_cfg_1ch.vhd
--  Configuration (only change when in reset!)
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Parameter Calculations
------------------------------------------------------------------------------
-- CIC_GAIN = (Ratio*DifDelay)^Order
-- CIC_GROWTH = ceil(log2(CIC_GAIN))
-- SHIFT = CIC_GROWTH         --> Apply this to CfgShift
-- GAINCORR = 2^CIC_GROWTH/CIC_GAIN   --> Apply this to CfgGainCorr
------------------------------------------------------------------------------

entity psi_fix_cic_dec_cfg_1ch is
  generic(
    order_g        : integer              := 4;                                 -- filter order
    max_ratio_g     : natural              := 12;                                -- maximum ratio for decimation
    diff_delay_g    : natural range 1 to 2 := 1;                                 -- differential delay
    in_fmt_g        : psi_fix_fmt_t        := (1, 0, 15);                        -- input  format FP
    out_fmt_g       : psi_fix_fmt_t        := (1, 0, 15);                        -- output format FP
    rst_pol_g      : std_logic :='1';                                           -- reset polarity active = '1'
    auto_gain_corr_g : boolean              := True                               -- Use CfgGainCorr for fine-grained gain correction (beyond pure shifting)
  );
  port(
    clk_i           : in  std_logic;                                            -- clk system
    rst_i           : in  std_logic;                                            -- rst system
    cfg_ratio_i     : in  std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0);  -- Ratio-1 (0 --> no decimation, 3 --> decimation by 4)
    cfg_shift_i     : in  std_logic_vector(7 downto 0);                         -- Shifting by more than 255 bits is not supported, this would lead to timing issues anyways
    cfg_gain_corr_i : in  std_logic_vector(16 downto 0);                        -- Gain correction factor in format [0,1,16]
    dat_i           : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);   -- data input
    vld_i           : in  std_logic;                                            -- valid input
    dat_o           : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);  -- data output
    vld_o           : out std_logic;                                            -- valid otuput
    busy_o          : out std_logic                                             -- busy signal output active high
  );
end entity;


architecture rtl of psi_fix_cic_dec_cfg_1ch is
  -- Constants
  constant MaxCicGain_c    : real        := (real(max_ratio_g) * real(diff_delay_g))**real(order_g);
  constant MaxCicAddBits_c : integer     := log2ceil(MaxCicGain_c - 0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
  constant MaxShift_c      : integer     := MaxCicAddBits_c;
  constant AccuFmt_c       : psi_fix_fmt_t := (in_fmt_g.S, in_fmt_g.I + MaxCicAddBits_c, in_fmt_g.F);
  constant DiffFmt_c       : psi_fix_fmt_t := (out_fmt_g.S, in_fmt_g.I, out_fmt_g.F + order_g + 1);
  constant GcInFmt_c       : psi_fix_fmt_t := (1, out_fmt_g.I, work.psi_common_math_pkg.min(24 - out_fmt_g.I, DiffFmt_c.F));
  constant GcCoefFmt_c     : psi_fix_fmt_t := (0, 1, 16);
  constant GcMultFmt_c     : psi_fix_fmt_t := (1, GcInFmt_c.I + GcCoefFmt_c.I, GcInFmt_c.F + GcCoefFmt_c.F);
  constant SftFmt_c        : psi_fix_fmt_t := (AccuFmt_c.S, AccuFmt_c.I, max(AccuFmt_c.F, DiffFmt_c.F));

  -- Types
  type Accus_t is array (natural range <>) of std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  type Diff_t is array (natural range <>) of std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    -- GainCorr Registers
    GcCoef      : std_logic_vector(psi_fix_size(GcCoefFmt_c) - 1 downto 0);
    -- Accu Section
    Input_0     : std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
    VldAccu     : std_logic_vector(0 to order_g);
    Accu        : Accus_t(1 to order_g);
    Rcnt        : integer range 0 to max_ratio_g - 1;
    SftVldCnt   : unsigned(4 downto 0); -- Maximum shift is 255
    -- Diff Section
    DiffIn_0    : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
    VldDiff     : std_logic_vector(0 to order_g);
    DiffVal     : Diff_t(1 to order_g);
    DiffLast    : Diff_t(1 to order_g);
    DiffLast2   : Diff_t(1 to order_g);
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

  signal ShiftSel     : std_logic_vector(log2ceil(MaxShift_c + 1) - 1 downto 0);
  signal ShiftVld     : std_logic;
  signal ShiftDataIn  : std_logic_vector(psi_fix_size(SftFmt_c) - 1 downto 0);
  signal ShiftDataOut : std_logic_vector(psi_fix_size(SftFmt_c) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i, ShiftDataOut, ShiftVld, cfg_gain_corr_i, cfg_ratio_i, cfg_shift_i)
    variable v         : two_process_r;
    variable DiffDel_v : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
  begin
    -- hold variables stable
    v         := r;
    DiffDel_v := (others => '0');

    -- *** Pipe Handling ***
    v.VldAccu(v.VldAccu'low + 1 to v.VldAccu'high) := r.VldAccu(r.VldAccu'low to r.VldAccu'high - 1);
    v.VldDiff(v.VldDiff'low + 1 to v.VldDiff'high) := r.VldDiff(r.VldDiff'low to r.VldDiff'high - 1);
    v.GcVld(v.GcVld'low + 1 to v.GcVld'high)       := r.GcVld(r.GcVld'low to r.GcVld'high - 1);

    -- *** Stage Accu 0 ***
    -- Input Registers
    v.VldAccu(0) := vld_i;
    v.Input_0    := dat_i;

    -- *** Stage Accu 1 ***
    -- First accumulator
    if r.VldAccu(0) = '1' then
      v.Accu(1) := psi_fix_add(r.Accu(1), AccuFmt_c,
                             r.Input_0, in_fmt_g,
                             AccuFmt_c);
    end if;

    -- *** Accumuator Stages (2 to Order) ***
    for stage in 1 to order_g - 1 loop
      if r.VldAccu(stage) = '1' then
        v.Accu(stage + 1) := psi_fix_add(r.Accu(stage + 1), AccuFmt_c,
                                       r.Accu(stage), AccuFmt_c,
                                       AccuFmt_c);
      end if;
    end loop;

    -- *** Shift ***
    -- Shifter implemented as separate component, see below
    if r.VldAccu(order_g) = '1' then
      v.SftVldCnt := r.SftVldCnt + 1;
    end if;
    if ShiftVld = '1' then
      v.SftVldCnt := v.SftVldCnt - 1;
    end if;

    -- *** Stage Diff 0 ***
    -- Decimate
    v.VldDiff(0) := '0';
    if ShiftVld = '1' then
      if r.Rcnt = 0 then
        v.VldDiff(0) := '1';
        v.Rcnt       := to_integer(unsigned(cfg_ratio_i));
        v.DiffIn_0   := psi_fix_resize(ShiftDataOut, SftFmt_c, DiffFmt_c, psi_fix_trunc, psi_fix_wrap);
      else
        v.Rcnt := r.Rcnt - 1;
      end if;
    end if;

    -- *** Stage Diff 1 ***
    -- First differentiator
    if r.VldDiff(0) = '1' then
      if diff_delay_g = 1 then
        DiffDel_v := r.DiffLast(1);
      else
        DiffDel_v      := r.DiffLast2(1);
        v.DiffLast2(1) := r.DiffLast(1);
      end if;
      -- Differentiate
      v.DiffVal(1)  := psi_fix_sub(r.DiffIn_0, DiffFmt_c,
                                 DiffDel_v, DiffFmt_c,
                                 DiffFmt_c);
      v.DiffLast(1) := r.DiffIn_0;
    end if;

    -- *** Diff Stages ***
    -- Differentiators
    for stage in 1 to order_g - 1 loop
      if r.VldDiff(stage) = '1' then
        if diff_delay_g = 1 then
          DiffDel_v := r.DiffLast(stage + 1);
        else
          DiffDel_v              := r.DiffLast2(stage + 1);
          v.DiffLast2(stage + 1) := r.DiffLast(stage + 1);
        end if;
        -- Differentiate
        v.DiffVal(stage + 1)  := psi_fix_sub(r.DiffVal(stage), DiffFmt_c,
                                           DiffDel_v, DiffFmt_c,
                                           DiffFmt_c);
        v.DiffLast(stage + 1) := r.DiffVal(stage);
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
    if (unsigned(r.VldAccu) /= 0) or (unsigned(r.VldDiff) /= 0) or (unsigned(r.GcVld) /= 0) or (r.SftVldCnt /= 0) then -- OutVld omitted because of 1 cycle PL delay
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
  vld_o  <= r.OutVld;
  dat_o <= r.Outp;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.VldAccu     <= (others => '0');
        r.Accu        <= (others => (others => '0'));
        r.Rcnt        <= 0;
        r.VldDiff     <= (others => '0');
        r.DiffLast    <= (others => (others => '0'));
        r.DiffLast2   <= (others => (others => '0'));
        r.GcVld       <= (others => '0');
        r.OutVld      <= '0';
        r.CalcOngoing <= '0';
        r.SftVldCnt   <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiations
  --------------------------------------------------------------------------
  -- Dynamic Shifter
  ShiftSel    <= cfg_shift_i(ShiftSel'range);
  ShiftDataIn <= psi_fix_resize(r.Accu(order_g), AccuFmt_c, SftFmt_c);
  i_sft : entity work.psi_common_dyn_sft
    generic map(
      Direction_g          => "RIGHT",
      SelectBitsPerStage_g => 4,
      MaxShift_g           => MaxShift_c,
      Width_g              => psi_fix_size(SftFmt_c),
      SignExtend_g         => true
    )
    port map(
      Clk     => clk_i,
      Rst     => rst_i,
      InVld   => r.VldAccu(order_g),
      InShift => ShiftSel,
      InData  => ShiftDataIn,
      OutVld  => ShiftVld,
      OutData => ShiftDataOut
    );

end architecture;
