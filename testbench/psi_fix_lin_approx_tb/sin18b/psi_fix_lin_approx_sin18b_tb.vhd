------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library std;
	use std.textio.all;
	
library work;
	use work.psi_fix_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_tb_textfile_pkg.all;	
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_fix_lin_approx_sin18b_tb is
	generic (
		StimuliDir_g		: string		:= "../testbench/psi_fix_lin_approx_tb/sin18b"
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture sim of psi_fix_lin_approx_sin18b_tb is

	-- constants
	constant InFmt_c		: PsiFixFmt_t		:= (0, 0, 20);
	constant OutFmt_c		: PsiFixFmt_t		:= (1, 0, 17);
	constant ClkPeriod_c	: time				:= 10 ns;

	-- Signals
	signal Clk			: std_logic												:= '0';
	signal Rst			: std_logic												:= '1';
	signal InVld		: std_logic												:= '0';
	signal InData		: std_logic_vector(PsiFixSize(InFmt_c)-1 downto 0)		:= (others => '0');
	signal OutVld		: std_logic												:= '0';
	signal OutData		: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0)		:= (others => '0');
	
	-- Tb Signals
	signal TbRunning	: boolean	:= true;
	signal SigIn		: TextfileData_t(0 to 0) := (others => 0);
	signal SigOut		: TextfileData_t(0 to 0) := (others => 0);
	
	
begin

	i_dut : entity work.psi_fix_lin_approx_sin18b 
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Input
			InVld		=> InVld,
			InData		=> InData,
			-- Output
			OutVld		=> OutVld,
			OutData		=> OutData
		);

	p_clk : process
	begin
		Clk <= '0';
		while TbRunning loop
			wait for ClkPeriod_c/2;
			Clk <= '1';
			wait for ClkPeriod_c/2;
			Clk <= '0';
		end loop;
		wait;
	end process;
	
	InData <= std_logic_vector(to_unsigned(SigIn(0), InData'length));
	p_stimuli : process
	begin
		Rst <= '1';
		-- Remove reset
		wait for 1 us;
		wait until rising_edge(Clk);
		Rst <= '0';
		wait for 1 us;
		
		-- Apply StimuliDir_g
		ApplyTextfileContent(	Clk 		=> Clk, 
								Rdy 		=> PsiTextfile_SigOne,
								Vld 		=> InVld, 
								Data		=> SigIn, 
								Filepath	=> StimuliDir_g & "/stimuli.txt", 
								ClkPerSpl	=> 1);		
		
		-- Finish
		wait for 1 us;
		Rst <= '1';
		TbRunning <= False;
		wait;
	end process;

	SigOut(0) <= to_integer(signed(OutData));
	p_response : process
	begin
		
		-- Check
		CheckTextfileContent(	Clk			=> Clk,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> OutVld,
								Data		=> SigOut,
								Filepath		=> StimuliDir_g & "/response.txt");
		
		-- Finish
		wait;
	end process;
	

end sim;