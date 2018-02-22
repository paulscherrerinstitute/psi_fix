------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_fix_pkg.all;

entity psi_fix_dds_18b_tb is
	generic (
		FileFolder_c		: string 	:= "../testbench/psi_fix_dds_18b_tb/Data";
		IdleCycles_g		: integer	:= 0
	);
end entity psi_fix_dds_18b_tb;

architecture sim of psi_fix_dds_18b_tb is

	-------------------------------------------------------------------------
	-- File Names
	-------------------------------------------------------------------------
	constant ConfigFile		: string	:= "Config.txt";
	constant SinCosFile		: string	:= "SinCos.txt";

	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant 	ClockFrequency_c	: real 		:= 160.0e6;
	constant	ClockPeriod_c		: time		:= (1 sec)/ClockFrequency_c;
	signal 		TbRunning			: boolean 	:= True;
	signal		TestCase			: integer	:= -1;	
	signal 		ResponseDone		: integer	:= -1;
	
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	constant OutFmt_c				: PsiFixFmt_t		:= (1, 0, 17);
	constant PhaseFmt_c				: PsiFixFmt_t		:= (0, 0, 31);
	signal Clk						: std_logic			:= '0';
	signal Rst						: std_logic 		:= '1';
	signal InVld					: std_logic			:= '0';
	signal OutVld					: std_logic			:= '0';
	signal OutSin					: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0)		:= (others => '0');
	signal OutCos					: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0)		:= (others => '0');
	signal PhaseStep				: std_logic_vector(PsiFixSize(PhaseFmt_c)-1 downto 0)	:= (others => '0');
	signal PhaseOffs				: std_logic_vector(PsiFixSize(PhaseFmt_c)-1 downto 0)	:= (others => '0');
	signal Restart					: std_logic			:= '0';
	
	-------------------------------------------------------------------------
	-- Procedures
	-------------------------------------------------------------------------	
	procedure CheckOutput(	file	fSinCos 	: 			text;
							signal 	Sin			: in		std_logic_vector;
							signal  Cos			: in		std_logic_vector;
									Idx			: in		integer) is
		variable ln		: line;
		variable Spl	: integer;
	begin
		readline(fSinCos,ln);
		read(ln, Spl);
		assert to_integer(signed(Sin)) = Spl 
			report "###ERROR###: Wrong Sin Sample " & integer'image(Idx)  &
			       " Expected: " & integer'image(Spl) &
				   " Received: " & integer'image(to_integer(signed(Sin)))
			severity error;
		read(ln, Spl);
		assert to_integer(signed(Cos)) = Spl 
			report "###ERROR###: Wrong Cos Sample " & integer'image(Idx)  &
			       " Expected: " & integer'image(Spl) &
				   " Received: " & integer'image(to_integer(signed(Cos)))
			severity error;			
	end procedure;

begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.psi_fix_dds_18b
		generic map (
			PhaseFmt_g	=> PhaseFmt_c
		)
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Control Signals
			Restart		=> Restart,
			PhaseStep	=> PhaseStep,
			PhaseOffs	=> PhaseOffs,
			-- Input
			InVld		=> InVld,
			-- Output
			OutVld		=> OutVld,
			OutSin		=> OutSin,
			OutCos		=> OutCos
		);
	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_clk : process
	begin
		Clk <= '0';
		while TbRunning loop
			wait for 0.5*ClockPeriod_c;
			Clk <= '1';
			wait for 0.5*ClockPeriod_c;
			Clk <= '0';
		end loop;
		wait;
	end process;
	
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		file fCfg, fSig	: text;
		variable ln	 	: line;
		variable Spl	: integer;
	begin
		-- Reset
		Rst <= '1';
		wait for 1 us;
		wait until rising_edge(Clk);
		Rst <= '0';
		wait for 1 us;
		
		-- Apply Configuration
		file_open(fCfg, FileFolder_c & "/" & ConfigFile, read_mode);
		wait until rising_edge(Clk);
		readline(fCfg,ln); --header
		readline(fCfg,ln);
		read(ln, Spl);
		PhaseStep <= std_logic_vector(to_unsigned(Spl, PhaseStep'length));
		read(ln, Spl);
		PhaseOffs <= std_logic_vector(to_unsigned(Spl, PhaseOffs'length));
		file_close(fCfg);
		wait until rising_edge(Clk);
		
		
		-- *** Case 0: Bittrueness ***
		print("Case 0: Bittrueness");
		TestCase <= 0;
		-- Apply Inputs
		file_open(fSig, FileFolder_c & "/" & SinCosFile, read_mode); --only required for determining the number of samples
		wait until rising_edge(Clk);
		while not endfile(fSig) loop
			readline(fSig,ln);
			InVld <= '1';	
			wait until rising_edge(Clk);
			for i in 0 to IdleCycles_g-1 loop
				InVld <= '0';
				wait until rising_edge(Clk);
			end loop;
		end loop;
		InVld <= '0';
		file_close(fSig);		wait until rising_edge(Clk);
		
		wait until ResponseDone = 0;
		
		-- *** Case 1: Restart ***
		print("Case 1: Restart");
		TestCase <= 1;
		-- Restart
		wait until rising_edge(Clk);
		Restart <= '1';
		wait until rising_edge(Clk);
		Restart <= '0';
		-- Apply Inputs
		file_open(fSig, FileFolder_c & "/" & SinCosFile, read_mode); --only required for determining the number of samples
		wait until rising_edge(Clk);
		for i in 0 to 10 loop -- if first 10 samples are corred, we can assume the restart worked			
			InVld <= '1';	
			wait until rising_edge(Clk);
			for i in 0 to IdleCycles_g-1 loop
				InVld <= '0';
				wait until rising_edge(Clk);
			end loop;			
		end loop;
		InVld <= '0';
		file_close(fSig);
		wait until rising_edge(Clk);		
		wait until ResponseDone = 1;		
		
		-- TB done
		wait for 1 us;
		TbRunning <= false;
		wait;
	end process;
	
	p_check : process
		file fSinCos		: text;
		variable ln	 		: line;
		variable Spl		: integer;	
		variable idx		: integer := 0;
	begin
		-- *** Case 0: Bittrueness ***
		wait until TestCase = 0;
		-- Open files
		file_open(fSinCos, FileFolder_c & "/" & SinCosFile, read_mode);
		
		-- Check Outputs
		while not endfile(fSinCos) loop
			wait until rising_edge(Clk) and OutVld = '1';
			CheckOutput(fSinCos, OutSin, OutCos, idx);		
			idx := idx + 1;
		end loop;			
		
		-- Close Files
		file_close(fSinCos);
		ResponseDone <= 0;
		
		-- *** Case 1: Restart ***
		wait until TestCase = 1;
		-- Open files
		file_open(fSinCos, FileFolder_c & "/" & SinCosFile, read_mode);
		
		-- Check Outputs
		idx := 0;
		for i in 0 to 10 loop -- if first 10 samples are corred, we can assume the restart worked
			wait until rising_edge(Clk) and OutVld = '1';
			CheckOutput(fSinCos, OutSin, OutCos, idx);		
			idx := idx + 1;
		end loop;		
		
		-- Close Files
		file_close(fSinCos);
		ResponseDone <= 1;		
	
		-- TB done
		wait;
	end process;
	
	

end sim;
