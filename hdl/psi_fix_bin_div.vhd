---------------------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- Description
---------------------------------------------------------------------------------------------
-- This component calculates a binary division of two fixed point values.
-- https://github.com/paulscherrerinstitute/psi_fix/blob/refactor/doc_beta/psi_fix_bin_div.md
----------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_common_math_pkg.all;

-- @formatter:off
entity psi_fix_bin_div is
  generic(
       num_fmt_g     : psi_fix_fmt_t := (1, 0, 17);                                -- numerator format
       denom_fmt_g   : psi_fix_fmt_t := (0, 0, 17);                                -- denominator format
       out_fmt_g     : psi_fix_fmt_t := (1, 0, 25);                                -- ouput format
       round_g       : psi_fix_rnd_t := psi_fix_trunc;                             -- rounding or trunc
       sat_g         : psi_fix_sat_t := psi_fix_sat;                               -- saturation or wrap
       rst_pol_g     : std_logic   := '1';                                         -- polarity reset
       rst_sync_g    : boolean     := true                                         -- sync reset ?
        );
  port(
       clk_i         : in  std_logic;                                                -- clk system
       rst_i         : in  std_logic;                                                -- rst system depends on polarity
       vld_i         : in  std_logic;                                                -- valid signal input
       rdy_i         : out std_logic;                                                -- ready signal output
       numerator_i   : in  std_logic_vector(psi_fix_size(num_fmt_g) - 1 downto 0);   -- numerator to divide
       denominator_i : in  std_logic_vector(psi_fix_size(denom_fmt_g) - 1 downto 0); -- denominator divider
       vld_o         : out std_logic;                                                -- valid output signal
       result_o      : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0)    -- result output = Num/Den
        );
end entity;
-- @formatter:on

