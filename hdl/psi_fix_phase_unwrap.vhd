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
entity psi_fix_phase_unwrap is
  generic(
    InFmt_g   : PsiFixFmt_t := (1, 0, 15);
    OutFmt_g  : PsiFixFmt_t := (0, 1, 15);
    Round_g   : PsiFixRnd_t := PsiFixTrunc;
    rst_pol_g : std_logic   := '1'
  );
  port(
    clk_i  : in  std_logic;             -- $$ type=Clk; freq=127e6 $$
    rst_i  : in  std_logic;             -- $$ type=Rst; Clk=Clk $$
    vld_i  : in  std_logic;
    dat_i  : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
    vld_o  : out std_logic;
    dat_o  : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    wrap_o : out std_logic
  );
end entity;

architecture rtl of psi_fix_phase_unwrap is

  -- Constants
  constant SumFmt_c  : PsiFixFmt_t := (1, max(OutFmt_g.I + 1, 1), InFmt_g.F);
  constant DiffFmt_c : PsiFixFmt_t := (1, 0, InFmt_g.F);

  -- Two Process Method
  type two_process_r is record
    Vld       : std_logic_vector(0 to 3);
    InData_0  : std_logic_vector(dat_i'range);
    InData_1  : std_logic_vector(dat_i'range);
    InLast_0  : std_logic_vector(dat_i'range);
    Diff_1    : std_logic_vector(PsiFixSize(DiffFmt_c) - 1 downto 0);
    Sum_2     : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);
    Wrap_2    : std_logic;
    OutData_3 : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    OutWrap_3 : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------	
  assert OutFmt_g.S = 1 report "###ERROR###: psi_fix_phase_unwrap: output format must be signed!" severity error;
  assert OutFmt_g.I >= 1 report "###ERROR###: psi_fix_phase_unwrap: output format must at least have one integer bit!" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  proc_comb : process(r, vld_i, dat_i)
    variable Sum_v  : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);
    variable Wrap_v : std_logic;
    variable v      : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high) := r.Vld(r.Vld'low to r.Vld'high - 1);

    -- *** Stage 0 (Input Stage) ***
    v.Vld(0)   := vld_i;
    v.InData_0 := dat_i;
    -- Delay input data by one sample
    if r.Vld(0) = '1' then
      v.InLast_0 := r.InData_0;
    end if;

    -- *** Stage 1 (Differentiate) ***
    if r.Vld(0) = '1' then
      v.Diff_1   := PsiFixSub(r.InData_0, InFmt_g, r.InLast_0, InFmt_g, DiffFmt_c, PsiFixTrunc, PsiFixWrap);
      v.InData_1 := r.InData_0;
    end if;

    -- *** Stage 2 (Summation) ***
    Sum_v  := PsiFixAdd(r.Sum_2, SumFmt_c, r.Diff_1, DiffFmt_c, SumFmt_c);
    Wrap_v := '0';
    if not PsiFixInRange(Sum_v, SumFmt_c, OutFmt_g, Round_g) then
      Sum_v  := PsiFixResize(r.InData_1, InFmt_g, SumFmt_c);
      Wrap_v := '1';
    end if;
    if r.Vld(1) = '1' then
      v.Sum_2  := Sum_v;
      v.Wrap_2 := Wrap_v;
    end if;

    -- *** Stage 3 (Output Rounding) ***
    if r.Vld(2) = '1' then
      v.OutData_3 := PsiFixResize(r.Sum_2, SumFmt_c, OutFmt_g, Round_g);
      v.OutWrap_3 := r.Wrap_2;
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Output Assignment
  --------------------------------------------------------------------------
  vld_o  <= r.Vld(3);
  dat_o  <= r.OutData_3;
  wrap_o <= r.OutWrap_3;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.InLast_0 <= (others => '0');
        r.Vld      <= (others => '0');
        r.Sum_2    <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
