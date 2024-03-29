------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
------------------------------------------------------------

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

library work;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

use work.psi_tb_textfile_pkg.all;
------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_fir_3tap_hbw_dec2_tb is
  generic (
    file_folder_g : string := "../testbench/psi_fix_fir_3tap_hbw_dec2_tb/Data/";
    in_file_g : string := "input.txt";
    out_file_g : string := "output.txt";
    vld_duty_cycle_g : positive := 5;
    channels_g : natural := 2;
    separate_g : boolean := true
    );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_fir_3tap_hbw_dec2_tb is
  -- *** Fixed Generics ***

  -- *** Not Assigned Generics (default values) ***
  constant in_fmt_g  : psi_fix_fmt_t := (1, 0, 17);
  constant out_fmt_g : psi_fix_fmt_t := (1, 0, 17);
  constant int_fmt_g : psi_fix_fmt_t := (1, 0, 17);
  constant rnd_g    : psi_fix_rnd_t := psi_fix_round;
  constant sat_g    : psi_fix_sat_t := psi_fix_sat;
  constant shifts_g : t_ainteger  := (2, 1, 2);

  -- *** TB Control ***
  signal TbRunning            : boolean                  := true;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_Input_c   : integer                  := 0;
  constant TbProcNr_Output_c  : integer                  := 1;

  -- *** DUT Signals ***
  signal Clk     : std_logic                                                     := '1';
  signal Rst     : std_logic                                                     := '1';
  signal InVld   : std_logic                                                     := '0';
  signal InData  : std_logic_vector(psi_fix_size(in_fmt_g)*2*channels_g-1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                                     := '0';
  signal OutData : std_logic_vector(psi_fix_size(out_fmt_g)*channels_g-1 downto 0)  := (others => '0');

  signal SigIn          : TextfileData_t(0 to 2*channels_g-1) := (others => 0);
  signal SigOut         : TextfileData_t(0 to channels_g-1) := (others => 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_fix_fir_3tap_hbw_dec2
    generic map (
      channels_g => channels_g,
      separate_g => separate_g
      )
    port map (
      clk_i     => Clk,
      rst_i     => Rst,
      vld_i   => InVld,
      dat_i  => InData,
      vld_o  => OutVld,
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
  -- *** stimuli ***
  process (SigIn, InVld) is
  begin
    if InVld = '0' then
      InData <= (others => 'X');
    else
      for i in 0 to channels_g-1 loop
        InData(psi_fix_size(in_fmt_g)*(2*i+1)-1 downto psi_fix_size(in_fmt_g)*(2*i)) <= std_logic_vector(to_signed(SigIn(2*i), psi_fix_size(in_fmt_g)));
        InData(psi_fix_size(in_fmt_g)*(2*i+2)-1 downto psi_fix_size(in_fmt_g)*(2*i+1)) <= std_logic_vector(to_signed(SigIn(2*i+1), psi_fix_size(in_fmt_g)));
      end loop;
    end if;
  end process;

  p_stimuli : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- User Code
    ApplyTextfileContent( Clk     => Clk,
                            Rdy     => PsiTextfile_SigOne,
                            Vld     => InVld,
                            Data    => SigIn,
                            Filepath  => file_folder_g & "/" & in_file_g,
                            ClkPerSpl => vld_duty_cycle_g,
                            IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_input_c) <= '1';
    wait;
  end process;

  -- *** response ***
  process (OutData) is
  begin
    for i in 0 to channels_g-1 loop
      SigOut(i) <= to_integer(signed(OutData(psi_fix_size(out_fmt_g)*(i+1)-1 downto psi_fix_size(out_fmt_g)*i)));
    end loop;
  end process;

  p_response : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- User Code
    CheckTextfileContent( Clk     => Clk,
                            Rdy     => PsiTextfile_SigUnused,
                            Vld     => OutVld,
                            Data    => SigOut,
                            Filepath  => file_folder_g & "/" & out_file_g,
                            IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_output_c) <= '1';
    wait;
  end process;

end;
