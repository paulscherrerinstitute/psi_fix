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
-- @formatter : off
entity psi_fix_cic_int_fix_1ch is
  generic(
    order_g        : integer              := 4;           -- CIC filter order
    ratio_g        : integer              := 10;          -- ratio interpolation
    diff_delay_g    : natural range 1 to 2 := 1;           -- differential delay
    in_fmt_g        : psi_fix_fmt_t        := (1, 0, 15);  -- input format
    out_fmt_g       : psi_fix_fmt_t        := (1, 0, 15);  -- output fromat
    rst_pol_g      : std_logic            := '1';         -- reset polarity active high
    auto_gain_corr_g : boolean              := True         -- Uses up to 25 bits of the datapath and 17 bit correction parameter
  );
  port(
    -- Control Signals      
    clk_i : in  std_logic;                                          -- clk system
    rst_i : in  std_logic;                                          -- rst system
    -- Data Ports
    dat_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data input
    vld_i : in  std_logic;                                          -- valid input Frequency sampling
    rdy_o : out std_logic;                                          -- ready signal output
    dat_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);-- data output
    vld_o : out std_logic;                                          -- valid signal output new Fs*Ratio
    rdy_i : in  std_logic                                           -- ready signal input
  );
end entity;
-- @formatter : on
architecture rtl of psi_fix_cic_int_fix_1ch is
  -- Constants
  constant CicGain_c     : real                                                   := ((real(ratio_g) * real(diff_delay_g))**real(order_g)) / real(ratio_g);
  constant CicAddBits_c  : integer                                                := log2ceil(CicGain_c - 0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
  constant Shift_c       : integer                                                := CicAddBits_c;
  constant DiffFmt_c     : psi_fix_fmt_t                                            := (in_fmt_g.S, in_fmt_g.I + order_g + 1, in_fmt_g.F);
  constant AccuFmt_c     : psi_fix_fmt_t                                            := (in_fmt_g.S, in_fmt_g.I + CicAddBits_c, in_fmt_g.F);
  constant ShiftInFmt_c  : psi_fix_fmt_t                                            := (in_fmt_g.S, in_fmt_g.I, in_fmt_g.F + CicAddBits_c);
  constant GcInFmt_c     : psi_fix_fmt_t                                            := (1, out_fmt_g.I, work.psi_common_math_pkg.min(24 - out_fmt_g.I, ShiftInFmt_c.F));
  constant ShiftOutFmt_c : psi_fix_fmt_t                                            := (in_fmt_g.S, in_fmt_g.I, choose(auto_gain_corr_g, GcInFmt_c.F, out_fmt_g.F) + 1);
  constant GcCoefFmt_c   : psi_fix_fmt_t                                            := (0, 1, 16);
  constant GcMultFmt_c   : psi_fix_fmt_t                                            := (1, GcInFmt_c.I + GcCoefFmt_c.I, GcInFmt_c.F + GcCoefFmt_c.F);
  constant Gc_c          : std_logic_vector(psi_fix_size(GcCoefFmt_c) - 1 downto 0) := psi_fix_from_real(2.0**real(CicAddBits_c) / real(CicGain_c), GcCoefFmt_c);

  -- Types
  type Accus_t is array (natural range <>) of std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  type Diff_t is array (natural range <>) of std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    -- Diff Section
    Input_0   : std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
    Rdy_0     : std_logic;
    VldDiff   : std_logic_vector(0 to order_g);
    DiffVal   : Diff_t(1 to order_g);
    DiffLast  : Diff_t(1 to order_g);
    DiffLast2 : Diff_t(1 to order_g);
    -- Interplation
    Rcnt      : integer range 0 to ratio_g;
    VldAccu   : std_logic_vector(0 to order_g);
    AccuIn_0  : std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
    -- Accu section
    Accu      : Accus_t(1 to order_g);
    -- GC Stages
    GcVld     : std_logic_vector(0 to 4);
    GcIn_0    : std_logic_vector(psi_fix_size(GcInFmt_c) - 1 downto 0);
    GcIn_1    : std_logic_vector(psi_fix_size(GcInFmt_c) - 1 downto 0);
    GcIn_2    : std_logic_vector(psi_fix_size(GcInFmt_c) - 1 downto 0);
    GcMult_3  : std_logic_vector(psi_fix_size(GcMultFmt_c) - 1 downto 0);
    GcOut_4   : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    -- Output
    Outp      : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutVld    : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i, rdy_i)
    variable v         : two_process_r;
    variable DiffDel_v : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
    variable Sft_v     : std_logic_vector(psi_fix_size(ShiftOutFmt_c) - 1 downto 0);
    variable InRdy_v   : std_logic;
    variable OutRdy_v  : std_logic;
  begin
    -- hold variables stable
    v := r;

    -- Variable default values
    DiffDel_v := (others => '0');
    Sft_v     := (others => '0');

    -- *** Handshaking pipeline control signals ***
    -- Only stop output pipeline if a result is available at the output (AXI-S Spec says valid is not allowed to wait on ready!)
    if r.OutVld = '0' or rdy_i = '1' then
      OutRdy_v := '1';
    else
      OutRdy_v := '0';
    end if;

    -- Input Rdy
    if r.Rcnt = 0 or (r.Rcnt = 1 and OutRdy_v = '1') then
      InRdy_v := '1';
    else
      InRdy_v := '0';
    end if;

    -- *** Pipe Handling ***
    if InRdy_v = '1' then
      v.VldDiff(v.VldDiff'low + 1 to v.VldDiff'high) := r.VldDiff(r.VldDiff'low to r.VldDiff'high - 1);
    end if;
    if OutRdy_v = '1' then
      v.VldAccu(v.VldAccu'low + 1 to v.VldAccu'high) := r.VldAccu(r.VldAccu'low to r.VldAccu'high - 1);
      v.GcVld(v.GcVld'low + 1 to v.GcVld'high)       := r.GcVld(r.GcVld'low to r.GcVld'high - 1);
    end if;

    -- *** Stage Diff 0 (Input registers) ***
    -- Input Registers and combinatorial rdy chain breaking (making RDY registered)
    if r.Rdy_0 = '1' and vld_i = '1' then
      v.VldDiff(0) := '1';
      v.Input_0    := dat_i;
      v.Rdy_0      := '0';
    elsif InRdy_v = '1' or r.VldDiff(1) = '0' then
      v.VldDiff(0) := '0';
      v.Rdy_0      := '1';
    end if;

    -- *** Stage Diff 1 ***
    -- First differentiator
    if r.VldDiff(0) = '1' and (InRdy_v = '1' or r.VldDiff(1) = '0') then
      v.VldDiff(1)  := '1';
      v.VldDiff(0)  := '0';
      if diff_delay_g = 1 then
        DiffDel_v := r.DiffLast(1);
      else
        DiffDel_v      := r.DiffLast2(1);
        v.DiffLast2(1) := r.DiffLast(1);
      end if;
      -- Differentiate
      v.DiffVal(1)  := psi_fix_sub(r.Input_0, in_fmt_g,
                                 DiffDel_v, DiffFmt_c,
                                 DiffFmt_c);
      v.DiffLast(1) := psi_fix_resize(r.Input_0, in_fmt_g, DiffFmt_c);
    end if;

    -- *** Diff Stages ***
    -- Differentiators
    for stage in 1 to order_g - 1 loop
      if r.VldDiff(stage) = '1' and (InRdy_v = '1' or r.VldDiff(stage + 1) = '0') then
        v.VldDiff(stage + 1)  := '1';
        v.VldDiff(stage)      := r.VldDiff(stage - 1);
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

    -- *** Stage Accu 0 (interpolation) ***
    if (r.Rcnt = 0 and r.VldDiff(order_g) = '1') or (r.Rcnt = 1 and OutRdy_v = '1' and r.VldDiff(order_g) = '1') then
      v.Rcnt       := ratio_g;
      v.AccuIn_0   := psi_fix_resize(r.DiffVal(order_g), DiffFmt_c, AccuFmt_c);
      v.VldAccu(0) := '1';
    elsif r.Rcnt = 1 and OutRdy_v = '1' then
      v.VldAccu(0) := '0';
      v.Rcnt       := r.Rcnt - 1;
    elsif OutRdy_v = '1' and r.Rcnt /= 0 then
      v.AccuIn_0 := (others => '0');
      v.Rcnt     := r.Rcnt - 1;
    end if;

    -- *** Stage Accu 1 ***
    -- First accumulator
    if r.VldAccu(0) = '1' and OutRdy_v = '1' then
      v.Accu(1) := psi_fix_add(r.Accu(1), AccuFmt_c,
                             r.AccuIn_0, AccuFmt_c,
                             AccuFmt_c);
    end if;

    -- *** Accumuator Stages (2 to Order) ***
    for stage in 1 to order_g - 1 loop
      if r.VldAccu(stage) = '1' and OutRdy_v = '1' then
        v.Accu(stage + 1) := psi_fix_add(r.Accu(stage + 1), AccuFmt_c,
                                       r.Accu(stage), AccuFmt_c,
                                       AccuFmt_c);
      end if;
    end loop;
    -- Shifter (pure wiring)
    Sft_v := psi_fix_shift_right(r.Accu(order_g), AccuFmt_c, Shift_c, Shift_c, ShiftOutFmt_c);

    -- *** Gain Correction ***		
    if auto_gain_corr_g then
      -- *** Gain Correction Stage 0 ***
      if OutRdy_v = '1' then
        -- *** GC Stage 0 ***
        v.GcVld(0) := r.VldAccu(order_g);
        v.GcIn_0   := psi_fix_resize(Sft_v, ShiftOutFmt_c, GcInFmt_c, psi_fix_round, psi_fix_sat);

        -- *** GC Stage 1 ***
        v.GcIn_1 := r.GcIn_0;

        -- *** GC Stage 2 ***
        v.GcIn_2 := r.GcIn_1;

        -- *** Gain Correction Stage 3 ***
        v.GcMult_3 := psi_fix_mult(r.GcIn_2, GcInFmt_c,
                                 Gc_c, GcCoefFmt_c,
                                 GcMultFmt_c, psi_fix_trunc, psi_fix_wrap); -- Round/Truncation in next stage

        -- *** Gain Correction Stage 4 ***
        v.GcOut_4 := psi_fix_resize(r.GcMult_3, GcMultFmt_c, out_fmt_g, psi_fix_round, psi_fix_sat);
      end if;
    end if;

    -- *** Output Assignment ***
    if OutRdy_v = '1' then
      if auto_gain_corr_g then
        v.Outp   := r.GcOut_4;
        v.OutVld := r.GcVld(4);
      else
        v.Outp   := psi_fix_resize(Sft_v, ShiftOutFmt_c, out_fmt_g, psi_fix_round, psi_fix_sat);
        v.OutVld := r.VldAccu(order_g);
      end if;
    end if;

    -- *** Output Signals ***
    vld_o <= r.OutVld;
    dat_o <= r.Outp;
    rdy_o <= r.Rdy_0;

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
        r.VldDiff   <= (others => '0');
        r.DiffLast  <= (others => (others => '0'));
        r.DiffLast2 <= (others => (others => '0'));
        r.VldAccu   <= (others => '0');
        r.Accu      <= (others => (others => '0'));
        r.GcVld     <= (others => '0');
        r.OutVld    <= '0';
        r.Rdy_0     <= '1';
      end if;
    end if;
  end process;

end architecture;
