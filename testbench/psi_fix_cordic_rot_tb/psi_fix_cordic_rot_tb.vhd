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
	use work.psi_fix_pkg.all;
	use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_tb_textfile_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_cordic_rot_tb is
	generic (
		GainComp_g 		: boolean 		:= False ;
		Round_g 		: PsiFixRnd_t 	:= PsiFixTrunc ;
		Sat_g 			: PsiFixSat_t 	:= PsiFixWrap ;
		Mode_g 			: string 		:= "PIPELINED";
		FileFolder_g	: string 		:= "../tesbench/psi_fix_cordic_vect_tb/Data"
	);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_cordic_rot_tb is
	-- *** Fixed Generics ***
	constant InAbsFmt_g : PsiFixFmt_t := (0,0,16);
	constant InAngleFmt_g : PsiFixFmt_t := (0,0,15);
	constant OutFmt_g : PsiFixFmt_t := (1,2,16);
	constant InternalFmt_g : PsiFixFmt_t := (1,2,22);
	constant AngleIntFmt_g : PsiFixFmt_t := (1,-2,23);
	constant Iterations_g : natural := 21;
	
	-- *** Not Assigned Generics (default values) ***
	
	-- *** TB Control ***
	signal TbRunning : boolean := True;
	signal NextCase : integer := -1;
	signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
	constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
	constant TbProcNr_stim_c : integer := 0;
	constant TbProcNr_resp_c : integer := 1;
	
	-- *** DUT Signals ***
	signal Clk : std_logic := '0';
	signal Rst : std_logic := '1';
	signal InVld : std_logic := '0';
	signal InRdy : std_logic := '1';
	signal InAbs : std_logic_vector(PsiFixSize(InAbsFmt_g)-1 downto 0) := (others => '0');
	signal InAng : std_logic_vector(PsiFixSize(InAngleFmt_g)-1 downto 0) := (others => '0');
	signal OutVld : std_logic := '0';
	signal OutI : std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0) := (others => '0');
	signal OutQ : std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0) := (others => '0');
	
	-- *** User Definitions ***
	constant RespFileName_c : string	:= choose(GainComp_g, "outputWithGc.txt", "outputWithNoGc.txt");
	signal RespFileSig : TextfileData_t(0 to 1)(31 downto 0);	
	
begin
	------------------------------------------------------------
	-- DUT Instantiation
	------------------------------------------------------------
	i_dut : entity work.psi_fix_cordic_rot
		generic map (
			GainComp_g => GainComp_g,
			Round_g => Round_g,
			Sat_g => Sat_g,
			Mode_g => Mode_g,
			InAbsFmt_g => InAbsFmt_g,
			InAngleFmt_g => InAngleFmt_g,
			OutFmt_g => OutFmt_g,
			InternalFmt_g => InternalFmt_g,
			AngleIntFmt_g => AngleIntFmt_g,
			Iterations_g => Iterations_g
		)
		port map (
			Clk => Clk,
			Rst => Rst,
			InVld => InVld,
			InRdy => InRdy,
			InAbs => InAbs,
			InAng => InAng,
			OutVld => OutVld,
			OutI => OutI,
			OutQ => OutQ
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
								Rdy 		=> InRdy,
								Vld 		=> InVld, 
								Data		=> RespFileSig, 
								Filepath	=> FileFolder_g & "/input.txt", 
								IgnoreLines => 1);	
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_stim_c) <= '1';
		wait;
	end process;
	InAbs <= RespFileSig(0)(InAbs'left downto 0);
	InAng <= RespFileSig(1)(InAng'left downto 0);
	
	-- *** resp ***
	p_resp : process
	begin
		-- start of process !DO NOT EDIT
		wait until Rst = '0';
		
		-- Check
		check_textfile_content(	Clk			=> Clk,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> OutVld,
								Data(0)		=> OutI,
								Data(1)		=> OutQ,
								Filepath	=> FileFolder_g & "/" & RespFileName_c,
								IgnoreLines => 1);
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_resp_c) <= '1';
		wait;
	end process;
	
	
end;
