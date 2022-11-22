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

--library work;
use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_tb_textfile_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_phase_unwrap_tb is
  generic(
    file_folder_g   : string  := "../testbench/psi_fix_phase_unwrap_tb/Data";
    stimuli_set_g   : string  := "S";    -- "S" = signed, "U" = unsigned
    vld_duty_cycle_g : integer := 5
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_phase_unwrap_tb is
  -- *** Fixed Generics ***
  constant out_fmt_g : psi_fix_fmt_t := (1, 3, 15);
  constant round_g  : psi_fix_rnd_t := psi_fix_trunc;

  -- *** Constants ***
  constant InFmtS_c : psi_fix_fmt_t := (1, 0, 15);
  constant InFmtU_c : psi_fix_fmt_t := (0, 1, 15);
  constant InFmt_c  : psi_fix_fmt_t := psi_fix_choose_fmt(stimuli_set_g = "S", InFmtS_c, InFmtU_c);

  -- *** TB Control ***
  signal TbRunning             : boolean                  := True;
  signal NextCase              : integer                  := -1;
  signal ProcessDone           : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c  : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stimuli_c  : integer                  := 0;
  constant TbProcNr_response_c : integer                  := 1;

  -- *** DUT Signals ***
  signal Clk     : std_logic                                           := '1';
  signal Rst     : std_logic                                           := '1';
  signal InVld   : std_logic                                           := '0';
  signal InData  : std_logic_vector(psi_fix_size(InFmt_c) - 1 downto 0)  := (others => '0');
  signal OutData : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                           := '0';
  signal OutWrap : std_logic                                           := '0';

  signal SigIn  : TextfileData_t(0 to 0) := (others => 0);
  signal SigOut : TextfileData_t(0 to 1) := (others => 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_fix_phase_unwrap
    generic map(
      in_fmt_g  => InFmt_C,
      out_fmt_g => out_fmt_g,
      round_g  => round_g
    )
    port map(
      clk_i     => Clk,
      rst_i     => Rst,
      vld_i   => InVld,
      dat_i  => InData,
      dat_o => OutData,
      wrap_o => OutWrap,
      vld_o  => OutVld
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
    constant Frequency_c : real := real(127e6);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
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
    -- Wait for two Clk edges to ensure reset is active for at least one edge
    wait until rising_edge(Clk);
    wait until rising_edge(Clk);
    Rst <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** stimuli ***
  InData <= std_logic_vector(to_signed(SigIn(0), InData'length));
  p_stimuli : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- User Code
    ApplyTextfileContent(Clk         => Clk,
                         Rdy         => PsiTextfile_SigOne,
                         Vld         => InVld,
                         Data        => SigIn,
                         Filepath    => file_folder_g & choose(stimuli_set_g = "S", "/InputS.txt", "/InputU.txt"),
                         ClkPerSpl   => vld_duty_cycle_g,
                         IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stimuli_c) <= '1';
    wait;
  end process;

  -- *** response ***
  SigOut(0) <= to_integer(signed(OutData));
  SigOut(1) <= choose(OutWrap = '1', 1, 0);
  p_response : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- User Code
    CheckTextfileContent(Clk         => Clk,
                         Rdy         => PsiTextfile_SigUnused,
                         Vld         => OutVld,
                         Data        => SigOut,
                         Filepath    => file_folder_g & choose(stimuli_set_g = "S", "/OutputS.txt", "/OutputU.txt"),
                         IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_response_c) <= '1';
    wait;
  end process;

end;
