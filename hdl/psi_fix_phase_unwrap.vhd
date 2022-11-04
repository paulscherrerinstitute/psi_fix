------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- unwrap phase signal for instance +/- 180 -> 360° and so on with indicator
------------------------------------------------------------------------------
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
    in_fmt_g   : psi_fix_fmt_t := (1, 0, 15);                           -- input format
    out_fmt_g  : psi_fix_fmt_t := (0, 1, 15);                           -- output format
    round_g    : psi_fix_rnd_t := psi_fix_trunc;                        -- round or trunc
    rst_pol_g  : std_logic   := '1'                                     -- reset polarity
  );
  port(
    clk_i  : in  std_logic;                                             -- $$ type=Clk; freq=127e6 $$
    rst_i  : in  std_logic;                                             -- $$ type=Rst; Clk=Clk $$
    dat_i  : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data input
    vld_i  : in  std_logic;                                             -- valid signal input
    dat_o  : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);-- data output
    vld_o  : out std_logic;                                             -- valid signal output
    wrap_o : out std_logic                                              -- wrap output
  );
end entity;

architecture rtl of psi_fix_phase_unwrap is

  -- Constants
  constant SumFmt_c  : psi_fix_fmt_t := (1, max(out_fmt_g.I + 1, 1), in_fmt_g.F);
  constant DiffFmt_c : psi_fix_fmt_t := (1, 0, in_fmt_g.F);

  -- Two Process Method
  type two_process_r is record
    Vld       : std_logic_vector(0 to 3);
    InData_0  : std_logic_vector(dat_i'range);
    InData_1  : std_logic_vector(dat_i'range);
    InLast_0  : std_logic_vector(dat_i'range);
    Diff_1    : std_logic_vector(psi_fix_size(DiffFmt_c) - 1 downto 0);
    Sum_2     : std_logic_vector(psi_fix_size(SumFmt_c) - 1 downto 0);
    Wrap_2    : std_logic;
    OutData_3 : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutWrap_3 : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  assert out_fmt_g.S = 1 report "###ERROR###: psi_fix_phase_unwrap: output format must be signed!" severity error;
  assert out_fmt_g.I >= 1 report "###ERROR###: psi_fix_phase_unwrap: output format must at least have one integer bit!" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  proc_comb : process(r, vld_i, dat_i)
    variable Sum_v  : std_logic_vector(psi_fix_size(SumFmt_c) - 1 downto 0);
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
      v.Diff_1   := psi_fix_sub(r.InData_0, in_fmt_g, r.InLast_0, in_fmt_g, DiffFmt_c, psi_fix_trunc, psi_fix_wrap);
      v.InData_1 := r.InData_0;
    end if;

    -- *** Stage 2 (Summation) ***
    Sum_v  := psi_fix_add(r.Sum_2, SumFmt_c, r.Diff_1, DiffFmt_c, SumFmt_c);
    Wrap_v := '0';
    if not psi_fix_in_range(Sum_v, SumFmt_c, out_fmt_g, round_g) then
      Sum_v  := psi_fix_resize(r.InData_1, in_fmt_g, SumFmt_c);
      Wrap_v := '1';
    end if;
    if r.Vld(1) = '1' then
      v.Sum_2  := Sum_v;
      v.Wrap_2 := Wrap_v;
    end if;

    -- *** Stage 3 (Output Rounding) ***
    if r.Vld(2) = '1' then
      v.OutData_3 := psi_fix_resize(r.Sum_2, SumFmt_c, out_fmt_g, round_g);
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
