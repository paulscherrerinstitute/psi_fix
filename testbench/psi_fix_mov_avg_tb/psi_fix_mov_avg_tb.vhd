------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------
-- Testbench generated by TbGen.py
------------------------------------------------------------
-- see Library/Python/TbGenerator

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library work;
  use work.psi_common_math_pkg.all;
  use work.psi_fix_pkg.all;
  use work.psi_tb_txt_util.all;
  use work.psi_tb_textfile_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_mov_avg_tb is
  generic (
    gain_corr_g     : string  := "ROUGH";
    file_folder_g : string  := "../tesbench/psi_fix_demod_real2cplx_tb/Data";
    duty_cycle_g    : integer := 1;
    out_regs_g    : integer := 1
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_mov_avg_tb is
  -- *** Fixed Generics ***
  constant in_fmt_g : psi_fix_fmt_t := (1,0,10);
  constant out_fmt_g : psi_fix_fmt_t := (1,1,12);
  constant taps_g : positive := 7;

  -- *** Not Assigned Generics (default values) ***
  constant round_g : psi_fix_rnd_t := psi_fix_round ;
  constant sat_g : psi_fix_sat_t := psi_fix_sat;

  -- *** TB Control ***
  signal TbRunning : boolean := True;
  signal NextCase : integer := -1;
  signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stim_c : integer := 0;
  constant TbProcNr_check_c : integer := 1;

  -- *** DUT Signals ***
  signal Clk : std_logic := '0';
  signal Rst : std_logic := '1';
  signal InVld : std_logic := '0';
  signal InData : std_logic_vector(psi_fix_size(in_fmt_g)-1 downto 0) := (others => '0');
  signal OutVld : std_logic := '0';
  signal OutData : std_logic_vector(psi_fix_size(out_fmt_g)-1 downto 0) := (others => '0');
  signal SigIn          : TextfileData_t(0 to 0)  := (others => 0);
  signal SigOut         : TextfileData_t(0 to 0)  := (others => 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_fix_mov_avg
    generic map (
      gain_corr_g => gain_corr_g,
      in_fmt_g => in_fmt_g,
      out_fmt_g => out_fmt_g,
      taps_g => taps_g,
      out_regs_g => out_regs_g
    )
    port map (
      clk_i => Clk,
      rst_i => Rst,
      vld_i => InVld,
      dat_i => InData,
      vld_o => OutVld,
      dat_o => OutData
    );

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until Rst = '0';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_Clk : process
    constant Frequency_c : real := real(100e6);
  begin
    while TbRunning loop
      wait for 0.5*(1 sec)/Frequency_c;
      Clk <= not Clk;
    end loop;
    wait;
  end process;


  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_Rst : process
  begin
    wait for 1 us;
    -- Wait for two clk edges to ensure reset is active for at least one edge
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    Rst <= '0';
    wait;
  end process;


  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** stim ***
  InData <= std_logic_vector(to_signed(SigIn(0), InData'length));
  p_stim : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- Apply Stimuli
    ApplyTextfileContent( Clk     => Clk,
                Rdy     => PsiTextfile_SigOne,
                Vld     => InVld,
                Data    => SigIn,
                Filepath  => file_folder_g & "/input.txt",
                ClkPerSpl => duty_cycle_g,
                IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** check ***
  SigOut(0) <= to_integer(signed(OutData));
  p_check : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- Check
    CheckTextfileContent( Clk     => Clk,
                Rdy     => PsiTextfile_SigUnused,
                Vld     => OutVld,
                Data    => SigOut,
                Filepath  => file_folder_g & "/output_" & to_lower(gain_corr_g) & ".txt",
                IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_check_c) <= '1';
    wait;
  end process;


end;
