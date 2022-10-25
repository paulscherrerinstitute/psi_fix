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
    S : natural range 0 to 1;           -- Sign bit
    I : integer;                        -- Integer bits
    F : integer;                        -- Fractional bits
  end record;

  type PsiFixFmtArray_t is array (natural range <>) of psi_fix_fmt_t;

  type psi_fix_rnd_t is (PsiFixRound, PsiFixTrunc);

  type psi_fix_sat_t is (PsiFixWrap, PsiFixSat);

  --------------------------------------------------------------------------
  -- Helpers
  --------------------------------------------------------------------------		
  function PsiFixChooseFmt(sel  : boolean;
                           fmtA : psi_fix_fmt_t;
                           fmtB : psi_fix_fmt_t)
  return psi_fix_fmt_t;                   -- fmtA if true, otherwise fmtB

  --------------------------------------------------------------------------
  -- Conversions between PSI and Enclustra Definitions
  --------------------------------------------------------------------------	
  function PsiFix2ClFix(rnd : psi_fix_rnd_t)
  return FixRound_t;

  function PsiFix2ClFix(sat : psi_fix_sat_t)
  return FixSaturate_t;

  function PsiFix2ClFix(fmt : psi_fix_fmt_t)
  return FixFormat_t;

  function PsiFix2ClFix(fmts : PsiFixFmtArray_t)
  return FixFormatArray_t;

  function ClFix2PsiFix(rnd : FixRound_t)
  return psi_fix_rnd_t;

  function ClFix2PsiFix(sat : FixSaturate_t)
  return psi_fix_sat_t;

  function ClFix2PsiFix(fmt : FixFormat_t)
  return psi_fix_fmt_t;

  function ClFix2PsiFix(fmts : FixFormatArray_t)
  return PsiFixFmtArray_t;

  --------------------------------------------------------------------------
  -- Bittrue available in Python
  --------------------------------------------------------------------------	
  function PsiFixSize(fmt : psi_fix_fmt_t)
  return integer;

  function PsiFixFromReal(a    : real;
                          rFmt : psi_fix_fmt_t)
  return std_logic_vector;

  function PsiFixFromBitsAsInt(a    : integer;
                               aFmt : psi_fix_fmt_t)
  return std_logic_vector;

  function PsiFixGetBitsAsInt(a    : std_logic_vector;
                              aFmt : psi_fix_fmt_t)
  return integer;

  function PsiFixResize(a    : std_logic_vector;
                        aFmt : psi_fix_fmt_t;
                        rFmt : psi_fix_fmt_t;
                        rnd  : psi_fix_rnd_t := PsiFixTrunc;
                        sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixAdd(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     bFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixSub(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     bFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixMult(a    : std_logic_vector;
                      aFmt : psi_fix_fmt_t;
                      b    : std_logic_vector;
                      bFmt : psi_fix_fmt_t;
                      rFmt : psi_fix_fmt_t;
                      rnd  : psi_fix_rnd_t := PsiFixTrunc;
                      sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixAbs(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixNeg(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector;

  function PsiFixShiftLeft(a        : std_logic_vector;
                           aFmt     : psi_fix_fmt_t;
                           shift    : integer;
                           maxShift : integer;
                           rFmt     : psi_fix_fmt_t;
                           rnd      : psi_fix_rnd_t := PsiFixTrunc;
                           sat      : psi_fix_sat_t := PsiFixWrap;
                           dynamic  : boolean     := False)
  return std_logic_vector;

  function PsiFixShiftRight(a        : std_logic_vector;
                            aFmt     : psi_fix_fmt_t;
                            shift    : integer;
                            maxShift : integer;
                            rFmt     : psi_fix_fmt_t;
                            rnd      : psi_fix_rnd_t := PsiFixTrunc;
                            sat      : psi_fix_sat_t := PsiFixWrap;
                            dynamic  : boolean     := False)
  return std_logic_vector;

  function PsiFixUpperBoundStdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function PsiFixLowerBoundStdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector;

  function PsiFixUpperBoundReal(fmt : psi_fix_fmt_t)
  return real;

  function PsiFixLowerBoundReal(fmt : psi_fix_fmt_t)
  return real;

  function PsiFixInRange(a    : std_logic_vector;
                         aFmt : psi_fix_fmt_t;
                         rFmt : psi_fix_fmt_t;
                         rnd  : psi_fix_rnd_t := PsiFixTrunc)
  return boolean;

  -- Allowed comparisons: "a=b", "a<b", "a>b", "a<=b", "a>=b",  "a!=b"
  function PsiFixCompare(comparison : string;
                         a          : std_logic_vector;
                         aFmt       : psi_fix_fmt_t;
                         b          : std_logic_vector;
                         bFmt       : psi_fix_fmt_t) return boolean;

  --------------------------------------------------------------------------
  -- VHDL Only
  --------------------------------------------------------------------------		
  function PsiFixToReal(a    : std_logic_vector;
                        aFmt : psi_fix_fmt_t)
  return real;

  function PsiFixRoundFromString(s : string)
  return psi_fix_rnd_t;

  function PsiFixSatFromString(s : string)
  return psi_fix_sat_t;

  function PsiFixFmtFromString(str : string) return psi_fix_fmt_t;

  function PsiFixFmtToString(aFmt : psi_fix_fmt_t) return string;

end psi_fix_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_fix_pkg is

  --------------------------------------------------------------------------
  -- Helpers
  --------------------------------------------------------------------------
  function PsiFixChooseFmt(sel  : boolean;
                           fmtA : psi_fix_fmt_t;
                           fmtB : psi_fix_fmt_t)
  return psi_fix_fmt_t is
  begin
    if sel then
      return fmtA;
    else
      return fmtB;
    end if;
  end function;

  function PsiFixStrToInt(str : string) return integer is
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
  function PsiFix2ClFix(rnd : psi_fix_rnd_t)
  return FixRound_t is
  begin
    case rnd is
      when PsiFixRound => return NonSymPos_s;
      when PsiFixTrunc => return Trunc_s;
      when others => report "psi_fix_pkg: Unsupported Rounding Mode" severity error;
        return Trunc_s;
    end case;
  end function;

  function PsiFix2ClFix(sat : psi_fix_sat_t)
  return FixSaturate_t is
  begin
    case sat is
      when PsiFixSat  => return Sat_s;
      when PsiFixWrap => return None_s;
      when others => report "psi_fix_pkg: Unsupported Saturation Mode" severity error;
        return None_s;
    end case;
  end function;

  function PsiFix2ClFix(fmt : psi_fix_fmt_t)
  return FixFormat_t is
  begin
    return ((fmt.S = 1), fmt.I, fmt.F);
  end function;

  function PsiFix2ClFix(fmts : PsiFixFmtArray_t)
  return FixFormatArray_t is
    variable Fmts_v : FixFormatArray_t(fmts'range);
  begin
    for i in fmts'range loop
      Fmts_v(i) := PsiFix2ClFix(fmts(i));
    end loop;
    return Fmts_v;
  end function;

  function ClFix2PsiFix(rnd : FixRound_t)
  return psi_fix_rnd_t is
  begin
    case rnd is
      when NonSymPos_s => return PsiFixRound;
      when Trunc_s     => return PsiFixTrunc;
      when others => report "psi_fix_pkg: Unsupported Rounding Mode (only Round/Trunc are supported)" severity error;
        return PsiFixTrunc;
    end case;
  end function;

  function ClFix2PsiFix(sat : FixSaturate_t)
  return psi_fix_sat_t is
  begin
    case sat is
      when Sat_s  => return PsiFixSat;
      when None_s => return PsiFixWrap;
      when others => report "psi_fix_pkg: Unsupported Saturation Mode (only Sat/Wrap are supported)" severity error;
        return PsiFixWrap;
    end case;
  end function;

  function ClFix2PsiFix(fmt : FixFormat_t)
  return psi_fix_fmt_t is
  begin
    return (choose(fmt.Signed, 1, 0), fmt.Intbits, fmt.FracBits);
  end function;

  function ClFix2PsiFix(fmts : FixFormatArray_t)
  return PsiFixFmtArray_t is
    variable Fmts_v : PsiFixFmtArray_t(fmts'range);
  begin
    for i in fmts'range loop
      Fmts_v(i) := ClFix2PsiFix(fmts(i));
    end loop;
    return Fmts_v;
  end function;

  --------------------------------------------------------------------------
  -- Psi Fix Functionality
  --------------------------------------------------------------------------
  -- *** PsiFixSize ***
  function PsiFixSize(fmt : psi_fix_fmt_t)
  return integer is
  begin
    return cl_fix_width(PsiFix2ClFix(fmt));
  end function;

  -- *** PsiFixFromReal ***
  function PsiFixFromReal(a    : real;
                          rFmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    -- assertions
    assert (rFmt.S = 1) or (a >= 0.0) report "PsiFixFromReal: Unsigned format but negative number" severity error;
    -- implementation
    return cl_fix_from_real(a, PsiFix2ClFix(rFmt));
  end function;

  -- *** PsiFixToReal ***
  function PsiFixToReal(a    : std_logic_vector;
                        aFmt : psi_fix_fmt_t)
  return real is

  begin
    return cl_fix_to_real(a, PsiFix2ClFix(aFmt));
  end function;

  -- *** PsiFixFromBitsAsInt ***
  function PsiFixFromBitsAsInt(a    : integer;
                               aFmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_from_bits_as_int(a, PsiFix2ClFix(aFmt));
  end function;

  -- *** PsiFixGetBitsAsInt ***
  function PsiFixGetBitsAsInt(a    : std_logic_vector;
                              aFmt : psi_fix_fmt_t)
  return integer is
  begin
    return cl_fix_get_bits_as_int(a, PsiFix2ClFix(aFmt));
  end function;

  -- *** PsiFixResize ***
  function PsiFixResize(a    : std_logic_vector;
                        aFmt : psi_fix_fmt_t;
                        rFmt : psi_fix_fmt_t;
                        rnd  : psi_fix_rnd_t := PsiFixTrunc;
                        sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_resize(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixAdd ***
  function PsiFixAdd(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     bFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_add(a, PsiFix2ClFix(aFmt),
                      b, PsiFix2ClFix(bFmt),
                      PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixSub ***
  function PsiFixSub(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     b    : std_logic_vector;
                     bFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_sub(a, PsiFix2ClFix(aFmt),
                      b, PsiFix2ClFix(bFmt),
                      PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixMult ***
  function PsiFixMult(a    : std_logic_vector;
                      aFmt : psi_fix_fmt_t;
                      b    : std_logic_vector;
                      bFmt : psi_fix_fmt_t;
                      rFmt : psi_fix_fmt_t;
                      rnd  : psi_fix_rnd_t := PsiFixTrunc;
                      sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_mult(a, PsiFix2ClFix(aFmt),
                       b, PsiFix2ClFix(bFmt),
                       PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixAbs ***
  function PsiFixAbs(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_abs(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixNeg ***
  function PsiFixNeg(a    : std_logic_vector;
                     aFmt : psi_fix_fmt_t;
                     rFmt : psi_fix_fmt_t;
                     rnd  : psi_fix_rnd_t := PsiFixTrunc;
                     sat  : psi_fix_sat_t := PsiFixWrap)
  return std_logic_vector is
  begin
    return cl_fix_neg(a, PsiFix2ClFix(aFmt), '1', PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat));
  end function;

  -- *** PsiFixShiftLeft ***
  -- PsiFix specific implementation since cl_fix implementation is not synthesizable for dynamic shifts when using Xilinx Vivado tools
  function PsiFixShiftLeft(a        : std_logic_vector;
                           aFmt     : psi_fix_fmt_t;
                           shift    : integer;
                           maxShift : integer;
                           rFmt     : psi_fix_fmt_t;
                           rnd      : psi_fix_rnd_t := PsiFixTrunc;
                           sat      : psi_fix_sat_t := PsiFixWrap;
                           dynamic  : boolean     := False)
  return std_logic_vector is
    constant FullFmt_c : psi_fix_fmt_t := (max(aFmt.S, rFmt.S), max(aFmt.I + maxShift, rFmt.I), max(aFmt.F, rFmt.F));
    variable FullA_v   : std_logic_vector(PsiFixsize(FullFmt_c) - 1 downto 0);
    variable FullOut_v : std_logic_vector(FullA_v'range);
  begin
    assert shift >= 0 report "PsiFixShiftLeft: Shift must be >= 0" severity error;
    assert shift <= maxShift report "PsiFixShiftLeft: Shift must be <= maxShift" severity error;
    FullA_v := PsiFixResize(a, aFmt, FullFmt_c);
    if not dynamic then
      FullOut_v := ShiftLeft(FullA_v, shift);
    else
      for i in 0 to maxShift loop
        if i = shift then
          FullOut_v := ShiftLeft(FullA_v, i);
        end if;
      end loop;
    end if;
    return PsiFixResize(FullOut_v, FullFmt_c, rFmt, rnd, sat);
  end function;

  -- *** PsiFixShiftRight ***
  -- PsiFix specific implementation since cl_fix implementation is not synthesizable for dynamic shifts when using Xilinx Vivado tools
  function PsiFixShiftRight(a        : std_logic_vector;
                            aFmt     : psi_fix_fmt_t;
                            shift    : integer;
                            maxShift : integer;
                            rFmt     : psi_fix_fmt_t;
                            rnd      : psi_fix_rnd_t := PsiFixTrunc;
                            sat      : psi_fix_sat_t := PsiFixWrap;
                            dynamic  : boolean     := False)
  return std_logic_vector is
    constant FullFmt_c : psi_fix_fmt_t := (max(aFmt.S, rFmt.S), max(aFmt.I, rFmt.I), max(aFmt.F + maxShift, rFmt.F + 1)); -- Additional bit for rounding
    variable FullA_v   : std_logic_vector(PsiFixsize(FullFmt_c) - 1 downto 0);
    variable FullOut_v : std_logic_vector(FullA_v'range);
  begin
    assert shift >= 0 report "PsiFixShiftRight: Shift must be >= 0" severity error;
    assert shift <= maxShift report "PsiFixShiftRight: Shift must be <= maxShift" severity error;
    FullA_v := PsiFixResize(a, aFmt, FullFmt_c);
    if not dynamic then
      if aFmt.S = 1 then
        FullOut_v := ShiftRight(FullA_v, shift, FullA_v(FullA_v'left));
      else
        FullOut_v := ShiftRight(FullA_v, shift, '0');
      end if;
    else
      for i in 0 to maxShift loop       -- make a loop to ensure the shift is a constant (required by the tools)
        if i = shift then
          if aFmt.S = 1 then
            FullOut_v := ShiftRight(FullA_v, i, FullA_v(FullA_v'left));
          else
            FullOut_v := ShiftRight(FullA_v, i, '0');
          end if;
        end if;
      end loop;
    end if;
    return PsiFixResize(FullOut_v, FullFmt_c, rFmt, rnd, sat);
  end function;

  -- *** PsiFixUpperBoundStdlv ***
  function PsiFixUpperBoundStdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_max_value(PsiFix2ClFix(fmt));
  end function;

  -- *** PsiFixLowerBoundStdlv ***	
  function PsiFixLowerBoundStdlv(fmt : psi_fix_fmt_t)
  return std_logic_vector is
  begin
    return cl_fix_min_value(PsiFix2ClFix(fmt));
  end function;

  -- *** PsiFixUpperBoundReal ***
  function PsiFixUpperBoundReal(fmt : psi_fix_fmt_t)
  return real is
  begin
    return cl_fix_max_real(PsiFix2ClFix(fmt));
  end function;

  -- *** PsiFixLowerBoundReal ***
  function PsiFixLowerBoundReal(fmt : psi_fix_fmt_t)
  return real is
  begin
    return cl_fix_min_real(PsiFix2ClFix(fmt));
  end function;

  -- *** PsiFixInRange ***
  function PsiFixInRange(a    : std_logic_vector;
                         aFmt : psi_fix_fmt_t;
                         rFmt : psi_fix_fmt_t;
                         rnd  : psi_fix_rnd_t := PsiFixTrunc)
  return boolean is
  begin
    return cl_fix_in_range(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd));
  end function;

  -- *** PsiFixRoundFromString ***
  function PsiFixRoundFromString(s : string)
  return psi_fix_rnd_t is
  begin
    if s = "PsiFixRound" or s = "psifixround" then
      return PsiFixRound;
    elsif s = "PsiFixTrunc" or s = "psifixtrunc" then
      return PsiFixTrunc;
    end if;
    report "PsiFixRoundFromString: Illegal value - " & s severity error;
    return PsiFixTrunc;
  end function;

  -- *** PsiFixSatFromString ***
  function PsiFixSatFromString(s : string)
  return psi_fix_sat_t is
  begin
    if s = "PsiFixSat" or s = "psifixsat" then
      return PsiFixSat;
    elsif s = "PsiFixWrap" or s = "psifixwrap" then
      return PsiFixWrap;
    end if;
    report "PsiFixSatFromString: Illegal value - " & s severity error;
    return PsiFixWrap;
  end function;

  -- *** PsiFixCompare ***
  -- Allowed comparisons: "a=b", "a<b", "a>b", "a<=b", "a>=b", "a!=b"
  function PsiFixCompare(comparison : string;
                         a          : std_logic_vector;
                         aFmt       : psi_fix_fmt_t;
                         b          : std_logic_vector;
                         bFmt       : psi_fix_fmt_t) return boolean is
  begin
    return cl_fix_compare(comparison, a, PsiFix2ClFix(aFmt), b, PsiFix2ClFix(bFmt));
  end function;

  -- *** PsiFixFmtFromString ***
  function PsiFixFmtFromString(str : string) return psi_fix_fmt_t is
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
    assert OpenBraceIdx_v >= 0 report "PsiFixFmtFromString: No opening brace found" severity error;
    assert FirstCommaIdx_v >= 0 report "PsiFixFmtFromString: First comma not found" severity error;
    assert SecondCommaIdx_v >= 0 report "PsiFixFmtFromString: Second comman not found" severity error;
    assert CloseBraceIdx_v >= 0 report "PsiFixFmtFromString: No closing brace found" severity error;
    Format_v.S := PsiFixStrToInt(str(OpenBraceIdx_v + 1 to FirstCommaIdx_v - 1));
    Format_v.I := PsiFixStrToInt(str(FirstCommaIdx_v + 1 to SecondCommaIdx_v - 1));
    Format_v.F := PsiFixStrToInt(str(SecondCommaIdx_v + 1 to CloseBraceIdx_v - 1));
    assert (Format_v.S = 0) or (Format_v.S = 1) report "PsiFixFmtFromString: Sign must be 1 or 0" severity error;
    return Format_v;
  end function;

  -- *** PsiFixFmtToString ***
  function PsiFixFmtToString(aFmt : psi_fix_fmt_t) return string is
  begin
    return "(" & integer'image(aFmt.S) & ", " & integer'image(aFmt.I) & ", " & integer'image(aFmt.F) & ")";
  end function;

end psi_fix_pkg;

