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

library work;
use work.psi_fix_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;

entity psi_fix_pkg_tb is
end entity psi_fix_pkg_tb;

architecture sim of psi_fix_pkg_tb is

  procedure CheckStdlv(expected : std_logic_vector;
                       actual   : std_logic_vector;
                       msg      : string) is
  begin
    assert expected = actual
    report "###ERROR### " & msg & " [expected: " & str(expected) & ", got: " & str(actual) & "]"
    severity error;
  end procedure;

  procedure CheckInt(expected : integer;
                     actual   : integer;
                     msg      : string) is
  begin
    assert expected = actual
    report "###ERROR### " & msg & " [expected: " & str(expected) & ", got: " & str(actual) & "]"
    severity error;
  end procedure;

  procedure CheckReal(expected : real;
                      actual   : real;
                      msg      : string) is
  begin
    assert expected = actual
    report "###ERROR### " & msg & " [expected: " & real'image(expected) & ", got: " & real'image(actual) & "]"
    severity error;
  end procedure;

  procedure CheckBoolean(expected : boolean;
                         actual   : boolean;
                         msg      : string) is
  begin
    assert expected = actual
    report "###ERROR### " & msg & " [expected: " & boolean'image(expected) & ", got: " & boolean'image(actual) & "]"
    severity error;
  end procedure;

