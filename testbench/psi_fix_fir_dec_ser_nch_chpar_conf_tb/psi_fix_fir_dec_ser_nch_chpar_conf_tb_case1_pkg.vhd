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

library std;
use std.textio.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg is

  constant CaseName_c : string := "Bittrueness";

  constant CoefCount_c : integer := 12;
  constant Ratio_c     : integer := 3;

  procedure run(signal Config : out Config_t;
                signal CoefIf : out CoefIn_t;
                signal InSig  : out In_t;
                signal Clk    : in std_logic;
                DutyCycle     : in natural;
                FilePath      : in string);

  procedure check(signal OutSig : in Out_t;
                  signal Clk    : in std_logic;
                  FilePath      : in string);

end psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg is

  procedure run(signal Config : out Config_t;
                signal CoefIf : out CoefIn_t;
                signal InSig  : out In_t;
                signal Clk    : in std_logic;
                DutyCycle     : in natural;
                FilePath      : in string) is
    file fCoef, fInput : text;
    variable l         : line;
    variable s         : integer;

  begin
    -- Print Message
    print("Test: " & CaseName_c);

    -- Configure
    wait until rising_edge(Clk);
    Config.Ratio <= std_logic_vector(to_unsigned(Ratio_c - 1, Config.Ratio'length));
    Config.Taps  <= std_logic_vector(to_unsigned(CoefCount_c - 1, Config.Taps'length));
    wait until rising_edge(Clk);

    -- Setup coefficients and check if they can be read back
    file_open(fCoef, FilePath & "/coefs.txt");
    for i in 0 to CoefCount_c - 1 loop
      readline(fCoef, l);
      read(l, s);
      WriteCoefInt(i, s, CoefIf, Clk);
    end loop;
    file_close(fCoef);

    -- Inject Signal
    file_open(fInput, FilePath & "/input.txt");
    while not endfile(fInput) loop
      wait until rising_edge(Clk);
      readline(fInput, l);
      read(l, s);
      InSig.Data(0) <= psi_fix_from_bits_as_int(s, InFmt_c);
      read(l, s);
      InSig.Data(1) <= psi_fix_from_bits_as_int(s, InFmt_c);
      InSig.Vld     <= '1';
      wait until rising_edge(Clk);
      InSig.Vld     <= '0';
      for i in 0 to DutyCycle - 3 loop
        wait until rising_edge(Clk);
      end loop;
    end loop;
    file_close(fInput);
  end procedure;

  procedure check(signal OutSig : in Out_t;
                  signal Clk    : in std_logic;
                  FilePath      : in string) is
    file fOutput    : text;
    variable l      : line;
    variable s0, s1 : integer;
    variable idx    : integer := 0;
  begin
    file_open(fOutput, FilePath & "/output.txt");
    while not endfile(fOutput) loop
      readline(fOutput, l);
      read(l, s0);
      read(l, s1);
      CheckOutInt((s0, s1), OutSig, Clk, idx);
      idx := idx + 1;
    end loop;
    file_close(fOutput);

  end procedure;

end psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg;

