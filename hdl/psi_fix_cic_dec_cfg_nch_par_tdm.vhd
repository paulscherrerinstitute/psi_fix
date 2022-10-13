------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
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
-- SHIFT = CIC_GROWTH					--> Apply this to CfgShift
-- GAINCORR = 2^CIC_GROWTH/CIC_GAIN		--> Apply this to CfgGainCorr

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
entity psi_fix_cic_dec_cfg_nch_par_tdm is
  generic(
    Channels_g     : integer              := 3; -- Min. 2
    Order_g        : integer              := 4;
    MaxRatio_g     : natural              := 12;
    DiffDelay_g    : natural range 1 to 2 := 1;
    InFmt_g        : PsiFixFmt_t          := (1, 0, 15);
    OutFmt_g       : PsiFixFmt_t          := (1, 0, 15);
    rst_pol_g      : std_logic            := '1';
    AutoGainCorr_g : boolean              := True -- Use CfgGainCorr for fine-grained gain correction (beyond pure shifting)
  );
  port(
    -- Control Signals
    clk_i           : in  std_logic;
    rst_i           : in  std_logic;
    -- Configuration (only change when in reset!)
    cfg_ratio_i     : in  std_logic_vector(log2ceil(MaxRatio_g) - 1 downto 0); -- Ratio-1 (0 --> no decimation, 3 --> decimation by 4)
    cfg_shift_i     : in  std_logic_vector(7 downto 0); -- Shifting by more than 255 bits is not supported, this would lead to timing issues anyways
    cfg_gain_corr_i : in  std_logic_vector(16 downto 0); -- Gain correction factor in format [0,1,16]
    -- Data Ports
    dat_i           : in  std_logic_vector(PsiFixSize(InFmt_g) * Channels_g - 1 downto 0);
    vld_i           : in  std_logic;
    dat_o           : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    vld_o           : out std_logic;
    -- Status Output
    busy_o          : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_cic_dec_cfg_nch_par_tdm is
  -- Constants
  constant MaxCicGain_c    : real        := (real(MaxRatio_g) * real(DiffDelay_g))**real(Order_g);
  constant MaxCicAddBits_c : integer     := log2ceil(MaxCicGain_c - 0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
  constant MaxShift_c      : integer     := MaxCicAddBits_c;
  constant AccuFmt_c       : PsiFixFmt_t := (InFmt_g.S, InFmt_g.I + MaxCicAddBits_c, InFmt_g.F);
  constant DiffFmt_c       : PsiFixFmt_t := (OutFmt_g.S, InFmt_g.I, OutFmt_g.F + Order_g + 1);
  constant GcInFmt_c       : PsiFixFmt_t := (1, OutFmt_g.I, work.psi_common_math_pkg.min(24 - OutFmt_g.I, DiffFmt_c.F));
  constant GcCoefFmt_c     : PsiFixFmt_t := (0, 1, 16);
  constant GcMultFmt_c     : PsiFixFmt_t := (1, GcInFmt_c.I + GcCoefFmt_c.I, GcInFmt_c.F + GcCoefFmt_c.F);
  constant SftFmt_c        : PsiFixFmt_t := (AccuFmt_c.S, AccuFmt_c.I, max(AccuFmt_c.F, DiffFmt_c.F));

  -- Types
  type AccuStage_t is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c) - 1 downto 0);
  type Accus_t is array (natural range <>) of AccuStage_t(0 to Channels_g - 1);
  type Diff_t is array (natural range <>) of std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
  type InputStage_t is array (natural range <>) of std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    -- GainCorr Registers
    GcCoef      : std_logic_vector(PsiFixSize(GcCoefFmt_c) - 1 downto 0);
    -- Accu Section
    Input_0     : InputStage_t(Channels_g - 1 downto 0);
    VldAccu     : std_logic_vector(0 to Order_g);
    Accu        : Accus_t(1 to Order_g);
    Rcnt        : integer range 0 to MaxRatio_g - 1;
    SftVldCnt   : unsigned(4 downto 0); -- Maximum shift is 255
    -- Diff Section
    VldParTdm   : std_logic;
    VldDiff     : std_logic_vector(1 to Order_g);
    DiffVal     : Diff_t(1 to Order_g);
    -- GC Stages
    GcVld       : std_logic_vector(0 to 2);
    GcIn_0      : std_logic_vector(PsiFixSize(GcInFmt_c) - 1 downto 0);
    GcMult_1    : std_logic_vector(PsiFixSize(GcMultFmt_c) - 1 downto 0);
    GcOut_2     : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    -- Output
    Outp        : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    OutVld      : std_logic;
    -- Status
    CalcOngoing : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- Component Connection Signals
  signal ParTdmIn     : std_logic_vector(PsiFixSize(AccuFmt_c) * Channels_g - 1 downto 0);
  signal ParTdmOut    : std_logic_vector(PsiFixSize(AccuFmt_c) - 1 downto 0);
  signal ParTdmOutVld : std_logic;
  signal DiffIn_0     : std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
  signal VldDiff_0    : std_logic;
  signal DiffDel      : Diff_t(0 to Order_g - 1);

  signal ShiftSel     : std_logic_vector(log2ceil(MaxShift_c + 1) - 1 downto 0);
  signal ShiftVld     : std_logic;
  signal ShiftDataIn  : std_logic_vector(PSiFixSize(SftFmt_c) - 1 downto 0);
  signal ShiftDataOut : std_logic_vector(PSiFixSize(SftFmt_c) - 1 downto 0);

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
    for ch in 0 to Channels_g - 1 loop
      v.Input_0(ch) := dat_i(PsiFixSize(InFmt_g) * (ch + 1) - 1 downto PsiFixSize(InFmt_g) * ch);
    end loop;

    -- *** Stage Accu 1 ***
    -- First accumulator
    if r.VldAccu(0) = '1' then
      for ch in 0 to Channels_g - 1 loop
        v.Accu(1)(ch) := PsiFixAdd(r.Accu(1)(ch), AccuFmt_c,
                                   r.Input_0(ch), InFmt_g,
                                   AccuFmt_c);
      end loop;
    end if;

    -- *** Accumuator Stages (2 to Order) ***
    for stage in 1 to Order_g - 1 loop
      if r.VldAccu(stage) = '1' then
        for ch in 0 to Channels_g - 1 loop
          v.Accu(stage + 1)(ch) := PsiFixAdd(r.Accu(stage + 1)(ch), AccuFmt_c,
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
    if r.VldAccu(Order_g - 1) = '1' then
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
      v.DiffVal(1) := PsiFixSub(DiffIn_0, DiffFmt_c,
                                DiffDel(0), DiffFmt_c,
                                DiffFmt_c);
    end if;

    -- *** Diff Stages ***
    -- Differentiators
    for stage in 1 to Order_g - 1 loop
      if r.VldDiff(stage) = '1' then
        -- Differentiate			
        v.DiffVal(stage + 1) := PsiFixSub(r.DiffVal(stage), DiffFmt_c,
                                          DiffDel(stage), DiffFmt_c,
                                          DiffFmt_c);
      end if;
    end loop;

    if AutoGainCorr_g then
      -- *** Gain Coefficient Register ***
      v.GcCoef := cfg_gain_corr_i;

      -- *** Gain Correction Stage 0 ***
      v.GcVld(0) := r.VldDiff(Order_g);
      v.GcIn_0   := PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, GcInFmt_c, PsiFixRound, PsiFixSat);

      -- *** Gain Correction Stage 1 ***
      v.GcMult_1 := PsiFixMult(r.GcIn_0, GcInFmt_c,
                               cfg_gain_corr_i, GcCoefFmt_c,
                               GcMultFmt_c, PsiFixTrunc, PsiFixWrap); -- Round/Truncation in next stage
      v.GcOut_2  := PsiFixResize(r.GcMult_1, GcMultFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
    end if;

    -- *** Status Output ***
    if (unsigned(r.VldAccu) /= 0) or (ParTdmOutVld = '1') or (unsigned(r.VldDiff) /= 0) or (unsigned(r.GcVld) /= 0) or (r.SftVldCnt /= 0) then -- OutVld omitted because of 1 cycle PL delay
      v.CalcOngoing := '1';
    else
      v.CalcOngoing := '0';
    end if;

    -- *** Output Assignment ***
    if AutoGainCorr_g then
      v.Outp   := r.GcOut_2;
      v.OutVld := r.GcVld(2);
    else
      v.Outp   := PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
      v.OutVld := r.VldDiff(Order_g);
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
      assert Channels_g >= 2 report "###ERROR###: psi_fix_cic_dec_fix_nch_tdm_tdm: Channels_g must be >= 2" severity error;
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
  g_partdmin : for ch in 0 to Channels_g - 1 generate
    ParTdmIn(PsiFixSize(AccuFmt_c) * (ch + 1) - 1 downto PsiFixSize(AccuFmt_c) * ch) <= r.Accu(Order_g)(ch);
  end generate;

  i_partdm : entity work.psi_common_par_tdm
    generic map(
      ChannelCount_g => Channels_g,
      ChannelWidth_g => PsiFixSize(AccuFmt_c)
    )
    port map(
      Clk         => clk_i,
      Rst         => rst_i,
      Parallel    => ParTdmIn,
      ParallelVld => r.VldParTdm,
      Tdm         => ParTdmOut,
      TdmVld      => ParTdmOutVld
    );

  -- *** Dynamic Shifter ***
  ShiftSel    <= cfg_shift_i(ShiftSel'range);
  ShiftDataIn <= PsiFixResize(ParTdmOut, AccuFmt_c, SftFmt_c);
  i_sft : entity work.psi_common_dyn_sft
    generic map(
      Direction_g          => "RIGHT",
      SelectBitsPerStage_g => 4,
      MaxShift_g           => MaxShift_c,
      Width_g              => PsiFixSize(SftFmt_c),
      SignExtend_g         => true
    )
    port map(
      Clk     => clk_i,
      Rst     => rst_i,
      InVld   => ParTdmOutVld,
      InShift => ShiftSel,
      InData  => ShiftDataIn,
      OutVld  => ShiftVld,
      OutData => ShiftDataOut
    );
  VldDiff_0   <= ShiftVld;
  DiffIn_0    <= PsiFixResize(ShiftDataOut, SftFmt_c, DiffFmt_c, PsiFixTrunc, PsiFixWrap);

  -- *** Diff-delays ***
  g_diffdel : for stage in 0 to Order_g - 1 generate
    signal DiffDelIn : std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
    signal DiffVldIn : std_logic;
  begin
    DiffDelIn <= DiffIn_0 when stage = 0 else r.DiffVal(max(stage, 1));
    DiffVldIn <= VldDiff_0 when stage = 0 else r.VldDiff(max(stage, 1));

    i_del : entity work.psi_common_delay
      generic map(
        Width_g    => PsiFixSize(DiffFmt_c),
        Delay_g    => Channels_g * DiffDelay_g,
        RstState_g => true
      )
      port map(
        Clk     => clk_i,
        Rst     => rst_i,
        -- Data
        InData  => DiffDelIn,
        InVld   => DiffVldIn,
        OutData => DiffDel(stage)
      );
  end generate;

end architecture;
