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

library work;
use work.psi_tb_txt_util.all;
use work.psi_fix_pkg.all;

library std;
use std.textio.all;

entity psi_fix_bin_div_tb is
  generic(
    DataDir_g : string := "../testbench/psi_fix_bin_div_tb/Data"
  );
end entity psi_fix_bin_div_tb;

architecture sim of psi_fix_bin_div_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant NumFmt_c   : psi_fix_fmt_t := (1, 2, 5);
  constant DenomFmt_c : psi_fix_fmt_t := (1, 2, 8);
  constant OutFmt_c   : psi_fix_fmt_t := (1, 4, 10);

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockFrequency_c : real    := 100.0e6;
  constant ClockPeriod_c    : time    := (1 sec) / ClockFrequency_c;
  signal TbRunning          : boolean := True;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal Clk     : std_logic                                             := '0';
  signal Rst     : std_logic                                             := '1';
  signal InVld   : std_logic                                             := '0';
  signal InRdy   : std_logic                                             := '0';
  signal InNum   : std_logic_vector(PsiFixSize(NumFmt_c) - 1 downto 0)   := (others => '0');
  signal InDenom : std_logic_vector(PsiFixSize(DenomFmt_c) - 1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                             := '0';
  signal OutQuot : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0)   := (others => '0');

  -------------------------------------------------------------------------
  -- Procedure
  -------------------------------------------------------------------------	
  procedure CheckReal(expected  : real;
                      actual    : real;
                      tolerance : real;
                      msg       : string) is
  begin
    assert (actual < expected + tolerance) and (actual > expected - tolerance)
    report "###ERROR***: " & msg & " expected: " & real'image(expected) & ", received: " & real'image(actual)
    severity error;
  end procedure;

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_fix_bin_div
    generic map(
      NumFmt_g   => NumFmt_c,
      DenomFmt_g => DenomFmt_c,
      OutFmt_g   => OutFmt_c,
      Round_g    => PsiFixTrunc,
      Sat_g      => PsiFixSat
    )
    port map(
      -- Control Signals
      clk_i         => Clk,
      rst_i         => Rst,
      -- Input
      vld_i         => InVld,
      rdy_i         => InRdy,
      numerator_i   => InNum,
      denominator_i => InDenom,
      -- Output
      vld_o         => OutVld,
      result_o      => OutQuot
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk : process
  begin
    Clk <= '0';
    while TbRunning loop
      wait for 0.5 * ClockPeriod_c;
      Clk <= '1';
      wait for 0.5 * ClockPeriod_c;
      Clk <= '0';
    end loop;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- TB Control
  -------------------------------------------------------------------------
  p_control : process
    file fIn        : text;
    file fOut       : text;
    variable r      : line;
    variable iNum   : integer;
    variable iDenom : integer;
    variable resp   : integer;
    variable idx    : integer := 0;
  begin
    -- Reset
    Rst <= '1';
    wait for 1 us;
    Rst <= '0';
    wait for 1 us;

    -- Check initial state
    assert OutVld = '0' report "###ERROR###: Initial state of output valid is high" severity error;

    -- Check Simple Division
    wait until rising_edge(Clk);
    InNum   <= PsiFixFromReal(3.0, NumFmt_c);
    InDenom <= PsiFixFromReal(0.5, DenomFmt_c);
    InVld   <= '1';
    wait until rising_edge(Clk) and InRdy = '1';
    InVld   <= '0';
    wait until rising_edge(Clk) and OutVld = '1';
    CheckReal(6.0, PsiFixToReal(OutQuot, OutFmt_c), 0.01, "Simple Division");

    -- Check Saturation
    wait until rising_edge(Clk);
    InNum   <= PsiFixFromReal(1.0, NumFmt_c);
    InDenom <= PsiFixFromReal(0.001, DenomFmt_c);
    InVld   <= '1';
    wait until rising_edge(Clk) and InRdy = '1';
    InVld   <= '0';
    wait until rising_edge(Clk) and OutVld = '1';
    CheckReal(16.0, PsiFixToReal(OutQuot, OutFmt_c), 0.01, "Saturation");

    -- Check Input Handshaking
    wait until rising_edge(Clk);
    InNum   <= PsiFixFromReal(1.0, NumFmt_c);
    InDenom <= PsiFixFromReal(0.001, DenomFmt_c);
    InVld   <= '1';
    wait until rising_edge(Clk) and InRdy = '1';
    InNum   <= PsiFixFromReal(3.0, NumFmt_c);
    InDenom <= PsiFixFromReal(0.5, DenomFmt_c);
    wait until rising_edge(Clk) and InRdy = '1';
    InNum   <= PsiFixFromReal(0.0, NumFmt_c);
    InDenom <= PsiFixFromReal(0.0, DenomFmt_c);
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    InVld   <= '0';
    wait until rising_edge(Clk) and OutVld = '1';
    CheckReal(6.0, PsiFixToReal(OutQuot, OutFmt_c), 0.01, "Handshaking");

    -- Test file content (bittrueness)
    file_open(fIn, DataDir_g & "/input.txt", read_mode);
    file_open(fOut, DataDir_g & "/output.txt", read_mode);
    while not endfile(fIn) loop
      readline(fIn, r);
      read(r, iNum);
      read(r, iDenom);
      readline(fOut, r);
      read(r, resp);
      wait until rising_edge(Clk);
      InNum   <= std_logic_vector(to_signed(iNum, InNum'length));
      InDenom <= std_logic_vector(to_signed(iDenom, InDenom'length));
      InVld   <= '1';
      wait until rising_edge(Clk) and InRdy = '1';
      InNum   <= PsiFixFromReal(0.0, NumFmt_c);
      InDenom <= PsiFixFromReal(0.0, DenomFmt_c);
      InVld   <= '0';
      wait until rising_edge(Clk) and OutVld = '1';
      assert to_integer(signed(OutQuot)) = resp
      report "###ERROR###: received wrong output, sample " & integer'image(idx) & 
						"[exp " & integer'image(resp) & 
						", got " & integer'image(to_integer(signed(OutQuot))) & "]"
      severity error;
      idx     := idx + 1;
    end loop;
    file_close(fIn);
    file_close(fOut);

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
