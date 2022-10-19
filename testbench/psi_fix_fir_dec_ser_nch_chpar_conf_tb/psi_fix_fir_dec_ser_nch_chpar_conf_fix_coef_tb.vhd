------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

-- This testbench is only very brief and required only to check if the fixed coefficient
-- mode works. All bittrue tests are executed in the configurable TB.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_fix_pkg.all;
use work.psi_common_array_pkg.all;

entity psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb is
  generic(
    TestRamInit_g : boolean := false
  );
end entity psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb;

architecture sim of psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb is

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockFrequency_c : real    := 100.0e6;
  constant ClockPeriod_c    : time    := (1 sec) / ClockFrequency_c;
  signal TbRunning          : boolean := True;
  signal ResponseDone       : boolean := False;

  constant CoefFmt_c : PsiFixFmt_t := (1, 0, 15);
  constant DataFmt_c : PsiFixFmt_t := (1, 0, 15);

  constant Coefs_c : t_areal(0 to 9) := (1.0 / 2.0**8.0, 2.0 / 2.0**8.0, 3.0 / 2.0**8.0, 4.0 / 2.0**8.0,
                                         5.0 / 2.0**8.0, 6.0 / 2.0**8.0, 7.0 / 2.0**8.0, 8.0 / 2.0**8.0,
                                         9.0 / 2.0**8.0, 10.0 / 2.0**8.0);

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal Clk     : std_logic                                            := '0';
  signal Rst     : std_logic                                            := '1';
  signal InVld   : std_logic                                            := '0';
  signal InData  : std_logic_vector(PsiFixSize(DataFmt_c) - 1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                            := '0';
  signal OutData : std_logic_vector(PsiFixSize(DataFmt_c) - 1 downto 0) := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_fix_fir_dec_ser_nch_chpar_conf
    generic map(
      InFmt_g       => DataFmt_c,
      OutFmt_g      => DataFmt_c,
      CoefFmt_g     => CoefFmt_c,
      Channels_g    => 1,
      MaxRatio_g    => 3,
      MaxTaps_g     => 10,
      Rnd_g         => PsiFixTrunc,
      Sat_g         => PsiFixSat,
      UseFixCoefs_g => not TestRamInit_g,
      Coefs_g       => Coefs_c
    )
    port map(
      -- Control Signals
      clk_i => Clk,
      rst_i => Rst,
      -- Input
      vld_i => InVld,
      dat_i => InData,
      -- Output
      vld_o => OutVld,
      dat_o => OutData
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_pclk : process
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
  begin
    -- Reset
    Rst <= '1';
    wait for 1 us;
    wait until rising_edge(Clk);
    Rst <= '0';
    wait for 1 us;

    -- Apply Input
    wait until rising_edge(Clk);
    InVld  <= '1';
    InData <= PsiFixFromReal(0.5, DataFmt_c);
    wait until rising_edge(Clk);
    InVld  <= '0';
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    InData <= PsiFixFromReal(0.0, DataFmt_c);
    for i in 0 to 200 loop
      InVld <= '1';
      wait until rising_edge(Clk);
      InVld <= '0';
      wait until rising_edge(Clk);
      wait until rising_edge(Clk);
      wait until rising_edge(Clk);
    end loop;

    -- TB done
    assert ResponseDone report "###ERROR###: Response aquisition not completed" severity error;
    TbRunning <= false;
    wait;
  end process;

  p_check : process
  begin
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.5 * Coefs_c(0), DataFmt_c) report "###ERROR###: Wrong output 0" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.5 * Coefs_c(3), DataFmt_c) report "###ERROR###: Wrong output 1" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.5 * Coefs_c(6), DataFmt_c) report "###ERROR###: Wrong output 2" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.5 * Coefs_c(9), DataFmt_c) report "###ERROR###: Wrong output 3" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong output 4" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong output 5" severity error;
    wait until rising_edge(Clk) and OutVld = '1';
    assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong output 6" severity error;

    -- TB done
    ResponseDone <= True;
    wait;
  end process;

end sim;
