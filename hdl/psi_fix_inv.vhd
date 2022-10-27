library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ tbpkg=psi_lib.psi_tb_textfile_pkg,psi_lib.psi_tb_txt_util $$
-- $$ processes=stimuli,response $$
entity psi_fix_inv is
  generic(
    in_fmt_g       : psi_fix_fmt_t := (0, 0, 15);  -- Must be unsigned, wuare root not defined for negative numbers
    out_fmt_g      : psi_fix_fmt_t := (0, 1, 15);  -- output fomrat FP
    round_g       : psi_fix_rnd_t := psi_fix_trunc; -- round or trunc
    sat_g         : psi_fix_sat_t := psi_fix_wrap;  -- sat or wrap
    ram_behavior_g : string      := "RBW"          -- RBW = Read before write, WBR = write before read
  );
  port(
    clk_i : in  std_logic;                                           -- system clock $$ type=Clk; freq=127e6 $$
    rst_i : in  std_logic;                                           -- system reset $$ type=Rst; Clk=Clk $$   
    dat_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);  -- data input
    vld_i : in  std_logic;                                           -- valid signal input frequency sampling
    dat_o : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0); -- data output 
    vld_o : out std_logic                                            -- valid output frequency samlping
    );
end entity;

architecture rtl of psi_fix_inv is

  -- Constants
  constant InFmtNorm_c          : psi_fix_fmt_t := (0, 1, in_fmt_g.I + in_fmt_g.F);
  constant OutFmtNorm_c         : psi_fix_fmt_t := (0, 1 + in_fmt_g.F, out_fmt_g.I + out_fmt_g.F);
  constant InvInFmt_c           : psi_fix_fmt_t := (0, 1, 18);
  constant InvOutFmt_c          : psi_fix_fmt_t := (0, 0, 18);
  constant MaxSft_c             : natural     := InFmtNorm_c.F;
  constant SftStgBeforeApprox_c : natural     := log2ceil(MaxSft_c);
  constant SftStgAfterApprox_c  : natural     := SftStgBeforeApprox_c;
  constant NormSft_c            : integer     := in_fmt_g.I - 1;
  constant AbsFmt_c             : psi_fix_fmt_t := (0, in_fmt_g.I, in_fmt_g.F);
  constant AbsFullFmt_c         : psi_fix_fmt_t := (0, AbsFmt_c.I + 1, AbsFmt_c.F);

  -- types
  type CntArray_t is array (natural range <>) of unsigned(SftStgBeforeApprox_c - 1 downto 0);
  type OutSftArray_t is array (natural range <>) of std_logic_vector(psi_fix_size(OutFmtNorm_c) - 1 downto 0);
  type InSftArray_t is array (natural range <>) of std_logic_vector(psi_fix_size(InFmtNorm_c) - 1 downto 0);

  -- Two Process Method
  type two_process_r is record
    InVld     : std_logic_vector(0 to 3 + SftStgBeforeApprox_c - 1);
    InSign    : std_logic_vector(0 to 3 + SftStgBeforeApprox_c - 1);
    AbsFull_0 : std_logic_vector(psi_fix_size(AbsFullFmt_c) - 1 downto 0);
    Abs_1     : std_logic_vector(psi_fix_size(AbsFmt_c) - 1 downto 0);
    Norm_2    : std_logic_vector(psi_fix_size(InFmtNorm_c) - 1 downto 0);
    InSft     : InSftArray_t(0 to SftStgBeforeApprox_c - 1);
    SftCnt    : CntArray_t(0 to SftStgBeforeApprox_c - 1);
    OutVld    : std_logic_vector(0 to SftStgAfterApprox_c + 2);
    OutSign   : std_logic_vector(0 to SftStgAfterApprox_c + 1);
    OutSft    : OutSftArray_t(0 to SftStgAfterApprox_c);
    OutCnt    : CntArray_t(0 to SftStgAfterApprox_c);
    Denorm    : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutRes    : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

  -- Component Instantiation
  signal InvIn_s     : std_logic_vector(psi_fix_size(InvInFmt_c) - 1 downto 0);
  signal SftCntOut_s : std_logic_vector(SftStgBeforeApprox_c - 1 downto 0);
  signal SignIn_s    : std_logic;
  signal SignOut_s   : std_logic;
  signal InvVld_s    : std_logic;
  signal InvData_s   : std_logic_vector(psi_fix_size(InvOutFmt_c) - 1 downto 0);

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  -- None

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  proc_comb : process(r, vld_i, dat_i, SftCntOut_s, InvVld_s, InvData_s, SignOut_s)
    variable v              : two_process_r;
    variable SftBeforeIn_v  : std_logic_vector(psi_fix_size(InFmtNorm_c) - 1 downto 0);
    variable SftBefore_v    : integer;
    variable SftAfter_v     : unsigned(SftStgBeforeApprox_c downto 0);
    variable SftStepAfter_v : integer;
    variable StgIdx_v       : integer;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.InVld(v.InVld'low + 1 to v.InVld'high)       := r.InVld(r.InVld'low to r.InVld'high - 1);
    v.OutVld(v.OutVld'low + 1 to v.OutVld'high)    := r.OutVld(r.OutVld'low to r.OutVld'high - 1);
    v.InSign(v.InSign'low + 1 to v.InSign'high)    := r.InSign(r.InSign'low to r.InSign'high - 1);
    v.OutSign(v.OutSign'low + 1 to v.OutSign'high) := r.OutSign(r.OutSign'low to r.OutSign'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.InVld(0)  := vld_i;
    if in_fmt_g.S = 0 then
      v.InSign(0) := '0';
    else
      v.InSign(0) := dat_i(dat_i'high);
    end if;
    v.AbsFull_0 := psi_fix_abs(dat_i, in_fmt_g, AbsFullFmt_c, psi_fix_trunc, psi_fix_wrap);

    -- *** Stage 1 ***
    v.Abs_1 := psi_fix_resize(r.AbsFull_0, AbsFullFmt_c, AbsFmt_c, psi_fix_trunc, psi_fix_sat);

    -- *** Stage 2 ***
    if NormSft_c > 0 then
      v.Norm_2 := psi_fix_shift_right(r.Abs_1, AbsFmt_c, NormSft_c, NormSft_c, InFmtNorm_c, psi_fix_trunc, psi_fix_wrap);
    else
      v.Norm_2 := psi_fix_shift_left(r.Abs_1, AbsFmt_c, -NormSft_c, -NormSft_c, InFmtNorm_c, psi_fix_trunc, psi_fix_wrap);
    end if;

    -- *** Shift stages (0 ... x) ***
    for stg in 0 to SftStgBeforeApprox_c - 1 loop
      -- Select input 
      if stg = 0 then
        SftBeforeIn_v := r.Norm_2;
        v.SftCnt(stg) := (others => '0');
      else
        SftBeforeIn_v := r.InSft(stg - 1);
        v.SftCnt(stg) := r.SftCnt(stg - 1);
      end if;

      -- Do Shift
      SftBefore_v := 2**(SftStgBeforeApprox_c - stg - 1);
      if unsigned(SftBeforeIn_v(SftBeforeIn_v'left downto SftBeforeIn_v'left - SftBefore_v + 1)) = 0 then
        v.InSft(stg)                                  := SftBeforeIn_v(SftBeforeIn_v'left - SftBefore_v downto 0) & ZerosVector(SftBefore_v);
        v.SftCnt(stg)(SftStgBeforeApprox_c - stg - 1) := '1';
      else
        v.InSft(stg)                                  := SftBeforeIn_v;
        v.SftCnt(stg)(SftStgBeforeApprox_c - stg - 1) := '0';
      end if;
    end loop;

    -- *** Out Stage 0 ***
    v.OutVld(0)  := InvVld_s;
    v.OutSign(0) := SignOut_s;
    v.OutSft(0)  := psi_fix_resize(InvData_s, InvOutFmt_c, OutFmtNorm_c);
    v.OutCnt(0)  := unsigned(SftCntOut_s);

    -- *** Out Shift Stages ***
    for stg in 0 to SftStgAfterApprox_c - 1 loop
      -- Zero extend shift 
      SftAfter_v := resize(r.OutCnt(stg), SftAfter_v'length);

      -- Shift
      v.OutCnt(stg + 1) := r.OutCnt(stg);
      StgIdx_v          := SftStgAfterApprox_c - 1 - stg;
      SftStepAfter_v    := 2**(StgIdx_v);
      --v.OutSft(stg+1)	:= psi_fix_shift_left(r.OutSft(stg), OutFmtNorm_c, 0, SftStepAfter_v, OutFmtNorm_c, psi_fix_trunc, psi_fix_wrap, true);
      v.OutSft(stg + 1) := psi_fix_shift_left(r.OutSft(stg), OutFmtNorm_c, to_integer(r.OutCnt(stg)(StgIdx_v downto StgIdx_v)) * SftStepAfter_v, SftStepAfter_v, OutFmtNorm_c, psi_fix_trunc, psi_fix_wrap, true);
    end loop;

    -- *** Denormalize ***
    if NormSft_c > 0 then
      v.Denorm := psi_fix_shift_right(r.OutSft(r.OutSft'high), OutFmtNorm_c, NormSft_c, NormSft_c, out_fmt_g, round_g, sat_g);
    else
      v.Denorm := psi_fix_shift_left(r.OutSft(r.OutSft'high), OutFmtNorm_c, -NormSft_c, -NormSft_c, out_fmt_g, round_g, sat_g);
    end if;

    -- Sign Handling
    if in_fmt_g.S = 0 or r.OutSign(r.OutSign'high) = '0' then
      v.OutRes := r.Denorm;
    else
      v.OutRes := psi_fix_neg(r.Denorm, out_fmt_g, out_fmt_g, psi_fix_trunc, sat_g);
    end if;

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
      if rst_i = '1' then
        r.InVld  <= (others => '0');
        r.OutVld <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiation
  --------------------------------------------------------------------------
  InvIn_s  <= psi_fix_resize(r.InSft(r.InSft'high), InFmtNorm_c, InvInFmt_c);
  SignIn_s <= r.InSign(r.InSign'high);
  inst_sqrt : entity work.psi_fix_lin_approx_inv18b
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i   => r.InVld(r.InVld'high),
      dat_i  => InvIn_s,
      vld_o  => InvVld_s,
      dat_o => InvData_s
    );

  -- Count delayed with FIFO to stay working of delay of the approximation should hcange in future
  fifo : block
    signal FifoIn, FifoOut : std_logic_vector(SftStgBeforeApprox_c downto 0);
    signal SftCntLim       : std_logic_vector(SftStgBeforeApprox_c - 1 downto 0);
  begin
    SftCntLim   <= std_logic_vector(to_unsigned(MaxSft_c, SftCntLim'length)) when unsigned(r.SftCnt(r.SftCnt'high)) > MaxSft_c else std_logic_vector(r.SftCnt(r.SftCnt'high));
    FifoIn      <= SignIn_s & SftCntLim;
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
        OutRdy  => InvVld_s
      );
    SftCntOut_s <= FifoOut(SftCntOut_s'high downto 0);
    SignOut_s   <= FifoOut(FifoOut'high);
  end block;

end architecture;
