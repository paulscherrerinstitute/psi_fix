------------------------------------------------------------
--
------------------------------------------------------------
-- see Library/Python/TbGenerator

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_tb_textfile_pkg.all;
-- @foramter:off
entity psi_fix_complex_addsub_tb is
  generic(pipeline_g   : boolean := true;
          file_folder_g : string  := "../testbench/psi_fix_complex_addsub_tb/Data";
          clk_per_spl_g  : integer := 1);
end entity;

architecture sim of psi_fix_complex_addsub_tb is
  -- *** Fixed Generics ***
  constant rst_pol_g : std_logic   := '1';
  constant in_a_fmt_g : psi_fix_fmt_t := (1, 0, 15);
  constant in_b_fmt_g : psi_fix_fmt_t := (1, 0, 15);
  constant out_fmt_g : psi_fix_fmt_t := (1, 0, 15);
  constant round_g  : psi_fix_rnd_t := psi_fix_round;
  constant sat_g    : psi_fix_sat_t := psi_fix_sat;

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 2) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 2) := (others => '1');
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_resp_c    : integer                  := 1;
  constant TbProcNr_resp1_c   : integer                  := 2;

  signal StimuliSig   : TextfileData_t(0 to 3);
  signal SubRespSig   : TextfileData_t(0 to 1);
  signal AddRespSig   : TextfileData_t(0 to 1);
  signal InClk        : std_logic := '0';
  signal InRst        : std_logic;
  signal InInpADat    : std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0);
  signal InQuaADat    : std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0);
  signal InInpBDat    : std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0);
  signal InQuaBDat    : std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0);
  signal InVld        : std_logic;
  signal SubOutInpDat : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  signal SubOutQuaDat : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  signal OutVld       : std_logic;
  signal AddOutInpDat : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  signal AddOutQuaDat : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation Add
  ------------------------------------------------------------
  i_dut_add : entity work.psi_fix_complex_addsub
    generic map(
      rst_pol_g   => rst_pol_g,
      pipeline_g => pipeline_g,
      in_a_fmt_g   => in_a_fmt_g,
      in_b_fmt_g   => in_b_fmt_g,
      out_fmt_g   => out_fmt_g,
      round_g    => round_g,
      sat_g      => sat_g,
      add_sub_g   => "ADD")
    port map(
      clk_i         => InClk,
      rst_i         => InRst,
      dat_inA_inp_i => InInpADat,
      dat_inA_qua_i => InQuaADat,
      dat_inB_inp_i => InInpBDat,
      dat_inB_qua_i => InQuaBDat,
      vld_i         => InVld,
      dat_out_inp_o => AddOutInpDat,
      dat_out_qua_o => AddOutQuaDat,
      vld_o         => OutVld);

  ------------------------------------------------------------
  -- DUT Instantiation Sub
  ------------------------------------------------------------
  i_dut_sub : entity work.psi_fix_complex_addsub
    generic map(
      rst_pol_g   => rst_pol_g,
      pipeline_g => pipeline_g,
      in_a_fmt_g   => in_a_fmt_g,
      in_b_fmt_g   => in_b_fmt_g,
      out_fmt_g   => out_fmt_g,
      round_g    => round_g,
      sat_g      => sat_g,
      add_sub_g   => "SUB")
    port map(
      clk_i         => InClk,
      rst_i         => InRst,
      dat_inA_inp_i => InInpADat,
      dat_inA_qua_i => InQuaADat,
      dat_inB_inp_i => InInpBDat,
      dat_inB_qua_i => InQuaBDat,
      vld_i         => InVld,
      dat_out_inp_o => SubOutInpDat,
      dat_out_qua_o => SubOutQuaDat,
      vld_o         => open);

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until InRst = '0';
    wait until ProcessDone = "111";
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_clk_i : process
    constant Frequency_c : real := real(100e6);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
      InClk <= not InClk;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_rst_i : process
  begin
    InRst <= '1';
    wait for 1 us;
    -- Wait for two clk edges to ensure reset is active for at least one edge
    wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    InRst <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** stim ***
  p_stim : process
  begin
    -- start of process !DO NOT EDIT
    wait until InRst = '0';

    -- Apply Stimuli
    ApplyTextfileContent(Clk         => InClk,
                         Rdy         => PsiTextfile_SigOne,
                         Vld         => InVld,
                         Data        => StimuliSig,
                         Filepath    => file_folder_g & "/input.txt",
                         ClkPerSpl   => clk_per_spl_g,
                         IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  InInpADat <= std_logic_vector(to_signed(StimuliSig(0), InInpADat'length));
  InQuaADat <= std_logic_vector(to_signed(StimuliSig(1), InQuaADat'length));
  InInpBDat <= std_logic_vector(to_signed(StimuliSig(2), InInpBDat'length));
  InQuaBDat <= std_logic_vector(to_signed(StimuliSig(3), InQuaBDat'length));

  -- *** resp ***
  AddRespSig(0) <= to_integer(signed(AddOutInpDat));
  AddRespSig(1) <= to_integer(signed(AddOutQuaDat));

  p_resp_add : process
  begin
    -- start of process !DO NOT EDIT
    wait until InRst = '0';

    -- Check
    CheckTextfileContent(Clk         => InClk,
                         Rdy         => PsiTextfile_SigUnused,
                         Vld         => OutVld,
                         Data        => AddRespSig,
                         Filepath    => file_folder_g & "/output_add.txt",
                         IgnoreLines => 1);

    --   end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_resp_c) <= '1';
    wait;
  end process;

  SubRespSig(0) <= to_integer(signed(SubOutInpDat));
  SubRespSig(1) <= to_integer(signed(SubOutQuaDat));

  p_resp_sub : process
  begin
    -- start of process !DO NOT EDIT
    wait until InRst = '0';
    -- Check
    CheckTextfileContent(Clk         => InClk,
                         Rdy         => PsiTextfile_SigUnused,
                         Vld         => OutVld,
                         Data        => SubRespSig,
                         Filepath    => file_folder_g & "/output_sub.txt",
                         IgnoreLines => 1);
    --   end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_resp1_c) <= '1';
    wait;
  end process;

end;
