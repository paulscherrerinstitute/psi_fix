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
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity <ENTITY_NAME>_tb is
	generic (
		StimuliDir_g		: string		:= "../testbench/psi_fix_lin_approx_tb/sin18b"
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture sim of <ENTITY_NAME>_tb is

	-- constants
	constant InFmt_c		: PsiFixFmt_t		:= <IN_FMT>;
	constant OutFmt_c		: PsiFixFmt_t		:= <OUT_FMT>;
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
	
	
begin

	i_dut : entity work.<ENTITY_NAME> 
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
	
	p_stimuli : process
		file 		f : text;
		variable 	l : line;
		variable 	s : integer;
	begin
		Rst <= '1';
		-- Remove reset
		wait for 1 us;
		wait until rising_edge(Clk);
		Rst <= '0';
		wait for 1 us;
		
		-- Apply StimuliDir_g
		file_open(f, StimuliDir_g & "/stimuli.txt");
		wait until rising_edge(Clk);
		InVld <= '1';
		while not endfile(f) loop
			readline(f, l);
			read(l, s);
			InData <= PsiFixFromBitsAsInt(s, InFmt_c);
			wait until rising_edge(Clk);
		end loop;
		InVld <= '0';
		file_close(f);
		
		-- Finish
		wait for 1 us;
		Rst <= '1';
		TbRunning <= False;
		wait;
	end process;
	
	p_response : process
		file 		f : text;
		variable 	l : line;
		variable 	s : integer;
		variable	i : integer := 0;
		variable    e : std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0);
	begin
		
		-- Apply StimuliDir_g
		file_open(f, StimuliDir_g & "/response.txt");
		while not endfile(f) loop
			wait until OutVld = '1' and rising_edge(Clk);
			readline(f, l);
			read(l, s);
			e := PsiFixFromBitsAsInt(s, OutFmt_c);
			assert e = OutData report "###ERROR###: Received wrong data in sample " & integer'image(i) &
									  " (got " & integer'image(to_integer(signed(OutData))) &
									  " expected " & integer'image(to_integer(signed(e))) & ")" severity error;
			i := i + 1;
		end loop;
		file_close(f);
		
		-- Finish
		wait;
	end process;
	

end sim;