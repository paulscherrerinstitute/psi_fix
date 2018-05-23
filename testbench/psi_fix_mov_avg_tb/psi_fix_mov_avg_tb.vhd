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
		GainCorr_g 		: string 	:= "ROUGH";
		FileFolder_g	: string 	:= "../tesbench/psi_fix_demod_real2cplx_tb/Data";
		DutyCycle_g		: integer	:= 1;
		OutRegs_g		: integer	:= 1
	);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_mov_avg_tb is
	-- *** Fixed Generics ***
	constant InFmt_g : PsiFixFmt_t := (1,0,10);
	constant OutFmt_g : PsiFixFmt_t := (1,1,12);
	constant Taps_g : positive := 7;
	
	-- *** Not Assigned Generics (default values) ***
	constant Round_g : PsiFixRnd_t := PsiFixRound ;
	constant Sat_g : PsiFixSat_t := PsiFixSat;
	
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
	signal InData : std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0) := (others => '0');
	signal OutVld : std_logic := '0';
	signal OutData : std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0) := (others => '0');
	
begin
	------------------------------------------------------------
	-- DUT Instantiation
	------------------------------------------------------------
	i_dut : entity work.psi_fix_mov_avg
		generic map (
			GainCorr_g => GainCorr_g,
			InFmt_g => InFmt_g,
			OutFmt_g => OutFmt_g,
			Taps_g => Taps_g,
			OutRegs_g => OutRegs_g
		)
		port map (
			Clk => Clk,
			Rst => Rst,
			InVld => InVld,
			InData => InData,
			OutVld => OutVld,
			OutData => OutData
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
	p_stim : process
	begin
		-- start of process !DO NOT EDIT
		wait until Rst = '0';
		
		-- Apply Stimuli	
		appy_textfile_content(	Clk 		=> Clk, 
								Rdy 		=> PsiTextfile_SigOne,
								Vld 		=> InVld, 
								Data(0)		=> InData, 
								Filepath	=> FileFolder_g & "/input.txt", 
								ClkPerSpl	=> DutyCycle_g,
								IgnoreLines => 1);	
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_stim_c) <= '1';
		wait;
	end process;
	
	-- *** check ***
	p_check : process
	begin
		-- start of process !DO NOT EDIT
		wait until Rst = '0';
		
		-- Check
		check_textfile_content(	Clk			=> Clk,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> OutVld,
								Data(0)		=> OutData,
								Filepath	=> FileFolder_g & "/output_" & to_lower(GainCorr_g) & ".txt",
								IgnoreLines => 1);
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_check_c) <= '1';
		wait;
	end process;
	
	
end;
