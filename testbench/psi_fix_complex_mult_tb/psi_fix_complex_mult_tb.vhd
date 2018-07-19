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
	use work.psi_tb_textfile_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_complex_mult_tb is
	generic (
		Pipeline_g 		: boolean 		:= false;
		FileFolder_g	: string 		:= "../tesbench/psi_fix_complex_mult_tb/Data";
		ClkPerSpl_g		: integer		:= 1
	);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_fix_complex_mult_tb is
	-- *** Fixed Generics ***
	constant RstPol_g : std_logic := '1';
	constant InAFmt_g : PsiFixFmt_t := (1,0,15);
	constant InBFmt_g : PsiFixFmt_t := (1,0,24);
	constant InternalFmt_g : PsiFixFmt_t := (1,1,24);
	constant OutFmt_g : PsiFixFmt_t := (1,0,20);
	constant Round_g : PsiFixRnd_t := PsiFixRound;
	constant Sat_g : PsiFixSat_t := PsiFixSat;
	
	-- *** Not Assigned Generics (default values) ***
	
	-- *** TB Control ***
	signal TbRunning : boolean := True;
	signal NextCase : integer := -1;
	signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
	constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
	constant TbProcNr_stim_c : integer := 0;
	constant TbProcNr_resp_c : integer := 1;
	
	signal StimuliSig 	: TextfileData_t(0 to 3)(31 downto 0);
	signal RespSig 		: TextfileData_t(0 to 1)(PsiFixSize(OutFmt_g)-1 downto 0);	
	
	-- *** DUT Signals ***
	signal clk_i : std_logic := '1';
	signal rst_i : std_logic := '1';
	signal ai_i : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0) := (others => '0');
	signal aq_i : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0) := (others => '0');
	signal bi_i : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0) := (others => '0');
	signal bq_i : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0) := (others => '0');
	signal vld_i : std_logic := '0';
	signal iout_o : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0) := (others => '0');
	signal qout_o : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0) := (others => '0');
	signal vld_o : std_logic := '0';
	
begin
	------------------------------------------------------------
	-- DUT Instantiation
	------------------------------------------------------------
	i_dut : entity work.psi_fix_complex_mult
		generic map (
			Pipeline_g => Pipeline_g,
			RstPol_g => RstPol_g,
			InAFmt_g => InAFmt_g,
			InBFmt_g => InBFmt_g,
			InternalFmt_g => InternalFmt_g,
			OutFmt_g => OutFmt_g,
			Round_g => Round_g,
			Sat_g => Sat_g
		)
		port map (
			clk_i => clk_i,
			rst_i => rst_i,
			ai_i => ai_i,
			aq_i => aq_i,
			bi_i => bi_i,
			bq_i => bq_i,
			vld_i => vld_i,
			iout_o => iout_o,
			qout_o => qout_o,
			vld_o => vld_o
		);
	
	------------------------------------------------------------
	-- Testbench Control !DO NOT EDIT!
	------------------------------------------------------------
	p_tb_control : process
	begin
		wait until rst_i = '0';
		wait until ProcessDone = AllProcessesDone_c;
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
			wait for 0.5*(1 sec)/Frequency_c;
			clk_i <= not clk_i;
		end loop;
		wait;
	end process;
	
	
	------------------------------------------------------------
	-- Resets
	------------------------------------------------------------
	p_rst_rst_i : process
	begin
		wait for 1 us;
		-- Wait for two clk edges to ensure reset is active for at least one edge
		wait until rising_edge(clk_i);
		wait until rising_edge(clk_i);
		rst_i <= '0';
		wait;
	end process;
	
	
	------------------------------------------------------------
	-- Processes
	------------------------------------------------------------
	-- *** stim ***
	p_stim : process
	begin
		-- start of process !DO NOT EDIT
		wait until rst_i = '0';
		
		-- Apply Stimuli	
		appy_textfile_content(	Clk 		=> clk_i, 
								Rdy 		=> PsiTextfile_SigOne,
								Vld 		=> vld_i, 
								Data		=> StimuliSig, 
								Filepath	=> FileFolder_g & "/input.txt", 
								ClkPerSpl	=> ClkPerSpl_g,
								IgnoreLines => 1);	
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_stim_c) <= '1';
		wait;
	end process;
	ai_i <= StimuliSig(0)(ai_i'left downto 0);
	aq_i <= StimuliSig(1)(aq_i'left downto 0);
	bi_i <= StimuliSig(2)(bi_i'left downto 0);
	bq_i <= StimuliSig(3)(bq_i'left downto 0);	
	
	-- *** resp ***
	RespSig(0)	<= iout_o;
	RespSig(1)	<= qout_o;
	p_resp : process
	begin
		-- start of process !DO NOT EDIT
		wait until rst_i = '0';
		
		-- Check
		check_textfile_content(	Clk			=> clk_i,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> vld_o,
								Data		=> RespSig,
								Filepath	=> FileFolder_g & "/output.txt",
								IgnoreLines => 1);
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_resp_c) <= '1';
		wait;
	end process;
	
	
end;
