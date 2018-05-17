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
entity psi_fix_lin_approx_sin18b_dual_tb is
	generic (
		StimuliDir_g		: string		:= "../testbench/psi_fix_lin_approx_tb/sin18b"
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture sim of psi_fix_lin_approx_sin18b_dual_tb is

	-- constants
	constant InFmt_c		: PsiFixFmt_t		:= (0, 0, 20);
	constant OutFmt_c		: PsiFixFmt_t		:= (1, 0, 17);
	constant ClkPeriod_c	: time				:= 10 ns;

	-- Signals
	signal Clk			: std_logic												:= '0';
	signal Rst			: std_logic												:= '1';
	signal InVldA		: std_logic												:= '0';
	signal InDataA		: std_logic_vector(PsiFixSize(InFmt_c)-1 downto 0)		:= (others => '0');
	signal InVldB		: std_logic												:= '0';
	signal InDataB		: std_logic_vector(PsiFixSize(InFmt_c)-1 downto 0)		:= (others => '0');
	signal OutVldA		: std_logic												:= '0';
	signal OutDataA		: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0)		:= (others => '0');
	signal OutVldB		: std_logic												:= '0';
	signal OutDataB		: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0)		:= (others => '0');
	
	-- Tb Signals
	signal TbRunning	: boolean	:= true;
	
begin

	i_dut : entity work.psi_fix_lin_approx_sin18b_dual 
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Input
			InVldA		=> InVldA,
			InDataA		=> InDataA,
			InVldB		=> InVldB,
			InDataB		=> InDataB,
			-- Output
			OutVldA		=> OutVldA,
			OutDataA	=> OutDataA,
			OutVldB		=> OutVldB,
			OutDataB	=> OutDataB
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
	
	p_chb : process(Clk)
	begin
		if rising_edge(Clk) then
			InVldB <= InVldA;
			InDataB <= InDataA;
		end if;
	end process;
	
	p_stimuli : process
	begin
		Rst <= '1';
		-- Remove reset
		wait for 1 us;
		wait until rising_edge(Clk);
		Rst <= '0';
		wait for 1 us;
		
		-- Apply StimuliDir_g		
		appy_textfile_content(	Clk 		=> Clk, 
								Rdy 		=> PsiTextfile_SigOne,
								Vld 		=> InVldA, 
								Data(0)		=> InDataA, 
								Filepath	=> StimuliDir_g & "/stimuli.txt", 
								ClkPerSpl	=> 1);
		
		-- Finish
		wait for 1 us;
		Rst <= '1';
		TbRunning <= False;
		wait;
	end process;
	
	p_response_a : process
	begin
	
		check_textfile_content(	Clk			=> Clk,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> OutVldA,
								Data(0)		=> OutDataA,
								Filepath	=> StimuliDir_g & "/response.txt");


		wait;
	end process;
	
	p_response_b : process
	begin
	
		check_textfile_content(	Clk			=> Clk,
								Rdy			=> PsiTextfile_SigUnused,
								Vld			=> OutVldB,
								Data(0)		=> OutDataB,
								Filepath	=> StimuliDir_g & "/response.txt");


		wait;
	end process;	
	

end sim;