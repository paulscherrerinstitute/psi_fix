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
use work.psi_common_logic_pkg.all;
-- @formatter:off
-- $$ tbpkg=psi_lib.psi_tb_textfile_pkg,psi_lib.psi_tb_txt_util $$
-- $$ processes=stimuli,response $$
entity psi_fix_complex_abs is
  generic(
    in_fmt_g       : psi_fix_fmt_t := (1, 0, 15);                            -- FP format in
    out_fmt_g      : psi_fix_fmt_t := (0, 1, 15);                            -- FP format out
    round_g        : psi_fix_rnd_t := psi_fix_trunc;                         -- trunc or round
    sat_g          : psi_fix_sat_t := psi_fix_wrap;                          -- Wrap or sat
    rst_pol_g      : std_logic   := '1';                                     -- reset polarity active high
    ram_behavior_g : string      := "RBW"                                    -- RBW = Read before write, WBR = write before read
  );
  port(
    clk_i     : in  std_logic;                                              -- $$ type=Clk; freq=127e6 $$
    rst_i     : in  std_logic;                                              -- $$ type=Rst; Clk=clk_i $$
    dat_inp_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);  -- data inphase I
    dat_qua_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);  -- data quadrature Q
    vld_i     : in  std_logic;                                              -- valid signal in
    dat_o     : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- results output DQRT(I^2+Q^2)
    vld_o     : out std_logic                                               -- valid signal out
  );
