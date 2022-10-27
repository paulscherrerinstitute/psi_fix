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
use work.psi_tb_textfile_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_noise_awgn_tb is
  generic(
    file_folder_g   : string  := "../testbench/psi_fix_noise_awgn_tb/Data";
    vld_duty_cycle_g : integer := 5
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_noise_awgn_tb is

  -- *** Constants ***
  constant OutFmt_c : psi_fix_fmt_t := (1, 0, 15);

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
  signal OutData : std_logic_vector(psi_fix_size(OutFmt_c) - 1 downto 0) := (others => '0');
  signal OutVld  : std_logic                                           := '0';

  signal SigOut : TextfileData_t(0 to 0) := (others => 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_fix_noise_awgn
    generic map(
      out_fmt_g => OutFmt_c
    )
    port map(
      clk_i     => Clk,
      rst_i     => Rst,
      vld_i   => InVld,
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
  p_stimuli : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- Generate Valid Pulses
    wait until rising_edge(Clk);
    while ProcessDone(TbProcNr_response_c) = '0' loop
      InVld <= '1';
      wait until rising_edge(Clk);
      if vld_duty_cycle_g > 1 then
        InVld <= '0';
        for i in 1 to vld_duty_cycle_g - 1 loop
          wait until rising_edge(Clk);
        end loop;
      end if;
    end loop;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stimuli_c) <= '1';
    wait;
  end process;

  -- *** response ***
  SigOut(0) <= to_integer(signed(OutData));
  p_response : process
  begin
    -- start of process !DO NOT EDIT
    wait until Rst = '0';

    -- User Code
    CheckTextfileContent(Clk         => Clk,
                         Rdy         => PsiTextfile_SigUnused,
                         Vld         => OutVld,
                         Data        => SigOut,
                         Filepath    => file_folder_g & "/output.txt",
                         IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_response_c) <= '1';
    wait;
  end process;

end;
