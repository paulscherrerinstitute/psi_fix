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

entity psi_fix_cic_dec_fix_1ch is
  generic(
    Order_g        : integer              := 4;
    Ratio_g        : integer              := 10;
    DiffDelay_g    : natural range 1 to 2 := 1;
    InFmt_g        : PsiFixFmt_t          := (1, 0, 15);
    OutFmt_g       : PsiFixFmt_t          := (1, 0, 15);
    rst_pol_g      : std_logic            := '1';
    AutoGainCorr_g : boolean              := True -- Uses up to 25 bits of the datapath and 17 bit correction parameter
  );
  port(
    -- Control Signals
    clk_i  : in  std_logic;
    rst_i  : in  std_logic;
    -- Data Ports
    dat_i  : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    vld_i  : in  std_logic;
    dat_o  : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    vld_o  : out std_logic;
    -- Status Output
    busy_o : out std_logic
  );
end entity;

architecture rtl of psi_fix_cic_dec_fix_1ch is
  -- Constants
  constant CicGain_c    : real                                                   := (real(Ratio_g) * real(DiffDelay_g))**real(Order_g);
  constant CicAddBits_c : integer                                                := log2ceil(CicGain_c - 0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
  constant Shift_c      : integer                                                := CicAddBits_c;
  constant AccuFmt_c    : PsiFixFmt_t                                            := (InFmt_g.S, InFmt_g.I + CicAddBits_c, InFmt_g.F);
  constant DiffFmt_c    : PsiFixFmt_t                                            := (OutFmt_g.S, InFmt_g.I, OutFmt_g.F + Order_g + 1);
  constant GcInFmt_c    : PsiFixFmt_t                                            := (1, OutFmt_g.I, work.psi_common_math_pkg.min(24 - OutFmt_g.I, DiffFmt_c.F));
  constant GcCoefFmt_c  : PsiFixFmt_t                                            := (0, 1, 16);
  constant GcMultFmt_c  : PsiFixFmt_t                                            := (1, GcInFmt_c.I + GcCoefFmt_c.I, GcInFmt_c.F + GcCoefFmt_c.F);
  constant Gc_c         : std_logic_vector(PsiFixSize(GcCoefFmt_c) - 1 downto 0) := PsiFixFromReal(2.0**real(CicAddBits_c) / real(CicGain_c), GcCoefFmt_c);

  -- Types
  type Accus_t is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c) - 1 downto 0);
  type Diff_t is array (natural range <>) of std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    -- Accu Section
    Input_0     : std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    VldAccu     : std_logic_vector(0 to Order_g);
    Accu        : Accus_t(1 to Order_g);
    Rcnt        : integer range 0 to Ratio_g - 1;
    -- Diff Section
    DiffIn_0    : std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
    VldDiff     : std_logic_vector(0 to Order_g);
    DiffVal     : Diff_t(1 to Order_g);
    DiffLast    : Diff_t(1 to Order_g);
    DiffLast2   : Diff_t(1 to Order_g);
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

begin
  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i)
    variable v         : two_process_r;
    variable DiffDel_v : std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
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
      v.Accu(1) := PsiFixAdd(r.Accu(1), AccuFmt_c,
                             r.Input_0, InFmt_g,
                             AccuFmt_c);
    end if;

    -- *** Accumuator Stages (2 to Order) ***
    for stage in 1 to Order_g - 1 loop
      if r.VldAccu(stage) = '1' then
        v.Accu(stage + 1) := PsiFixAdd(r.Accu(stage + 1), AccuFmt_c,
                                       r.Accu(stage), AccuFmt_c,
                                       AccuFmt_c);
      end if;
    end loop;

    -- *** Stage Diff 0 ***
    -- Decimate
    v.VldDiff(0) := '0';
    if r.VldAccu(Order_g) = '1' then
      if r.Rcnt = 0 then
        v.VldDiff(0) := '1';
        v.Rcnt       := Ratio_g - 1;
        v.DiffIn_0   := PsiFixShiftRight(r.Accu(Order_g), AccuFmt_c, Shift_c, Shift_c, DiffFmt_c, PsiFixTrunc, PsiFixWrap);
      else
        v.Rcnt := r.Rcnt - 1;
      end if;
    end if;

    -- *** Stage Diff 1 ***
    -- First differentiator
    if r.VldDiff(0) = '1' then
      if DiffDelay_g = 1 then
        DiffDel_v := r.DiffLast(1);
      else
        DiffDel_v      := r.DiffLast2(1);
        v.DiffLast2(1) := r.DiffLast(1);
      end if;
      -- Differentiate
      v.DiffVal(1)  := PsiFixSub(r.DiffIn_0, DiffFmt_c,
                                 DiffDel_v, DiffFmt_c,
                                 DiffFmt_c);
      v.DiffLast(1) := r.DiffIn_0;
    end if;

    -- *** Diff Stages ***
    -- Differentiators
    for stage in 1 to Order_g - 1 loop
      if r.VldDiff(stage) = '1' then
        if DiffDelay_g = 1 then
          DiffDel_v := r.DiffLast(stage + 1);
        else
          DiffDel_v              := r.DiffLast2(stage + 1);
          v.DiffLast2(stage + 1) := r.DiffLast(stage + 1);
        end if;
        -- Differentiate			
        v.DiffVal(stage + 1)  := PsiFixSub(r.DiffVal(stage), DiffFmt_c,
                                           DiffDel_v, DiffFmt_c,
                                           DiffFmt_c);
        v.DiffLast(stage + 1) := r.DiffVal(stage);
      end if;
    end loop;

    if AutoGainCorr_g then
      -- *** Gain Correction Stage 0 ***
      v.GcVld(0) := r.VldDiff(Order_g);
      v.GcIn_0   := PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, GcInFmt_c, PsiFixRound, PsiFixSat);

      -- *** Gain Correction Stage 1 ***
      v.GcMult_1 := PsiFixMult(r.GcIn_0, GcInFmt_c,
                               Gc_c, GcCoefFmt_c,
                               GcMultFmt_c, PsiFixTrunc, PsiFixWrap); -- Round/Truncation in next stage
      v.GcOut_2  := PsiFixResize(r.GcMult_1, GcMultFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
    end if;

    -- *** Status Output ***
    if (unsigned(r.VldAccu) /= 0) or (unsigned(r.VldDiff) /= 0) or (unsigned(r.GcVld) /= 0) then -- OutVld omitted because of 1 cycle PL delay
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
      end if;
    end if;
  end process;

end architecture;