end entity;
-- @formatter:on
------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_complex_abs is

  -- Constants
  constant InFmtNorm_c          : psi_fix_fmt_t := (in_fmt_g.S, 0, in_fmt_g.I + in_fmt_g.F);
  constant OutFmtNorm_c         : psi_fix_fmt_t := (out_fmt_g.S, 0, out_fmt_g.I + out_fmt_g.F + 1); -- rounding bit is kept
  constant SqrFmt_c             : psi_fix_fmt_t := (0, InFmtNorm_c.I + 1, InFmtNorm_c.F * 2);
  constant AddFmt_c             : psi_fix_fmt_t := (0, SqrFmt_c.I + 1, SqrFmt_c.F);
  constant LimFmt_c             : psi_fix_fmt_t := (0, 0, AddFmt_c.F); -- 2*15=30 fractional bits
  constant SqrtInFmt_c          : psi_fix_fmt_t := (0, 0, 20);
  constant SqrtOutFmt_c         : psi_fix_fmt_t := (0, 0, 17);
  constant MaxSft_c             : natural     := (InFmtNorm_c.F / 2 * 2);
  constant SftStgBeforeApprox_c : natural     := log2ceil(MaxSft_c);
  constant SftStgAfterApprox_c  : natural     := SftStgBeforeApprox_c / 2;
  constant OutSftFmt_c          : psi_fix_fmt_t := (0, 0, OutFmtNorm_c.F);

  -- types
  type LimArray_t is array (natural range <>) of std_logic_vector(psi_fix_size(LimFmt_c) - 1 downto 0);
  type CntArray_t is array (natural range <>) of unsigned(SftStgBeforeApprox_c - 1 downto 0);
  type OutSftArray_t is array (natural range <>) of std_logic_vector(psi_fix_size(OutSftFmt_c) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    InVld  : std_logic_vector(0 to 4 + SftStgBeforeApprox_c - 1);
    I_0    : std_logic_vector(psi_fix_size(InFmtNorm_c) - 1 downto 0);
    Q_0    : std_logic_vector(psi_fix_size(InFmtNorm_c) - 1 downto 0);
    ISqr_1 : std_logic_vector(psi_fix_size(SqrFmt_c) - 1 downto 0);
    QSqr_1 : std_logic_vector(psi_fix_size(SqrFmt_c) - 1 downto 0);
    Sum_2  : std_logic_vector(psi_fix_size(AddFmt_c) - 1 downto 0);
    Lim_3  : std_logic_vector(psi_fix_size(LimFmt_c) - 1 downto 0);
    InSft  : LimArray_t(0 to SftStgBeforeApprox_c - 1);
    SftCnt : CntArray_t(0 to SftStgBeforeApprox_c - 1);
    OutVld : std_logic_vector(0 to SftStgAfterApprox_c + 1);
    OutSft : OutSftArray_t(0 to SftStgAfterApprox_c);
    OutCnt : CntArray_t(0 to SftStgAfterApprox_c);
    OutRes : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

  -- Component Instantiation
  signal SqrtIn_s    : std_logic_vector(psi_fix_size(SqrtInFmt_c) - 1 downto 0);
  signal SftCntOut_s : std_logic_vector(SftStgBeforeApprox_c - 1 downto 0);
  signal IsZeroIn_s  : std_logic;
  signal IsZeroOut_s : std_logic;
  signal SqrtVld_s   : std_logic;
  signal SqrtData_s  : std_logic_vector(psi_fix_size(SqrtOutFmt_c) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  proc_comb : process(r, vld_i, dat_inp_i, dat_qua_i, SftCntOut_s, SqrtVld_s, SqrtData_s, IsZeroOut_s)
    variable v              : two_process_r;
    variable SftBeforeIn_v  : std_logic_vector(psi_fix_size(LimFmt_c) - 1 downto 0);
    variable SftBefore_v    : integer;
    variable SftAfter_v     : unsigned(SftStgBeforeApprox_c downto 0);
    variable SftStepAfter_v : integer;
    variable StgIdx_v       : integer;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.InVld(v.InVld'low + 1 to v.InVld'high)    := r.InVld(r.InVld'low to r.InVld'high - 1);
    v.OutVld(v.OutVld'low + 1 to v.OutVld'high) := r.OutVld(r.OutVld'low to r.OutVld'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.InVld(0) := vld_i;
    v.I_0      := dat_inp_i;
    v.Q_0      := dat_qua_i;

    -- *** Stage 1 ***
    -- Normalization is implicit by reinterpreting the number format (number of bits is not changed)

    -- Squaring
    v.ISqr_1 := psi_fix_mult(r.I_0, InFmtNorm_c, r.I_0, InFmtNorm_c, SqrFmt_c);
    v.QSqr_1 := psi_fix_mult(r.Q_0, InFmtNorm_c, r.Q_0, InFmtNorm_c, SqrFmt_c);

    -- *** Stage 2 ***
    -- Sum
    v.Sum_2 := psi_fix_add(r.ISqr_1, SqrFmt_c, r.QSqr_1, SqrFmt_c, AddFmt_c);

    -- *** Stage 3 ***
    -- Limit to 1
    v.Lim_3 := psi_fix_resize(r.Sum_2, AddFmt_c, LimFmt_c, psi_fix_trunc, psi_fix_sat);

    -- *** Shift stages (0 ... x) ***
    for stg in 0 to SftStgBeforeApprox_c - 1 loop
      -- Select input
      if stg = 0 then
        SftBeforeIn_v := r.Lim_3;
        v.SftCnt(stg) := (others => '0');
      else
        SftBeforeIn_v := r.InSft(stg - 1);
        v.SftCnt(stg) := r.SftCnt(stg - 1);
      end if;

      -- Do Shift
      SftBefore_v := 2**(SftStgBeforeApprox_c - stg);
      if unsigned(SftBeforeIn_v(SftBeforeIn_v'left downto SftBeforeIn_v'left - SftBefore_v + 1)) = 0 then
        v.InSft(stg)                                  := SftBeforeIn_v(SftBeforeIn_v'left - SftBefore_v downto 0) & ZerosVector(SftBefore_v);
        v.SftCnt(stg)(SftStgBeforeApprox_c - stg - 1) := '1';
      else
        v.InSft(stg)                                  := SftBeforeIn_v;
        v.SftCnt(stg)(SftStgBeforeApprox_c - stg - 1) := '0';
      end if;
    end loop;

    -- *** Out Stage 0 ***
    v.OutVld(0) := SqrtVld_s;
    if IsZeroOut_s = '1' then
      v.OutSft(0) := (others => '0');
    else
      v.OutSft(0) := psi_fix_resize(SqrtData_s, SqrtOutFmt_c, OutSftFmt_c);
    end if;
    v.OutCnt(0) := unsigned(SftCntOut_s);

    -- *** Out Shift Stages ***
    for stg in 0 to SftStgAfterApprox_c - 1 loop
      -- Zero extend shift
      SftAfter_v := resize(r.OutCnt(stg), SftAfter_v'length);

      -- Shift
      v.OutCnt(stg + 1) := r.OutCnt(stg);
      StgIdx_v          := SftStgAfterApprox_c - 1 - stg;
      SftStepAfter_v    := 2**(2 * (StgIdx_v));
      v.OutSft(stg + 1) := psi_fix_shift_right(r.OutSft(stg), OutFmtNorm_c, to_integer(r.OutCnt(stg)(2 * StgIdx_v + 1 downto 2 * StgIdx_v)) * SftStepAfter_v, 3 * SftStepAfter_v, OutFmtNorm_c, psi_fix_trunc, psi_fix_wrap, true);
    end loop;

    -- *** Output resize ***
    v.OutRes := psi_fix_shift_left(r.OutSft(r.OutSft'high), OutFmtNorm_c, in_fmt_g.I, in_fmt_g.I, out_fmt_g, round_g, sat_g);

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Output Assignment
  --------------------------------------------------------------------------
  dat_o <= r.OutRes;
  vld_o <= r.OutVld(r.OutVld'high);

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.InVld  <= (others => '0');
        r.OutVld <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------
  SqrtIn_s   <= psi_fix_resize(r.InSft(r.InSft'high), LimFmt_c, SqrtInFmt_c);
  IsZeroIn_s <= '1' when unsigned(SqrtIn_s) = 0 else '0';
  inst_sqrt : entity work.psi_fix_lin_approx_sqrt18b
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i   => r.InVld(r.InVld'high),
      dat_i  => SqrtIn_s,
      vld_o  => SqrtVld_s,
      dat_o => SqrtData_s
    );

  -- Count delayed with FIFO to stay working of delay of the approximation should hcange in future
  fifo : block
    signal FifoIn, FifoOut : std_logic_vector(SftStgBeforeApprox_c downto 0);
  begin
    FifoIn      <= IsZeroIn_s & std_logic_vector(r.SftCnt(r.SftCnt'high));
    inst_sft_del : entity work.psi_common_sync_fifo
      generic map(
        Width_g       => SftStgBeforeApprox_c + 1,
        Depth_g       => 16,
        RamBehavior_g => ram_behavior_g
      )
      port map(
        Clk     => clk_i,
        Rst     => rst_i,
        InData  => FifoIn,
        InVld   => r.InVld(r.InVld'high),
        OutData => FifoOut,
        OutRdy  => SqrtVld_s
      );
    SftCntOut_s <= FifoOut(SftCntOut_s'high downto 0);
    IsZeroOut_s <= FifoOut(FifoOut'high);
  end block;

end architecture;
