------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.en_cl_fix_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_fix_pkg is

  --------------------------------------------------------------------------
  -- Definitions
  --------------------------------------------------------------------------
  type psi_fix_fmt_t is record
    s : natural range 0 to 1;           -- Sign bit
    i : integer;                        -- Integer bits
    f : integer;                        -- Fractional bits
  end record;

  type psi_fix_fmt_array_t is array (natural range <>) of psi_fix_fmt_t;

  type psi_fix_rnd_t is (psi_fix_round, psi_fix_trunc);

  type psi_fix_sat_t is (psi_fix_wrap, psi_fix_sat);

  --------------------------------------------------------------------------
  -- Helpers
  --------------------------------------------------------------------------
  function psi_fix_choose_fmt(sel : boolean;
                              fmt_a  : psi_fix_fmt_t;
                              fmt_b  : psi_fix_fmt_t)
  return psi_fix_fmt_t;  -- fmt_a if true, otherwise fmt_b

  --------------------------------------------------------------------------
  -- Conversions between PSI and Enclustra Definitions
  --------------------------------------------------------------------------
  function psi_fix2_cl_fix(rnd : psi_fix_rnd_t)
  return FixRound_t;

  function psi_fix2_cl_fix(sat : psi_fix_sat_t)
  return FixSaturate_t;

  function psi_fix2_cl_fix(fmt : psi_fix_fmt_t)
  return FixFormat_t;

  function psi_fix2_cl_fix(fmts : psi_fix_fmt_array_t)
  return FixFormatArray_t;

  function cl_fix2_psi_fix(rnd : FixRound_t)
  return psi_fix_rnd_t;

  function cl_fix2_psi_fix(sat : FixSaturate_t)
  return psi_fix_sat_t;

  function cl_fix2_psi_fix(fmt : FixFormat_t)
  return psi_fix_fmt_t;

  function cl_fix2_psi_fix(fmts : FixFormatArray_t)
  return psi_fix_fmt_array_t;

  --------------------------------------------------------------------------
  -- Bittrue available in Python
  --------------------------------------------------------------------------
  function psi_fix_size(fmt : psi_fix_fmt_t)
  return integer;

  function psi_fix_from_real(a    : real;
                             r_fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function psi_fix_from_bits_as_int(a    : integer;
                                    a_fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function psi_fix_get_bits_as_int(a    : std_logic_vector;
                                   a_fmt : psi_fix_fmt_t)
  return integer;

  function psi_fix_resize(a    : std_logic_vector;
                        a_fmt : psi_fix_fmt_t;
                        r_fmt : psi_fix_fmt_t;
                        rnd  : psi_fix_rnd_t := psi_fix_trunc;
                        sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_add(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     b_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_sub(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     b_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_mult(a    : std_logic_vector;
                      a_fmt : psi_fix_fmt_t;
                      b    : std_logic_vector;
                      b_fmt : psi_fix_fmt_t;
                      r_fmt : psi_fix_fmt_t;
                      rnd  : psi_fix_rnd_t := psi_fix_trunc;
                      sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_abs(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_neg(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector;

  function psi_fix_shift_left(a        : std_logic_vector;
                           a_fmt     : psi_fix_fmt_t;
                           shift    : integer;
                           maxShift : integer;
                           r_fmt     : psi_fix_fmt_t;
                           rnd      : psi_fix_rnd_t := psi_fix_trunc;
                           sat      : psi_fix_sat_t := psi_fix_wrap;
                           dynamic  : boolean     := False)
  return std_logic_vector;

  function psi_fix_shift_right(a        : std_logic_vector;
                            a_fmt     : psi_fix_fmt_t;
                            shift    : integer;
                            maxShift : integer;
                            r_fmt     : psi_fix_fmt_t;
                            rnd      : psi_fix_rnd_t := psi_fix_trunc;
                            sat      : psi_fix_sat_t := psi_fix_wrap;
                            dynamic  : boolean     := False)
  return std_logic_vector;

  function psi_fix_upper_bound_stdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function psi_fix_lower_bound_stdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function psi_fix_upper_bound_Real(fmt : psi_fix_fmt_t)
  return real;

  function psi_fix_lower_bound_Real(fmt : psi_fix_fmt_t)
  return real;

  function psi_fix_in_range(a    : std_logic_vector;
                         a_fmt : psi_fix_fmt_t;
                         r_fmt : psi_fix_fmt_t;
                         rnd  : psi_fix_rnd_t := psi_fix_trunc)
  return boolean;

  -- Allowed comparisons: "a=b", "a<b", "a>b", "a<=b", "a>=b",  "a!=b"
  function psi_fix_compare(comparison : string;
                         a          : std_logic_vector;
                         a_fmt       : psi_fix_fmt_t;
                         b          : std_logic_vector;
                         b_fmt       : psi_fix_fmt_t) return boolean;

  --------------------------------------------------------------------------
  -- VHDL Only
  --------------------------------------------------------------------------
  function psi_fix_to_real(a    : std_logic_vector;
                        a_fmt : psi_fix_fmt_t)
  return real;

  function psi_fix_round_from_string(s : string)
  return psi_fix_rnd_t;

  function psi_fix_sat_from_string(s : string)
  return psi_fix_sat_t;

  function psi_fix_fmt_from_string(str : string) return psi_fix_fmt_t;

  function psi_fix_fmt_to_string(a_fmt : psi_fix_fmt_t) return string;

end psi_fix_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_fix_pkg is

  --------------------------------------------------------------------------
  -- Helpers
  --------------------------------------------------------------------------
  function psi_fix_choose_fmt(sel  : boolean;
                           fmt_A : psi_fix_fmt_t;
                           fmt_B : psi_fix_fmt_t)
  return psi_fix_fmt_t is
  begin
    if sel then
      return fmt_A;
    else
      return fmt_B;
    end if;
  end function;

  function psi_fix_str_to_Int(str : string) return integer is
    variable Idx_v    : integer := str'low;
    variable IsNeg_v  : boolean := false;
    variable ValAbs_v : integer := 0;
  begin
    -- skip leading white-spaces
    while (Idx_v <= str'high) and str(Idx_v) = ' ' loop
      Idx_v := Idx_v + 1;
    end loop;

    -- Check signal
    if (Idx_v <= str'high) and (str(Idx_v) = '-') then
      IsNeg_v := true;
      Idx_v   := Idx_v + 1;
    end if;

    -- Parse Integer
    while (Idx_v <= str'high) and (str(Idx_v) <= '9') and (str(Idx_v) >= '0') loop
      ValAbs_v := ValAbs_v * 10 + (character'pos(str(Idx_v)) - character'pos('0'));
      Idx_v    := Idx_v + 1;
    end loop;

    -- Return
    if IsNeg_v then
      return -ValAbs_v;
    else
      return ValAbs_v;
    end if;
  end function;

  --------------------------------------------------------------------------
  -- Conversions between PSI and Enclustra Definitions
  --------------------------------------------------------------------------
  function psi_fix2_cl_fix(rnd : psi_fix_rnd_t)
  return FixRound_t is
  begin
    case rnd is
      when psi_fix_round => return NonSymPos_s;
      when psi_fix_trunc => return Trunc_s;
      when others => report "psi_fix_pkg: Unsupported Rounding Mode" severity error;
        return Trunc_s;
    end case;
  end function;

  function psi_fix2_cl_fix(sat : psi_fix_sat_t)
  return FixSaturate_t is
  begin
    case sat is
      when psi_fix_sat  => return Sat_s;
      when psi_fix_wrap => return None_s;
      when others => report "psi_fix_pkg: Unsupported Saturation Mode" severity error;
        return None_s;
    end case;
  end function;

  function psi_fix2_cl_fix(fmt : psi_fix_fmt_t)
  return FixFormat_t is
  begin
    return ((fmt.S = 1), fmt.I, fmt.F);
  end function;

  function psi_fix2_cl_fix(fmts : psi_fix_fmt_array_t)
  return FixFormatArray_t is
    variable Fmts_v : FixFormatArray_t(fmts'range);
  begin
    for i in fmts'range loop
      Fmts_v(i) := psi_fix2_cl_fix(fmts(i));
    end loop;
    return Fmts_v;
  end function;

  function cl_fix2_psi_fix(rnd : FixRound_t)
  return psi_fix_rnd_t is
  begin
    case rnd is
      when NonSymPos_s => return psi_fix_round;
      when Trunc_s     => return psi_fix_trunc;
      when others => report "psi_fix_pkg: Unsupported Rounding Mode (only Round/Trunc are supported)" severity error;
        return psi_fix_trunc;
    end case;
  end function;

  function cl_fix2_psi_fix(sat : FixSaturate_t)
  return psi_fix_sat_t is
  begin
    case sat is
      when Sat_s  => return psi_fix_sat;
      when None_s => return psi_fix_wrap;
      when others => report "psi_fix_pkg: Unsupported Saturation Mode (only Sat/Wrap are supported)" severity error;
        return psi_fix_wrap;
    end case;
  end function;

  function cl_fix2_psi_fix(fmt : FixFormat_t)
  return psi_fix_fmt_t is
  begin
    return (choose(fmt.Signed, 1, 0), fmt.Intbits, fmt.FracBits);
  end function;

  function cl_fix2_psi_fix(fmts : FixFormatArray_t)
  return psi_fix_fmt_array_t is
    variable Fmts_v : psi_fix_fmt_array_t(fmts'range);
  begin
    for i in fmts'range loop
      Fmts_v(i) := cl_fix2_psi_fix(fmts(i));
    end loop;
    return Fmts_v;
  end function;

  --------------------------------------------------------------------------
  -- Psi Fix Functionality
  --------------------------------------------------------------------------
  -- *** psi_fix_size ***
  function psi_fix_size(fmt : psi_fix_fmt_t)
  return integer is
  begin
    return cl_fix_width(psi_fix2_cl_fix(fmt));
  end function;

  -- *** psi_fix_from_real ***
  function psi_fix_from_real(a    : real;
                          r_fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    -- assertions
    assert (r_fmt.S = 1) or (a >= 0.0) report "psi_fix_from_real: Unsigned format but negative number" severity error;
    -- implementation
    return cl_fix_from_real(a, psi_fix2_cl_fix(r_fmt));
  end function;

  -- *** psi_fix_to_real ***
  function psi_fix_to_real(a    : std_logic_vector;
                        a_fmt : psi_fix_fmt_t)
  return real is

  begin
    return cl_fix_to_real(a, psi_fix2_cl_fix(a_fmt));
  end function;

  -- *** psi_fix_from_bits_as_int ***
  function psi_fix_from_bits_as_int(a    : integer;
                               a_fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_from_bits_as_int(a, psi_fix2_cl_fix(a_fmt));
  end function;

  -- *** psi_fix_get_bits_as_int ***
  function psi_fix_get_bits_as_int(a    : std_logic_vector;
                              a_fmt : psi_fix_fmt_t)
  return integer is
  begin
    return cl_fix_get_bits_as_int(a, psi_fix2_cl_fix(a_fmt));
  end function;

  -- *** psi_fix_resize ***
  function psi_fix_resize(a    : std_logic_vector;
                        a_fmt : psi_fix_fmt_t;
                        r_fmt : psi_fix_fmt_t;
                        rnd  : psi_fix_rnd_t := psi_fix_trunc;
                        sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_resize(a, psi_fix2_cl_fix(a_fmt), psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_add ***
  function psi_fix_add(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     b_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_add(a, psi_fix2_cl_fix(a_fmt),
                      b, psi_fix2_cl_fix(b_fmt),
                      psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_sub ***
  function psi_fix_sub(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     b_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_sub(a, psi_fix2_cl_fix(a_fmt),
                      b, psi_fix2_cl_fix(b_fmt),
                      psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_mult ***
  function psi_fix_mult(a    : std_logic_vector;
                      a_fmt : psi_fix_fmt_t;
                      b    : std_logic_vector;
                      b_fmt : psi_fix_fmt_t;
                      r_fmt : psi_fix_fmt_t;
                      rnd  : psi_fix_rnd_t := psi_fix_trunc;
                      sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_mult(a, psi_fix2_cl_fix(a_fmt),
                       b, psi_fix2_cl_fix(b_fmt),
                       psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_abs ***
  function psi_fix_abs(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_abs(a, psi_fix2_cl_fix(a_fmt), psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_neg ***
  function psi_fix_neg(a    : std_logic_vector;
                     a_fmt : psi_fix_fmt_t;
                     r_fmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := psi_fix_trunc;
                     sat  : psi_fix_sat_t := psi_fix_wrap)
  return std_logic_vector is
  begin
    return cl_fix_neg(a, psi_fix2_cl_fix(a_fmt), '1', psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd), psi_fix2_cl_fix(sat));
  end function;

  -- *** psi_fix_shift_left ***
  -- PsiFix specific implementation since cl_fix implementation is not synthesizable for dynamic shifts when using Xilinx Vivado tools
  function psi_fix_shift_left(a        : std_logic_vector;
                           a_fmt     : psi_fix_fmt_t;
                           shift    : integer;
                           maxShift : integer;
                           r_fmt     : psi_fix_fmt_t;
                           rnd      : psi_fix_rnd_t := psi_fix_trunc;
                           sat      : psi_fix_sat_t := psi_fix_wrap;
                           dynamic  : boolean     := False)
  return std_logic_vector is
    constant FullFmt_c : psi_fix_fmt_t := (max(a_fmt.S, r_fmt.S), max(a_fmt.I + maxShift, r_fmt.I), max(a_fmt.F, r_fmt.F));
    variable FullA_v   : std_logic_vector(psi_fix_size(FullFmt_c) - 1 downto 0);
    variable FullOut_v : std_logic_vector(FullA_v'range);
  begin
    assert shift >= 0 report "psi_fix_shift_left: Shift must be >= 0" severity error;
    assert shift <= maxShift report "psi_fix_shift_left: Shift must be <= maxShift" severity error;
    FullA_v := psi_fix_resize(a, a_fmt, FullFmt_c);
    if not dynamic then
      FullOut_v := shift_left(FullA_v, shift);
    else
      for i in 0 to maxShift loop
        if i = shift then
          FullOut_v := shift_left(FullA_v, i);
        end if;
      end loop;
    end if;
    return psi_fix_resize(FullOut_v, FullFmt_c, r_fmt, rnd, sat);
  end function;

  -- *** psi_fix_shift_right ***
  -- PsiFix specific implementation since cl_fix implementation is not synthesizable for dynamic shifts when using Xilinx Vivado tools
  function psi_fix_shift_right(a        : std_logic_vector;
                            a_fmt     : psi_fix_fmt_t;
                            shift    : integer;
                            maxShift : integer;
                            r_fmt     : psi_fix_fmt_t;
                            rnd      : psi_fix_rnd_t := psi_fix_trunc;
                            sat      : psi_fix_sat_t := psi_fix_wrap;
                            dynamic  : boolean     := False)
  return std_logic_vector is
    constant FullFmt_c : psi_fix_fmt_t := (max(a_fmt.S, r_fmt.S), max(a_fmt.I, r_fmt.I), max(a_fmt.F + maxShift, r_fmt.F + 1)); -- Additional bit for rounding
    variable FullA_v   : std_logic_vector(psi_fix_size(FullFmt_c) - 1 downto 0);
    variable FullOut_v : std_logic_vector(FullA_v'range);
  begin
    assert shift >= 0 report "psi_fix_shift_right: Shift must be >= 0" severity error;
    assert shift <= maxShift report "psi_fix_shift_right: Shift must be <= maxShift" severity error;
    FullA_v := psi_fix_resize(a, a_fmt, FullFmt_c);
    if not dynamic then
      if a_fmt.S = 1 then
        FullOut_v := shift_right(FullA_v, shift, FullA_v(FullA_v'left));
      else
        FullOut_v := shift_right(FullA_v, shift, '0');
      end if;
    else
      for i in 0 to maxShift loop       -- make a loop to ensure the shift is a constant (required by the tools)
        if i = shift then
          if a_fmt.S = 1 then
            FullOut_v := shift_right(FullA_v, i, FullA_v(FullA_v'left));
          else
            FullOut_v := shift_right(FullA_v, i, '0');
          end if;
        end if;
      end loop;
    end if;
    return psi_fix_resize(FullOut_v, FullFmt_c, r_fmt, rnd, sat);
  end function;

  -- *** psi_fix_upper_bound_stdlv ***
  function psi_fix_upper_bound_stdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_max_value(psi_fix2_cl_fix(fmt));
  end function;

  -- *** psi_fix_lower_bound_stdlv ***
  function psi_fix_lower_bound_stdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_min_value(psi_fix2_cl_fix(fmt));
  end function;

  -- *** psi_fix_upper_bound_Real ***
  function psi_fix_upper_bound_Real(fmt : psi_fix_fmt_t)
  return real is
  begin
    return cl_fix_max_real(psi_fix2_cl_fix(fmt));
  end function;

  -- *** psi_fix_lower_bound_Real ***
  function psi_fix_lower_bound_Real(fmt : psi_fix_fmt_t)
  return real is
  begin
    return cl_fix_min_real(psi_fix2_cl_fix(fmt));
  end function;

  -- *** psi_fix_in_range ***
  function psi_fix_in_range(a    : std_logic_vector;
                         a_fmt : psi_fix_fmt_t;
                         r_fmt : psi_fix_fmt_t;
                         rnd  : psi_fix_rnd_t := psi_fix_trunc)
  return boolean is
  begin
    return cl_fix_in_range(a, psi_fix2_cl_fix(a_fmt), psi_fix2_cl_fix(r_fmt), psi_fix2_cl_fix(rnd));
  end function;

  -- *** psi_fix_round_from_string ***
  function psi_fix_round_from_string(s : string)
  return psi_fix_rnd_t is
  begin
    if s = "psi_fix_round" or s = "psifixround" then
      return psi_fix_round;
    elsif s = "psi_fix_trunc" or s = "psifixtrunc" then
      return psi_fix_trunc;
    end if;
    report "psi_fix_round_from_string: Illegal value - " & s severity error;
    return psi_fix_trunc;
  end function;

  -- *** psi_fix_sat_from_string ***
  function psi_fix_sat_from_string(s : string)
  return psi_fix_sat_t is
  begin
    if s = "psi_fix_sat" or s = "psifixsat" then
      return psi_fix_sat;
    elsif s = "psi_fix_wrap" or s = "psifixwrap" then
      return psi_fix_wrap;
    end if;
    report "psi_fix_sat_from_string: Illegal value - " & s severity error;
    return psi_fix_wrap;
  end function;

  -- *** psi_fix_compare ***
  -- Allowed comparisons: "a=b", "a<b", "a>b", "a<=b", "a>=b", "a!=b"
  function psi_fix_compare(comparison : string;
                         a          : std_logic_vector;
                         a_fmt       : psi_fix_fmt_t;
                         b          : std_logic_vector;
                         b_fmt       : psi_fix_fmt_t) return boolean is
  begin
    return cl_fix_compare(comparison, a, psi_fix2_cl_fix(a_fmt), b, psi_fix2_cl_fix(b_fmt));
  end function;

  -- *** psi_fix_fmt_from_string ***
  function psi_fix_fmt_from_string(str : string) return psi_fix_fmt_t is
    variable Format_v         : psi_fix_fmt_t;
    variable OpenBraceIdx_v   : integer := -1;
    variable FirstCommaIdx_v  : integer := -1;
    variable SecondCommaIdx_v : integer := -1;
    variable CloseBraceIdx_v  : integer := -1;
  begin
    -- Parse Format
    for i in str'low to str'high loop
      if (OpenBraceIdx_v = -1) and (str(i) = '(') then
        OpenBraceIdx_v := i;
      elsif (FirstCommaIdx_v = -1) and (str(i) = ',') then
        FirstCommaIdx_v := i;
      elsif (SecondCommaIdx_v = -1) and (str(i) = ',') then
        SecondCommaIdx_v := i;
      elsif (CloseBraceIdx_v = -1) and (str(i) = ')') then
        CloseBraceIdx_v := i;
      end if;
    end loop;
    assert OpenBraceIdx_v >= 0 report "psi_fix_fmt_from_string: No opening brace found" severity error;
    assert FirstCommaIdx_v >= 0 report "psi_fix_fmt_from_string: First comma not found" severity error;
    assert SecondCommaIdx_v >= 0 report "psi_fix_fmt_from_string: Second comman not found" severity error;
    assert CloseBraceIdx_v >= 0 report "psi_fix_fmt_from_string: No closing brace found" severity error;
    Format_v.S := psi_fix_str_to_int(str(OpenBraceIdx_v + 1 to FirstCommaIdx_v - 1));
    Format_v.I := psi_fix_str_to_int(str(FirstCommaIdx_v + 1 to SecondCommaIdx_v - 1));
    Format_v.F := psi_fix_str_to_int(str(SecondCommaIdx_v + 1 to CloseBraceIdx_v - 1));
    assert (Format_v.S = 0) or (Format_v.S = 1) report "psi_fix_fmt_from_string: Sign must be 1 or 0" severity error;
    return Format_v;
  end function;

  -- *** psi_fix_fmt_to_string ***
  function psi_fix_fmt_to_string(a_fmt : psi_fix_fmt_t) return string is
  begin
    return "(" & integer'image(a_fmt.S) & ", " & integer'image(a_fmt.I) & ", " & integer'image(a_fmt.F) & ")";
  end function;

end psi_fix_pkg;

