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
use work.psi_tb_compare_pkg.all;
use work.psi_fix_pkg.all;

library std;
use std.textio.all;

entity psi_fix_cic_dec_fix_nch_par_tdm_tb is
  generic(
    DataDir_g      : string               := "../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb/Data";
    InFile_g       : string               := "input_o4_r9_dd2_gcTrue.txt";
    Outfile_g      : string               := "output_o4_r9_dd2_gcTrue.txt";
    IdleCycles_g   : integer              := 2;
    Order_g        : integer              := 4;
    Ratio_g        : integer              := 9;
    DiffDelay_g    : natural range 1 to 2 := 2;
    AutoGainCorr_g : boolean              := True
  );
end entity psi_fix_cic_dec_fix_nch_par_tdm_tb;

architecture sim of psi_fix_cic_dec_fix_nch_par_tdm_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant InFmt_c     : PsiFixFmt_t := (1, 0, 16);
  constant OutFmt_c    : PsiFixFmt_t := (1, 0, 17);
  constant Channels_c  : integer     := 3;
  constant InChWidth_c : integer     := PsiFixSize(InFmt_c);

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockFrequency_c : real    := 100.0e6;
  constant ClockPeriod_c    : time    := (1 sec) / ClockFrequency_c;
  signal TbRunning          : boolean := True;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal Clk     : std_logic                                              := '0';
  signal Rst     : std_logic                                              := '1';
  signal InVld   : std_logic                                              := '0';
  signal InData  : std_logic_vector(3 * PsiFixSize(InFmt_c) - 1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                              := '0';
  signal OutData : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0)    := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_fix_cic_dec_fix_nch_par_tdm
    generic map(
      rst_pol_g      => '1',
      Channels_g     => Channels_c,
      Order_g        => Order_g,
      Ratio_g        => Ratio_g,
      DiffDelay_g    => DiffDelay_g,
      InFmt_g        => InFmt_c,
      OutFmt_g       => OutFmt_c,
      AutoGainCorr_g => AutoGainCorr_g
    )
    port map(
      -- Control Signals
      clk_i => Clk,
      rst_i => Rst,
      -- Data Ports
      dat_i => InData,
      vld_i => InVld,
      dat_o => OutData,
      vld_o => OutVld
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
  -- Apply Input
  -------------------------------------------------------------------------
  p_input : process
    file fIn     : text;
    variable r   : line;
    variable val : integer;
  begin
    -- Reset
    Rst <= '1';
    wait for 1 us;
    Rst <= '0';
    wait for 1 us;

    -- Test file content (bittrueness)
    --print(DataDir_g & "/" & InFile_g);
    file_open(fIn, DataDir_g & "/" & InFile_g, read_mode);
    wait until rising_edge(Clk);
    while not endfile(fIn) loop
      readline(fIn, r);
      InVld <= '1';
      for ch in 0 to 2 loop
        read(r, val);
        InData(InChWidth_c * (ch + 1) - 1 downto InChWidth_c * ch) <= std_logic_vector(to_signed(val, InChWidth_c));
      end loop;
      wait until rising_edge(Clk);
      for c in 0 to IdleCycles_g - 1 loop
        InVld <= '0';
        wait until rising_edge(Clk);
      end loop;
    end loop;
    InVld <= '0';
    file_close(fIn);

    -- TB done
    TbRunning <= false;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- Check Output
  -------------------------------------------------------------------------
  p_output : process
    file fOut     : text;
    variable r    : line;
    variable resp : integer;
    variable idx  : integer := 0;
  begin
    wait until Rst = '0';

    -- Check initial state
    assert OutVld = '0' report "###ERROR###: Initial state of output valid is high" severity error;

    -- Test file content (bittrueness)
    file_open(fOut, DataDir_g & "/" & Outfile_g, read_mode);
    while not endfile(fOut) loop
      readline(fOut, r);
      for ch in 0 to 2 loop
        read(r, resp);
        wait until rising_edge(Clk) and OutVld = '1';
        StdlvCompareInt(resp, OutData, "WrongValue [" & integer'image(idx) & "] channel " & integer'image(ch));
      end loop;
      idx := idx + 1;
    end loop;
    file_close(fOut);
    wait;
  end process;

end sim;