architecture rtl of psi_fix_bin_div is

  -- constants
  constant first_shift_c    : integer       := out_fmt_g.I;
  constant num_abs_fmt_c    : psi_fix_fmt_t := (0, num_fmt_g.I + num_fmt_g.S, num_fmt_g.F);
  constant denom_abs_fmt_c  : psi_fix_fmt_t := (0, denom_fmt_g.I + denom_fmt_g.S, denom_fmt_g.F);
  constant result_int_fmt_c : psi_fix_fmt_t := (1, out_fmt_g.I + 1, out_fmt_g.F + 1);
  constant denom_comp_fmt_c : psi_fix_fmt_t := (0, denom_abs_fmt_c.I + first_shift_c, denom_abs_fmt_c.F - first_shift_c);
  constant num_comp_fmt_c   : psi_fix_fmt_t := (0, max(denom_comp_fmt_c.I, num_abs_fmt_c.I), max(denom_comp_fmt_c.F, num_abs_fmt_c.F));
  constant iterations_c     : integer       := out_fmt_g.I + out_fmt_g.F + 2;

  -- types
  type State_t is (Idle_s, Init1_s, Init2_s, Calc_s, Output_s);

  -- Two process method
  type two_process_r is record
    State     : State_t;
    Num       : std_logic_vector(numerator_i'range);
    Denom     : std_logic_vector(denominator_i'range);
    NumSign   : std_logic;
    DenomSign : std_logic;
    NumAbs    : std_logic_vector(psi_fix_size(num_abs_fmt_c) - 1 downto 0);
    DenomAbs  : std_logic_vector(psi_fix_size(denom_abs_fmt_c) - 1 downto 0);
    DenomComp : std_logic_vector(psi_fix_size(denom_comp_fmt_c) - 1 downto 0);
    NumComp   : std_logic_vector(psi_fix_size(num_comp_fmt_c) - 1 downto 0);
    IterCnt   : integer range 0 to iterations_c      - 1;
    ResultInt : std_logic_vector(psi_fix_size(result_int_fmt_c) - 1 downto 0);
    OutVld    : std_logic;
    OutQuot   : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    InRdy     : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(vld_i, numerator_i, denominator_i, r)
    variable v               : two_process_r;
    variable NumInDenomFmt_v : std_logic_vector(psi_fix_size(denom_comp_fmt_c) - 1 downto 0);
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** State Machine ***
    v.InRdy         := '0';
    v.OutVld        := '0';
    NumInDenomFmt_v := (others => '0');
    case r.State is
      when Idle_s =>
        -- start execution if valid
        if vld_i = '1' then
          v.State := Init1_s;
          v.Num   := numerator_i;
          v.Denom := denominator_i;
        else
          v.InRdy := '1';
        end if;

      when Init1_s =>
        -- state handling
        v.State    := Init2_s;
        -- latch signs
        if num_fmt_g.S = 0 then
          v.NumSign := '0';
        else
          v.NumSign := r.Num(r.Num'left);
        end if;
        if denom_fmt_g.S = 0 then
          v.DenomSign := '0';
        else
          v.DenomSign := r.Denom(r.Denom'left);
        end if;
        -- calculate absolute values
        v.NumAbs   := psi_fix_abs(r.Num, num_fmt_g, num_abs_fmt_c);
        v.DenomAbs := psi_fix_abs(r.Denom, denom_fmt_g, denom_abs_fmt_c);

      when Init2_s =>
        -- state handling
        v.State     := Calc_s;
        -- Initialize calculation
        v.DenomComp := psi_fix_shift_left(r.DenomAbs, denom_abs_fmt_c, first_shift_c, first_shift_c, denom_comp_fmt_c);
        v.NumComp   := psi_fix_resize(r.NumAbs, num_abs_fmt_c, num_comp_fmt_c);
        v.IterCnt   := iterations_c      - 1;
        v.ResultInt := (others => '0');

      when Calc_s =>
        -- state handling
        if r.IterCnt = 0 then
          v.State := Output_s;
        else
          v.IterCnt := r.IterCnt - 1;
        end if;

        -- Calculation
        v.ResultInt     := shift_left(r.ResultInt, 1);
        NumInDenomFmt_v := psi_fix_resize(r.NumComp, num_comp_fmt_c, denom_comp_fmt_c, psi_fix_trunc, psi_fix_wrap);
        if unsigned(r.DenomComp) <= unsigned(NumInDenomFmt_v) then
          v.ResultInt(0) := '1';
          v.NumComp      := psi_fix_sub(r.NumComp, num_comp_fmt_c, r.DenomComp, denom_comp_fmt_c, num_comp_fmt_c);
        end if;
        v.NumComp       := psi_fix_shift_left(v.NumComp, num_comp_fmt_c, 1, 1, num_comp_fmt_c, psi_fix_trunc, psi_fix_sat);

      when Output_s =>
        v.State  := Idle_s;
        v.OutVld := '1';
        v.InRdy  := '1';
        if out_fmt_g.S = 1 then
          if r.NumSign /= r.DenomSign then
            v.OutQuot := psi_fix_neg(r.ResultInt, result_int_fmt_c, out_fmt_g, round_g, sat_g);
          else
            v.OutQuot := psi_fix_resize(r.ResultInt, result_int_fmt_c, out_fmt_g, round_g, sat_g);
          end if;
        else
          v.OutQuot := psi_fix_resize(r.ResultInt, result_int_fmt_c, out_fmt_g, round_g, sat_g);
        end if;

      when others => null;
    end case;

    -- *** Assign to signal ***
    r_next <= v;

  end process;

  -- *** Outputs ***
  vld_o    <= r.OutVld;
  result_o <= r.OutQuot;
  rdy_i    <= r.InRdy;

  sync_rst_gene : if rst_sync_g generate
  begin
    p_seq : process(clk_i)
    begin
      if rising_edge(clk_i) then
        r <= r_next;
        if rst_i = rst_pol_g then
          r.State  <= Idle_s;
          r.OutVld <= '0';
          r.InRdy  <= '0';
        end if;
      end if;
    end process;
  end generate;

  async_rst_gene : if not rst_sync_g generate
  begin
    p_seq : process(clk_i,rst_i)
    begin
       if rst_i = rst_pol_g then
          r.State  <= Idle_s;
          r.OutVld <= '0';
          r.InRdy  <= '0';
      elsif rising_edge(clk_i) then
        r <= r_next;
      end if;
    end process;
  end generate;

end architecture;

