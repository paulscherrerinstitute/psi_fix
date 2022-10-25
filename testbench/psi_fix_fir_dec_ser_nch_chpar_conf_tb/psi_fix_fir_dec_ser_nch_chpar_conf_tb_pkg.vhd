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
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant Channels_c : integer     := 2;
  constant InFmt_c    : psi_fix_fmt_t := (1, 0, 16);
  constant CoefFmt_c  : psi_fix_fmt_t := (1, 0, 15);
  constant OutFmt_c   : psi_fix_fmt_t := (1, 0, 17);
  constant MaxRatio_c : integer     := 8;
  constant MaxTaps_c  : integer     := 16;

  -------------------------------------------------------------------------
  -- Types
  -------------------------------------------------------------------------	
  type InData_t is array (0 to Channels_c - 1) of std_logic_vector(PsiFixSize(InFmt_c) - 1 downto 0);
  type OutData_t is array (0 to Channels_c - 1) of std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
  type RealArray_t is array (natural range <>) of real;
  type IntArray_t is array (natural range <>) of integer;

  type In_t is record
    Data : InData_t;
    Vld  : std_logic;
  end record;

  type Out_t is record
    Data : OutData_t;
    Vld  : std_logic;
  end record;

  type Config_t is record
    Ratio : std_logic_vector(log2ceil(MaxRatio_c) - 1 downto 0);
    Taps  : std_logic_vector(log2ceil(MaxTaps_c) - 1 downto 0);
  end record;

  type CoefIn_t is record
    Wr   : std_logic;
    Addr : std_logic_vector(log2ceil(MaxTaps_c) - 1 downto 0);
    Data : std_logic_vector(PsiFixSize(CoefFmt_c) - 1 downto 0);
  end record;

  -------------------------------------------------------------------------
  -- Procedures
  -------------------------------------------------------------------------	
  procedure WriteCoef(Idx        : in natural;
                      Coef       : in real;
                      signal Wif : out CoefIn_t;
                      signal Clk : in std_logic);

  procedure WriteCoefInt(Idx        : in natural;
                         Coef       : in integer;
                         signal Wif : out CoefIn_t;
                         signal Clk : in std_logic);

  procedure CheckCoef(Idx           : in natural;
                      Coef          : in real;
                      signal RdCoef : in std_logic_vector;
                      signal Wif    : out CoefIn_t;
                      signal Clk    : in std_logic);

  procedure CheckOut(Expected      : in RealArray_t(0 to Channels_c-1);
                     signal OutSig : in Out_t;
                     signal Clk    : in std_logic);

  procedure CheckOutInt(Expected      : in IntArray_t(0 to Channels_c-1);
                        signal OutSig : in Out_t;
                        signal Clk    : in std_logic;
                        Sample        : in integer);

end psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg;

package body psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg is

  procedure WriteCoef(Idx        : in natural;
                      Coef       : in real;
                      signal Wif : out CoefIn_t;
                      signal Clk : in std_logic) is
  begin
    wait until rising_edge(Clk);
    Wif.Wr   <= '1';
    Wif.Data <= PsiFixFromReal(Coef, CoefFmt_c);
    Wif.Addr <= std_logic_vector(to_unsigned(Idx, Wif.Addr'length));
    wait until rising_edge(Clk);
    Wif.Wr   <= '0';
  end procedure;

  procedure WriteCoefInt(Idx        : in natural;
                         Coef       : in integer;
                         signal Wif : out CoefIn_t;
                         signal Clk : in std_logic) is
  begin
    wait until rising_edge(Clk);
    Wif.Wr   <= '1';
    Wif.Data <= std_logic_vector(to_signed(Coef, Wif.Data'length));
    Wif.Addr <= std_logic_vector(to_unsigned(Idx, Wif.Addr'length));
    wait until rising_edge(Clk);
    Wif.Wr   <= '0';
  end procedure;

  procedure CheckCoef(Idx           : in natural;
                      Coef          : in real;
                      signal RdCoef : in std_logic_vector;
                      signal Wif    : out CoefIn_t;
                      signal Clk    : in std_logic) is
  begin
    wait until rising_edge(Clk);
    Wif.Addr <= std_logic_vector(to_unsigned(Idx, Wif.Addr'length));
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    assert PsiFixFromReal(Coef, CoefFmt_c) = RdCoef report "###ERROR###: read wrong coefficient" severity error;
  end procedure;

  procedure CheckOut(Expected      : in RealArray_t(0 to Channels_c-1);
                     signal OutSig : in Out_t;
                     signal Clk    : in std_logic) is
    variable ExpectedStdlv_v : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
  begin
    wait until rising_edge(Clk) and OutSig.Vld = '1';
    for i in 0 to Channels_c - 1 loop
      ExpectedStdlv_v := PsiFixFromReal(Expected(i), OutFmt_c);
      assert ExpectedStdlv_v = OutSig.Data(i)
      report "###ERROR###: received wrong output on channel " & integer'image(i) & 
						", expected " & integer'image(to_integer(signed(ExpectedStdlv_v))) &
						", received " & integer'image(to_integer(signed(OutSig.Data(i))))
      severity error;
    end loop;
  end procedure;

  procedure CheckOutInt(Expected      : in IntArray_t(0 to Channels_c-1);
                        signal OutSig : in Out_t;
                        signal Clk    : in std_logic;
                        Sample        : in integer) is
    variable ExpectedStdlv_v : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
  begin
    wait until rising_edge(Clk) and OutSig.Vld = '1';
    for i in 0 to Channels_c - 1 loop
      ExpectedStdlv_v := PsiFixFromBitsAsInt(Expected(i), OutFmt_c);
      assert ExpectedStdlv_v = OutSig.Data(i)
      report "###ERROR###: received wrong output on channel " & integer'image(i) & 
						" Sample: " & integer'image(Sample) & 
						", expected " & integer'image(to_integer(signed(ExpectedStdlv_v))) &
						", received " & integer'image(to_integer(signed(OutSig.Data(i))))
      severity error;
    end loop;
  end procedure;

end psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg;