begin

  -------------------------------------------------------------------------
  -- TB Control
  -------------------------------------------------------------------------
  p_control : process
    variable Fmt_v      : psi_fix_fmt_t;
    variable FmtArray_v : psi_fix_fmt_array_t(0 to 1);
  begin
    -- *** psi_fix_size ***
    print("*** psi_fix_size ***");
    CheckInt(3, psi_fix_size((0, 3, 0)), "psi_fix_size Wrong: Integer only, Unsigned, NoFractional Bits");
    CheckInt(4, psi_fix_size((1, 3, 0)), "psi_fix_size Wrong: Integer only, Signed, NoFractional Bits");
    CheckInt(3, psi_fix_size((0, 0, 3)), "psi_fix_size Wrong: Fractional only, Unsigned, No Integer Bits");
    CheckInt(4, psi_fix_size((1, 0, 3)), "psi_fix_size Wrong: Fractional only, Signed, No Integer Bits");
    CheckInt(7, psi_fix_size((1, 3, 3)), "psi_fix_size Wrong: Integer and Fractional Bits");
    CheckInt(2, psi_fix_size((1, -2, 3)), "psi_fix_size Wrong: Negative integer bits");
    CheckInt(2, psi_fix_size((1, 3, -2)), "psi_fix_size Wrong: Negative fractional bits");

    -- *** psi_fix_from_real ***
    print("*** psi_fix_from_real ***");
    CheckStdlv("0011",
               psi_fix_from_real(3.0, (1, 3, 0)),
               "FixFromReal Wrong: Integer only, Signed, NoFractional Bits, Positive");
    CheckStdlv("1101",
               psi_fix_from_real(-3.0, (1, 3, 0)),
               "FixFromReal Wrong: Integer only, Signed, NoFractional Bits, Negative");
    CheckStdlv("011",
               psi_fix_from_real(3.0, (0, 3, 0)),
               "FixFromReal Wrong: Integer only, Unsigned, NoFractional Bits, Positive");
    CheckStdlv("110011",
               psi_fix_from_real(-3.25, (1, 3, 2)),
               "FixFromReal Wrong: Integer and Fractional");
    CheckStdlv("11010",
               psi_fix_from_real(-3.24, (1, 3, 1)),
               "FixFromReal Wrong: Rounding");
    CheckStdlv("01",
               psi_fix_from_real(0.125, (0, -1, 3)),
               "FixFromReal Wrong: Negative Integer Bits");
    CheckStdlv("010",
               psi_fix_from_real(4.0, (1, 3, -1)),
               "FixFromReal Wrong: Negative Fractional Bits");
    CheckStdlv("011",
               psi_fix_from_real(4.0, (1, 0, 2)),
               "FixFromReal Wrong: Saturate upper limit");
    CheckStdlv("100",
               psi_fix_from_real(-4.0, (1, 0, 2)),
               "FixFromReal Wrong: Saturate lower limit");
    CheckStdlv(X"FFFF00000000",
               psi_fix_from_real(281470681743360.0, (0, 48, 0)),
               "FixFromReal: Wrong for large number");

    -- *** psi_fix_to_real ***
    print("*** psi_fix_to_real ***");
    CheckReal(3.0,
              psi_fix_to_real(psi_fix_from_real(3.0, (1, 3, 0)), (1, 3, 0)),
              "psi_fix_to_real Wrong: Integer only, Signed, NoFractional Bits, Positive");
    CheckReal(-3.0,
              psi_fix_to_real(psi_fix_from_real(-3.0, (1, 3, 0)), (1, 3, 0)),
              "psi_fix_to_real Wrong: Integer only, Signed, NoFractional Bits, Negative");
    CheckReal(3.0,
              psi_fix_to_real(psi_fix_from_real(3.0, (0, 3, 0)), (0, 3, 0)),
              "psi_fix_to_real Wrong: Integer only, Unsigned, NoFractional Bits, Positive");
    CheckReal(-3.25,
              psi_fix_to_real(psi_fix_from_real(-3.25, (1, 3, 2)), (1, 3, 2)),
              "psi_fix_to_real Wrong: Integer and Fractional");
    CheckReal(-3.0,
              psi_fix_to_real(psi_fix_from_real(-3.24, (1, 3, 1)), (1, 3, 1)),
              "psi_fix_to_real Wrong: Rounding");
    CheckReal(0.125,
              psi_fix_to_real(psi_fix_from_real(0.125, (0, -1, 3)), (0, -1, 3)),
              "psi_fix_to_real Wrong: Negative Integer Bits");
    CheckReal(4.0,
              psi_fix_to_real(psi_fix_from_real(4.0, (1, 3, -1)), (1, 3, -1)),
              "psi_fix_to_real Wrong: Negative Fractional Bits");

    -- *** psi_fix_from_bits_as_int ***
    print("*** psi_fix_from_bits_as_int ***");
    CheckStdlv("0011", psi_fix_from_bits_as_int(3, (0, 4, 0)), "psi_fix_from_bits_as_int: Unsigned Positive");
    CheckStdlv("0011", psi_fix_from_bits_as_int(3, (1, 3, 0)), "psi_fix_from_bits_as_int: Signed Positive");
    CheckStdlv("1101", psi_fix_from_bits_as_int(-3, (1, 3, 0)), "psi_fix_from_bits_as_int: Signed Negative");
    CheckStdlv("1101", psi_fix_from_bits_as_int(-3, (1, 1, 2)), "psi_fix_from_bits_as_int: Fractional"); -- binary point position is not important
    CheckStdlv("0001", psi_fix_from_bits_as_int(17, (0, 4, 0)), "psi_fix_from_bits_as_int: Wrap Unsigned");

    -- *** psi_fix_get_bits_as_int ***
    print("*** psi_fix_get_bits_as_int ***");
    CheckInt(3, psi_fix_get_bits_as_int("11", (0, 2, 0)), "psi_fix_get_bits_as_int: Unsigned Positive");
    CheckInt(3, psi_fix_get_bits_as_int("011", (1, 2, 0)), "psi_fix_get_bits_as_int: Signed Positive");
    CheckInt(-3, psi_fix_get_bits_as_int("1101", (1, 3, 0)), "psi_fix_get_bits_as_int: Signed Negative");
    CheckInt(-3, psi_fix_get_bits_as_int("1101", (1, 1, 2)), "psi_fix_get_bits_as_int: Fractional"); -- binary point position is not important

    -- *** psi_fix_resize ***
    print("*** psi_fix_resize ***");
    CheckStdlv("0101", psi_fix_resize("0101", (1, 2, 1), (1, 2, 1)),
               "psi_fix_resize: No formatchange");

    CheckStdlv("010", psi_fix_resize("0101", (1, 2, 1), (1, 2, 0), psi_fix_trunc),
               "psi_fix_resize: Remove Frac Bit 1 Trunc");
    CheckStdlv("011", psi_fix_resize("0101", (1, 2, 1), (1, 2, 0), psi_fix_round),
               "psi_fix_resize: Remove Frac Bit 1 Round");
    CheckStdlv("010", psi_fix_resize("0100", (1, 2, 1), (1, 2, 0), psi_fix_trunc),
               "psi_fix_resize: Remove Frac Bit 0 Trunc");
    CheckStdlv("010", psi_fix_resize("0100", (1, 2, 1), (1, 2, 0), psi_fix_round),
               "psi_fix_resize: Remove Frac Bit 0 Round");

    CheckStdlv("01000", psi_fix_resize("0100", (1, 2, 1), (1, 2, 2), psi_fix_round),
               "psi_fix_resize: Add Fractional Bit Signed");
    CheckStdlv("1000", psi_fix_resize("100", (0, 2, 1), (0, 2, 2), psi_fix_round),
               "psi_fix_resize: Add Fractional Bit Unsigned");

    CheckStdlv("0111", psi_fix_resize("00111", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Integer Bit, Signed, NoSat, Positive");
    CheckStdlv("1001", psi_fix_resize("11001", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_sat),
               "psi_fix_resize: Remove Integer Bit, Signed, NoSat, Negative");
    CheckStdlv("1011", psi_fix_resize("01011", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Integer Bit, Signed, Wrap, Positive");
    CheckStdlv("0011", psi_fix_resize("10011", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Integer Bit, Signed, Wrap, Negative");
    CheckStdlv("0111", psi_fix_resize("01011", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_sat),
               "psi_fix_resize: Remove Integer Bit, Signed, Sat, Positive");
    CheckStdlv("1000", psi_fix_resize("10011", (1, 3, 1), (1, 2, 1), psi_fix_trunc, psi_fix_sat),
               "psi_fix_resize: Remove Integer Bit, Signed, Sat, Negative");

    CheckStdlv("111", psi_fix_resize("0111", (0, 3, 1), (0, 2, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Integer Bit, Unsigned, NoSat, Positive");
    CheckStdlv("011", psi_fix_resize("1011", (0, 3, 1), (0, 2, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Integer Bit, Unsigned, Wrap, Positive");
    CheckStdlv("111", psi_fix_resize("1011", (0, 3, 1), (0, 2, 1), psi_fix_trunc, psi_fix_sat),
               "psi_fix_resize: Remove Integer Bit, Unsigned, Sat, Positive");

    CheckStdlv("0111", psi_fix_resize("00111", (1, 3, 1), (0, 3, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Sign Bit, Signed, NoSat, Positive");
    CheckStdlv("0011", psi_fix_resize("10011", (1, 3, 1), (0, 3, 1), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_resize: Remove Sign Bit, Signed, Wrap, Negative");
    CheckStdlv("0000", psi_fix_resize("10011", (1, 3, 1), (0, 3, 1), psi_fix_trunc, psi_fix_sat),
               "psi_fix_resize: Remove Sign Bit, Signed, Sat, Negative");

    CheckStdlv("1000", psi_fix_resize("01111", (1, 3, 1), (1, 3, 0), psi_fix_round, psi_fix_wrap),
               "psi_fix_resize: Overflow due rounding, Signed, Wrap");
    CheckStdlv("0111", psi_fix_resize("01111", (1, 3, 1), (1, 3, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_resize: Overflow due rounding, Signed, Sat");
    CheckStdlv("000", psi_fix_resize("1111", (0, 3, 1), (0, 3, 0), psi_fix_round, psi_fix_wrap),
               "psi_fix_resize: Overflow due rounding, Unsigned, Wrap");
    CheckStdlv("111", psi_fix_resize("1111", (0, 3, 1), (0, 3, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_resize: Overflow due rounding, Unsigned, Sat");

    -- error cases
    CheckStdlv("0000101000", psi_fix_resize(psi_fix_from_real(2.5, (0, 5, 4)), (0, 5, 4), (0, 6, 4)),
               "psi_fix_resize: Overflow due rounding, Unsigned, Sat");
    CheckStdlv("000010100", psi_fix_resize(psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3), (0, 5, 4)),
               "psi_fix_resize: Overflow due rounding, Unsigned, Sat");

    -- *** psi_fix_add ***
    print("*** psi_fix_add ***");
    CheckStdlv(psi_fix_from_real(-2.5 + 1.25, (1, 5, 3)),
               psi_fix_add(psi_fix_from_real(-2.5, (1, 5, 3)), (1, 5, 3),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_add: Same Fmt Signed");
    CheckStdlv(psi_fix_from_real(2.5 + 1.25, (0, 5, 3)),
               psi_fix_add(psi_fix_from_real(2.5, (0, 5, 3)), (0, 5, 3),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_add: Same Fmt Usigned");
    CheckStdlv(psi_fix_from_real(-2.5 + 1.25, (1, 5, 3)),
               psi_fix_add(psi_fix_from_real(-2.5, (1, 6, 3)), (1, 6, 3),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_add: Different Int Bits Signed");
    CheckStdlv(psi_fix_from_real(2.5 + 1.25, (0, 5, 3)),
               psi_fix_add(psi_fix_from_real(2.5, (0, 6, 3)), (0, 6, 3),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_add: Different Int Bits Usigned");
    CheckStdlv(psi_fix_from_real(-2.5 + 1.25, (1, 5, 3)),
               psi_fix_add(psi_fix_from_real(-2.5, (1, 5, 4)), (1, 5, 4),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_add: Different Frac Bits Signed");
    CheckStdlv(psi_fix_from_real(2.5 + 1.25, (0, 5, 3)),
               psi_fix_add(psi_fix_from_real(2.5, (0, 5, 4)), (0, 5, 4),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_add: Different Frac Bits Usigned");
    CheckStdlv(psi_fix_from_real(0.75 + 4.0, (0, 5, 5)),
               psi_fix_add(psi_fix_from_real(0.75, (0, 0, 4)), (0, 0, 4),
                         psi_fix_from_real(4.0, (0, 4, -1)), (0, 4, -1),
                         (0, 5, 5)),
               "psi_fix_add: Different Ranges Unsigned");
    CheckStdlv(psi_fix_from_real(5.0, (0, 5, 0)),
               psi_fix_add(psi_fix_from_real(0.75, (0, 0, 4)), (0, 0, 4),
                         psi_fix_from_real(4.0, (0, 4, -1)), (0, 4, -1),
                         (0, 5, 0), psi_fix_round),
               "psi_fix_add: Round");
    CheckStdlv(psi_fix_from_real(15.0, (0, 4, 0)),
               psi_fix_add(psi_fix_from_real(0.75, (0, 0, 4)), (0, 0, 4),
                         psi_fix_from_real(15.0, (0, 4, 0)), (0, 4, 0),
                         (0, 4, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_add: Satturate");

    -- *** psi_fix_sub ***
    print("*** psi_fix_sub ***");
    CheckStdlv(psi_fix_from_real(-2.5 - 1.25, (1, 5, 3)),
               psi_fix_sub(psi_fix_from_real(-2.5, (1, 5, 3)), (1, 5, 3),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_sub: Same Fmt Signed");
    CheckStdlv(psi_fix_from_real(2.5 - 1.25, (0, 5, 3)),
               psi_fix_sub(psi_fix_from_real(2.5, (0, 5, 3)), (0, 5, 3),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_sub: Same Fmt Usigned");
    CheckStdlv(psi_fix_from_real(-2.5 - 1.25, (1, 5, 3)),
               psi_fix_sub(psi_fix_from_real(-2.5, (1, 6, 3)), (1, 6, 3),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_sub: Different Int Bits Signed");
    CheckStdlv(psi_fix_from_real(2.5 - 1.25, (0, 5, 3)),
               psi_fix_sub(psi_fix_from_real(2.5, (0, 6, 3)), (0, 6, 3),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_sub: Different Int Bits Usigned");
    CheckStdlv(psi_fix_from_real(-2.5 - 1.25, (1, 5, 3)),
               psi_fix_sub(psi_fix_from_real(-2.5, (1, 5, 4)), (1, 5, 4),
                         psi_fix_from_real(1.25, (1, 5, 3)), (1, 5, 3),
                         (1, 5, 3)),
               "psi_fix_sub: Different Frac Bits Signed");
    CheckStdlv(psi_fix_from_real(2.5 - 1.25, (0, 5, 3)),
               psi_fix_sub(psi_fix_from_real(2.5, (0, 5, 4)), (0, 5, 4),
                         psi_fix_from_real(1.25, (0, 5, 3)), (0, 5, 3),
                         (0, 5, 3)),
               "psi_fix_sub: Different Frac Bits Usigned");
    CheckStdlv(psi_fix_from_real(4.0 - 0.75, (0, 5, 5)),
               psi_fix_sub(psi_fix_from_real(4.0, (0, 4, -1)), (0, 4, -1),
                         psi_fix_from_real(0.75, (0, 0, 4)), (0, 0, 4),
                         (0, 5, 5)),
               "psi_fix_sub: Different Ranges Unsigned");
    CheckStdlv(psi_fix_from_real(4.0, (0, 5, 0)),
               psi_fix_sub(psi_fix_from_real(4.0, (0, 4, -1)), (0, 4, -1),
                         psi_fix_from_real(0.25, (0, 0, 4)), (0, 0, 4),
                         (0, 5, 0), psi_fix_round),
               "psi_fix_sub: Round");
    CheckStdlv(psi_fix_from_real(0.0, (0, 4, 0)),
               psi_fix_sub(psi_fix_from_real(0.75, (0, 0, 4)), (0, 0, 4),
                         psi_fix_from_real(5.0, (0, 4, 0)), (0, 4, 0),
                         (0, 4, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_sub: Satturate");
    CheckStdlv(psi_fix_from_real(-16.0, (1, 4, 0)),
               psi_fix_sub(psi_fix_from_real(0.0, (1, 4, 0)), (1, 4, 0),
                         psi_fix_from_real(-16.0, (1, 4, 0)), (1, 4, 0),
                         (1, 4, 0), psi_fix_round, psi_fix_wrap),
               "psi_fix_sub: Invert most negative signed, noSat");
    CheckStdlv(psi_fix_from_real(15.0, (1, 4, 0)),
               psi_fix_sub(psi_fix_from_real(0.0, (1, 4, 0)), (1, 4, 0),
                         psi_fix_from_real(-16.0, (1, 4, 0)), (1, 4, 0),
                         (1, 4, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_sub: Invert most negative signed, Sat");
    CheckStdlv(psi_fix_from_real(0.0, (0, 4, 0)),
               psi_fix_sub(psi_fix_from_real(0.0, (0, 4, 0)), (0, 4, 0),
                         psi_fix_from_real(15.0, (0, 4, 0)), (0, 4, 0),
                         (0, 4, 0), psi_fix_round, psi_fix_sat),
               "psi_fix_sub: Invert unsigned, Sat");

    -- *** psi_fix_mult ***
    print("*** psi_fix_mult ***");
    CheckStdlv(psi_fix_from_real(2.5 * 1.25, (0, 5, 5)),
               psi_fix_mult(psi_fix_from_real(2.5, (0, 5, 1)), (0, 5, 1),
                          psi_fix_from_real(1.25, (0, 5, 2)), (0, 5, 2),
                          (0, 5, 5)),
               "psi_fix_mult: A unsigned positive, B unsigned positive");
    CheckStdlv(psi_fix_from_real(2.5 * 1.25, (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (1, 2, 1)), (1, 2, 1),
                          psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A signed positive, B signed positive");
    CheckStdlv(psi_fix_from_real(2.5 * (-1.25), (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (1, 2, 1)), (1, 2, 1),
                          psi_fix_from_real(-1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A signed positive, B signed negative");
    CheckStdlv(psi_fix_from_real((-2.5) * 1.25, (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(-2.5, (1, 2, 1)), (1, 2, 1),
                          psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A signed negative, B signed positive");
    CheckStdlv(psi_fix_from_real((-2.5) * (-1.25), (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(-2.5, (1, 2, 1)), (1, 2, 1),
                          psi_fix_from_real(-1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A signed negative, B signed negative");
    CheckStdlv(psi_fix_from_real(2.5 * 1.25, (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (0, 2, 1)), (0, 2, 1),
                          psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A unsigned positive, B signed positive");
    CheckStdlv(psi_fix_from_real(2.5 * (-1.25), (1, 3, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (0, 2, 1)), (0, 2, 1),
                          psi_fix_from_real(-1.25, (1, 1, 2)), (1, 1, 2),
                          (1, 3, 3)),
               "psi_fix_mult: A unsigned positive, B signed negative");
    CheckStdlv(psi_fix_from_real(2.5 * 1.25, (0, 3, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (0, 2, 1)), (0, 2, 1),
                          psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                          (0, 3, 3)),
               "psi_fix_mult: A unsigned positive, B signed positive, result unsigned");
    CheckStdlv(psi_fix_from_real(1.875, (0, 1, 3)),
               psi_fix_mult(psi_fix_from_real(2.5, (0, 2, 1)), (0, 2, 1),
                          psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                          (0, 1, 3), psi_fix_trunc, psi_fix_sat),
               "psi_fix_mult: A unsigned positive, B signed positive, saturate");

    -- *** psi_fix_abs ***
    print("*** psi_fix_abs ***");
    CheckStdlv(psi_fix_from_real(2.5, (0, 5, 5)),
               psi_fix_abs(psi_fix_from_real(2.5, (0, 5, 1)), (0, 5, 1),
                         (0, 5, 5)),
               "psi_fix_abs: positive stay positive");
    CheckStdlv(psi_fix_from_real(4.0, (1, 3, 3)),
               psi_fix_abs(psi_fix_from_real(-4.0, (1, 2, 2)), (1, 2, 2),
                         (1, 3, 3)),
               "psi_fix_abs: negative becomes positive");
    CheckStdlv(psi_fix_from_real(3.75, (1, 2, 2)),
               psi_fix_abs(psi_fix_from_real(-4.0, (1, 2, 2)), (1, 2, 2),
                         (1, 2, 2), psi_fix_trunc, psi_fix_sat),
               "psi_fix_abs: most negative value sat");

    -- *** psi_fix_neg ***
    print("*** psi_fix_neg ***");
    CheckStdlv(psi_fix_from_real(-2.5, (1, 5, 5)),
               psi_fix_neg(psi_fix_from_real(2.5, (1, 5, 1)), (1, 5, 1),
                         (1, 5, 5)),
               "psi_fix_neg: positive to negative (signed -> signed)");
    CheckStdlv(psi_fix_from_real(-2.5, (1, 5, 5)),
               psi_fix_neg(psi_fix_from_real(2.5, (0, 5, 1)), (0, 5, 1),
                         (1, 5, 5)),
               "psi_fix_neg: positive to negative (unsigned -> signed)");
    CheckStdlv(psi_fix_from_real(2.5, (1, 5, 5)),
               psi_fix_neg(psi_fix_from_real(-2.5, (1, 5, 1)), (1, 5, 1),
                         (1, 5, 5)),
               "psi_fix_neg: negative to positive (signed -> signed)");
    CheckStdlv(psi_fix_from_real(2.5, (0, 5, 5)),
               psi_fix_neg(psi_fix_from_real(-2.5, (1, 5, 1)), (1, 5, 1),
                         (0, 5, 5)),
               "psi_fix_neg: negative to positive (signed -> unsigned)");
    CheckStdlv(psi_fix_from_real(3.75, (1, 2, 2)),
               psi_fix_neg(psi_fix_from_real(-4.0, (1, 2, 4)), (1, 2, 4),
                         (1, 2, 2), psi_fix_trunc, psi_fix_sat),
               "psi_fix_neg: saturation (signed -> signed)");
    CheckStdlv(psi_fix_from_real(-4.0, (1, 2, 2)),
               psi_fix_neg(psi_fix_from_real(-4.0, (1, 2, 4)), (1, 2, 4),
                         (1, 2, 2), psi_fix_trunc, psi_fix_wrap),
               "psi_fix_neg: wrap (signed -> signed)");
    CheckStdlv(psi_fix_from_real(0.0, (0, 5, 5)),
               psi_fix_neg(psi_fix_from_real(2.5, (1, 5, 1)), (1, 5, 1),
                         (0, 5, 5), psi_fix_trunc, psi_fix_sat),
               "psi_fix_neg: positive to negative saturate (signed -> unsigned)");

    -- *** psi_fix_shift_left ***
    print("*** psi_fix_shift_left ***");
    CheckStdlv(psi_fix_from_real(2.5, (0, 3, 2)),
               psi_fix_shift_left(psi_fix_from_real(1.25, (0, 3, 2)), (0, 3, 2),
                               1, 10,
                               (0, 3, 2)),
               "Shift same format unsigned");
    CheckStdlv(psi_fix_from_real(2.5, (1, 3, 2)),
               psi_fix_shift_left(psi_fix_from_real(1.25, (1, 3, 2)), (1, 3, 2),
                               1, 10,
                               (1, 3, 2)),
               "Shift same format signed");
    CheckStdlv(psi_fix_from_real(2.5, (0, 3, 2)),
               psi_fix_shift_left(psi_fix_from_real(1.25, (1, 1, 2)), (1, 1, 2),
                               1, 10,
                               (0, 3, 2)),
               "Shift format change");
    CheckStdlv(psi_fix_from_real(3.75, (1, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(2.0, (1, 2, 2)), (1, 2, 2),
                               1, 10,
                               (1, 2, 2), psi_fix_trunc, psi_fix_sat),
               "saturation signed");
    CheckStdlv(psi_fix_from_real(3.75, (1, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(2.0, (0, 3, 2)), (0, 3, 2),
                               1, 10,
                               (1, 2, 2), psi_fix_trunc, psi_fix_sat),
               "saturation unsigned to signed");
    CheckStdlv(psi_fix_from_real(0.0, (0, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(-0.5, (1, 3, 2)), (1, 3, 2),
                               1, 10,
                               (0, 2, 2), psi_fix_trunc, psi_fix_sat),
               "saturation signed to unsigned");
    CheckStdlv(psi_fix_from_real(-4.0, (1, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(2.0, (1, 2, 2)), (1, 2, 2),
                               1, 10,
                               (1, 2, 2), psi_fix_trunc, psi_fix_wrap),
               "wrap signed");
    CheckStdlv(psi_fix_from_real(-4.0, (1, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(2.0, (0, 3, 2)), (0, 3, 2),
                               1, 10,
                               (1, 2, 2), psi_fix_trunc, psi_fix_wrap),
               "wrap unsigned to signed");
    CheckStdlv(psi_fix_from_real(3.0, (0, 2, 2)),
               psi_fix_shift_left(psi_fix_from_real(-0.5, (1, 3, 2)), (1, 3, 2),
                               1, 10,
                               (0, 2, 2), psi_fix_trunc, psi_fix_wrap),
               "wrap signed to unsigned");
    CheckStdlv(psi_fix_from_real(0.5, (1, 5, 5)),
               psi_fix_shift_left(psi_fix_from_real(0.5, (1, 5, 5)), (1, 5, 5),
                               0, 10,
                               (1, 5, 5), psi_fix_trunc, psi_fix_wrap),
               "shift 0");
    CheckStdlv(psi_fix_from_real(-4.0, (1, 5, 5)),
               psi_fix_shift_left(psi_fix_from_real(-0.5, (1, 5, 5)), (1, 5, 5),
                               3, 10,
                               (1, 5, 5), psi_fix_trunc, psi_fix_wrap),
               "shift 3");

    -- *** psi_fix_shift_right ***
    print("*** psi_fix_shift_right ***");
    CheckStdlv(psi_fix_from_real(1.25, (0, 3, 2)),
               psi_fix_shift_right(psi_fix_from_real(2.5, (0, 3, 2)), (0, 3, 2),
                                1, 10,
                                (0, 3, 2)),
               "Shift same format unsigned");
    CheckStdlv(psi_fix_from_real(1.25, (1, 3, 2)),
               psi_fix_shift_right(psi_fix_from_real(2.5, (1, 3, 2)), (1, 3, 2),
                                1, 10,
                                (1, 3, 2)),
               "Shift same format signed");
    CheckStdlv(psi_fix_from_real(1.25, (1, 1, 2)),
               psi_fix_shift_right(psi_fix_from_real(2.5, (0, 3, 2)), (0, 3, 2),
                                1, 10,
                                (1, 1, 2)),
               "Shift format change");
    CheckStdlv(psi_fix_from_real(0.0, (0, 2, 2)),
               psi_fix_shift_right(psi_fix_from_real(-0.5, (1, 3, 2)), (1, 3, 2),
                                1, 10,
                                (0, 2, 2), psi_fix_trunc, psi_fix_sat),
               "saturation signed to unsigned");
    CheckStdlv(psi_fix_from_real(0.5, (1, 5, 5)),
               psi_fix_shift_right(psi_fix_from_real(0.5, (1, 5, 5)), (1, 5, 5),
                                0, 10,
                                (1, 5, 5), psi_fix_trunc, psi_fix_wrap),
               "shift 0");
    CheckStdlv(psi_fix_from_real(-0.5, (1, 5, 5)),
               psi_fix_shift_right(psi_fix_from_real(-4.0, (1, 5, 5)), (1, 5, 5),
                                3, 10,
                                (1, 5, 5), psi_fix_trunc, psi_fix_wrap),
               "shift 3");

    -- *** psi_fix_upper_bound_stdlv ***
    print("*** psi_fix_upper_bound_stdlv ***");
    CheckStdlv("1111", psi_fix_upper_bound_stdlv((0, 2, 2)), "unsigned");
    CheckStdlv("0111", psi_fix_upper_bound_stdlv((1, 1, 2)), "signed");

    -- *** psi_fix_lower_bound_stdlv ***
    print("*** psi_fix_lower_bound_stdlv ***");
    CheckStdlv("0000", psi_fix_lower_bound_stdlv((0, 2, 2)), "unsigned");
    CheckStdlv("1000", psi_fix_lower_bound_stdlv((1, 1, 2)), "signed");

    -- *** psi_fix_upper_bound_Real ***
    print("*** psi_fix_upper_bound_Real ***");
    CheckReal(3.75, psi_fix_upper_bound_Real((0, 2, 2)), "unsigned");
    CheckReal(1.75, psi_fix_upper_bound_Real((1, 1, 2)), "signed");

    -- *** psi_fix_lower_bound_Real ***
    print("*** psi_fix_lower_bound_Real ***");
    CheckReal(0.0, psi_fix_lower_bound_Real((0, 2, 2)), "unsigned");
    CheckReal(-2.0, psi_fix_lower_bound_Real((1, 1, 2)), "signed");

    -- *** psi_fix_in_range ***
    print("*** psi_fix_in_range ***");
    CheckBoolean(true,
                 psi_fix_in_range(psi_fix_from_real(1.25, (1, 4, 2)), (1, 4, 2),
                               (1, 2, 4), psi_fix_trunc),
                 "In Range Normal");
    CheckBoolean(false,
                 psi_fix_in_range(psi_fix_from_real(6.25, (1, 4, 2)), (1, 4, 2),
                               (1, 2, 4), psi_fix_trunc),
                 "Out Range Normal");
    CheckBoolean(false,
                 psi_fix_in_range(psi_fix_from_real(-1.25, (1, 4, 2)), (1, 4, 2),
                               (0, 5, 2), psi_fix_trunc),
                 "signed -> unsigned OOR");
    CheckBoolean(false,
                 psi_fix_in_range(psi_fix_from_real(15.0, (0, 4, 2)), (0, 4, 2),
                               (1, 3, 2), psi_fix_trunc),
                 "unsigned -> signed OOR");
    CheckBoolean(true,
                 psi_fix_in_range(psi_fix_from_real(15.0, (0, 4, 2)), (0, 4, 2),
                               (1, 4, 2), psi_fix_trunc),
                 "unsigned -> signed OK");
    CheckBoolean(false,
                 psi_fix_in_range(psi_fix_from_real(15.5, (0, 4, 2)), (0, 4, 2),
                               (1, 4, 0), psi_fix_round),
                 "rounding OOR");
    CheckBoolean(true,
                 psi_fix_in_range(psi_fix_from_real(15.5, (0, 4, 2)), (0, 4, 2),
                               (1, 4, 1), psi_fix_round),
                 "rounding OK 1");
    CheckBoolean(true,
                 psi_fix_in_range(psi_fix_from_real(15.5, (0, 4, 2)), (0, 4, 2),
                               (0, 5, 0), psi_fix_round),
                 "rounding OK 2");

    -- *** psi_fix_compare ***
    print("*** psi_fix_compare ***");
    CheckBoolean(true,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(1.25, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a<b unsigned unsigned true");
    CheckBoolean(false,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(1.5, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a<b unsigned unsigned false");
    CheckBoolean(true,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(1.25, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a<b signed unsigned true");
    CheckBoolean(false,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(2.5, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(1.5, (1, 2, 1)), (1, 2, 1)),
                 "a<b unsigned signed false");
    CheckBoolean(true,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(-1.25, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(-1.0, (1, 2, 1)), (1, 2, 1)),
                 "a<b signed signed true");
    CheckBoolean(false,
                 psi_fix_compare("a<b",
                               psi_fix_from_real(-0.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(-1.5, (1, 2, 1)), (1, 2, 1)),
                 "a<b signed signed false");

    CheckBoolean(true,
                 psi_fix_compare("a=b",
                               psi_fix_from_real(1.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a=b signed unsigned true");
    CheckBoolean(false,
                 psi_fix_compare("a=b",
                               psi_fix_from_real(2.5, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(-1.5, (1, 2, 1)), (1, 2, 1)),
                 "a=b unsigned signed false");

    CheckBoolean(true,
                 psi_fix_compare("a>b",
                               psi_fix_from_real(2.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a>b signed unsigned true");
    CheckBoolean(false,
                 psi_fix_compare("a>b",
                               psi_fix_from_real(1.5, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(1.5, (1, 2, 1)), (1, 2, 1)),
                 "a>b unsigned signed false");

    CheckBoolean(true,
                 psi_fix_compare("a>=b",
                               psi_fix_from_real(2.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a>=b signed unsigned true 1");
    CheckBoolean(true,
                 psi_fix_compare("a>=b",
                               psi_fix_from_real(1.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a>=b signed unsigned true 2");
    CheckBoolean(false,
                 psi_fix_compare("a>=b",
                               psi_fix_from_real(1.25, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(1.5, (1, 2, 1)), (1, 2, 1)),
                 "a>=b unsigned signed false 1");

    CheckBoolean(true,
                 psi_fix_compare("a<=b",
                               psi_fix_from_real(-2.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a<=b signed unsigned true 1");
    CheckBoolean(true,
                 psi_fix_compare("a<=b",
                               psi_fix_from_real(1.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a<=b signed unsigned true 2");
    CheckBoolean(false,
                 psi_fix_compare("a<=b",
                               psi_fix_from_real(0.25, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(-1.5, (1, 2, 1)), (1, 2, 1)),
                 "a<=b unsigned signed false 1");

    CheckBoolean(false,
                 psi_fix_compare("a!=b",
                               psi_fix_from_real(1.5, (1, 4, 2)), (1, 4, 2),
                               psi_fix_from_real(1.5, (0, 2, 1)), (0, 2, 1)),
                 "a!=b signed unsigned false");
    CheckBoolean(true,
                 psi_fix_compare("a!=b",
                               psi_fix_from_real(2.5, (0, 4, 2)), (0, 4, 2),
                               psi_fix_from_real(-1.5, (1, 2, 1)), (1, 2, 1)),
                 "a!=b unsigned signed true");

    -- *** psi_fix_fmt_from_string ***
    print("*** psi_fix_fmt_from_string ***");
    Fmt_v := psi_fix_fmt_from_string("(1,0,15)");
    IntCompare(1, Fmt_v.S, "psi_fix_fmt_from_string 0.S");
    IntCompare(0, Fmt_v.I, "psi_fix_fmt_from_string 0.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 0.F");
    Fmt_v := psi_fix_fmt_from_string(" (1,0,15)");
    IntCompare(1, Fmt_v.S, "psi_fix_fmt_from_string 1.S");
    IntCompare(0, Fmt_v.I, "psi_fix_fmt_from_string 1.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 1.F");
    Fmt_v := psi_fix_fmt_from_string("(1,2,15) ");
    IntCompare(1, Fmt_v.S, "psi_fix_fmt_from_string 2.S");
    IntCompare(2, Fmt_v.I, "psi_fix_fmt_from_string 2.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 2.F");
    Fmt_v := psi_fix_fmt_from_string("(0 ,0,15)");
    IntCompare(0, Fmt_v.S, "psi_fix_fmt_from_string 3.S");
    IntCompare(0, Fmt_v.I, "psi_fix_fmt_from_string 3.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 3.F");
    Fmt_v := psi_fix_fmt_from_string("(0 ,-3, 15)");
    IntCompare(0, Fmt_v.S, "psi_fix_fmt_from_string 4.S");
    IntCompare(-3, Fmt_v.I, "psi_fix_fmt_from_string 4.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 4.F");
    Fmt_v := psi_fix_fmt_from_string("( 0 , 0, -15  )");
    IntCompare(0, Fmt_v.S, "psi_fix_fmt_from_string 5.S");
    IntCompare(0, Fmt_v.I, "psi_fix_fmt_from_string 5.I");
    IntCompare(-15, Fmt_v.F, "psi_fix_fmt_from_string 5.F");
    Fmt_v := psi_fix_fmt_from_string("(0    , 0 , 15)");
    IntCompare(0, Fmt_v.S, "psi_fix_fmt_from_string 6.S");
    IntCompare(0, Fmt_v.I, "psi_fix_fmt_from_string 6.I");
    IntCompare(15, Fmt_v.F, "psi_fix_fmt_from_string 6.F");

    -- *** psi_fix_fmt_to_string ***
    print("*** psi_fix_fmt_to_string ***");
    assert "(1, -2, 15)" = psi_fix_fmt_to_string((1, -2, 15))
    report "###ERROR###: Wrong string fmt received"
    severity error;

    -- *** cl_fix2_psi_fix (psi_fix_fmt_t) ***
    print("*** cl_fix2_psi_fix (psi_fix_fmt_t) ***");
    Fmt_v := (1, 0, 15);
    assert cl_fix2_psi_fix(psi_fix2_cl_fix(Fmt_v)) = Fmt_v
    report "###ERROR###: psi_fix_fmt_t -> FixFormat_t -> psi_fix_fmt_t failed"
    severity error;

    -- *** cl_fix2_psi_fix (psi_fix_fmt_array_t) ***
    print("*** cl_fix2_psi_fix (psi_fix_fmt_array_t) ***");
    FmtArray_v := ((0, -2, 3), (1, 0, 15));
    assert cl_fix2_psi_fix(psi_fix2_cl_fix(FmtArray_v)) = FmtArray_v
    report "###ERROR###: psi_fix_fmt_array_t -> FixFormatArray_t -> psi_fix_fmt_array_t failed"
    severity error;

    wait;
  end process;

end sim;
