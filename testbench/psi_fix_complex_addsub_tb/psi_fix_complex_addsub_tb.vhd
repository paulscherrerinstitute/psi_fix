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

library work;
use work.psi_fix_pkg.all;
use work.psi_tb_textfile_pkg.all;
-- @foramter:off
------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_complex_addsub_tb is
  generic(Pipeline_g   : boolean := true;
          FileFolder_g : string  := "../testbench/psi_fix_complex_addsub_tb/Data";
          ClkPerSpl_g  : integer := 1);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_complex_addsub_tb is
  -- *** Fixed Generics ***
  constant RstPol_g : std_logic   := '1';
  constant InAFmt_g : PsiFixFmt_t := (1, 0, 15);
  constant InBFmt_g : PsiFixFmt_t := (1, 0, 15);
  constant OutFmt_g : PsiFixFmt_t := (1, 0, 15);
  constant Round_g  : PsiFixRnd_t := PsiFixRound;
  constant Sat_g    : PsiFixSat_t := PsiFixSat;

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
  signal InInpADat    : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
  signal InQuaADat    : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
  signal InInpBDat    : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
  signal InQuaBDat    : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
  signal InVld        : std_logic;
  signal SubOutInpDat : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  signal SubOutQuaDat : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  signal OutVld       : std_logic;
  signal AddOutInpDat : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  signal AddOutQuaDat : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);

begin
  ------------------------------------------------------------
  -- DUT Instantiation Add
  ------------------------------------------------------------
  i_dut_add : entity work.psi_fix_complex_addsub
    generic map(
      RstPol_g   => RstPol_g,
      Pipeline_g => Pipeline_g,
      InAFmt_g   => InAFmt_g,
      InBFmt_g   => InBFmt_g,
      OutFmt_g   => OutFmt_g,
      Round_g    => Round_g,
      Sat_g      => Sat_g,
      AddSub_g   => "ADD")
    port map(
      InClk   => InClk,
      InRst   => InRst,
      InIADat => InInpADat,
      InQADat => InQuaADat,
      InIBDat => InInpBDat,
      InQBDat => InQuaBDat,
      InVld   => InVld,
      OutIDat => AddOutInpDat,
      OutQDat => AddOutQuaDat,
      OutVld  => OutVld);

  ------------------------------------------------------------
  -- DUT Instantiation Sub
  ------------------------------------------------------------
  i_dut_sub : entity work.psi_fix_complex_addsub
    generic map(
      RstPol_g   => RstPol_g,
      Pipeline_g => Pipeline_g,
      InAFmt_g   => InAFmt_g,
      InBFmt_g   => InBFmt_g,
      OutFmt_g   => OutFmt_g,
      Round_g    => Round_g,
      Sat_g      => Sat_g,
      AddSub_g   => "SUB")
    port map(
      InClk   => InClk,
      InRst   => InRst,
      InIADat => InInpADat,
      InQADat => InQuaADat,
      InIBDat => InInpBDat,
      InQBDat => InQuaBDat,
      InVld   => InVld,
      OutIDat => SubOutInpDat,
      OutQDat => SubOutQuaDat,
      OutVld  => open);

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
                         Filepath    => FileFolder_g & "/input.txt",
                         ClkPerSpl   => ClkPerSpl_g,
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
                         Filepath    => FileFolder_g & "/output_add.txt",
                         IgnoreLines => 1);

    --	 end of process !DO NOT EDIT!
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
                         Filepath    => FileFolder_g & "/output_sub.txt",
                         IgnoreLines => 1);
    --	 end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_resp1_c) <= '1';
    wait;
  end process;

end;
