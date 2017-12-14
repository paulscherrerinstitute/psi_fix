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
	
	p_stimuli : process
		file 		f 		: text;
		variable 	l 		: line;
		variable 	s 		: integer;
		variable	slast	: integer;
		variable 	i 		: integer := 0;
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
		InVldA <= '1';
		while not endfile(f) loop
			readline(f, l);
			read(l, s);
			InDataA <= PsiFixFromBitsAsInt(s, InFmt_c);
			if i >= 1 then
				InDataB <= PsiFixFromBitsAsInt(slast, InFmt_c);
				InVldB <= '1';
			end if;
			wait until rising_edge(Clk);
			i := i+1;
			slast := s;
		end loop;
		InVldA <= '0';
		InVldB <= '0';
		file_close(f);
		
		-- Finish
		wait for 1 us;
		Rst <= '1';
		TbRunning <= False;
		wait;
	end process;
	
	p_response : process
		file 		f 		: text;
		variable 	l 		: line;
		variable 	s 		: integer;
		variable	slast 	: integer;
		variable	i 		: integer := 0;
		variable    e 		: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0);
	begin
		
		-- Apply StimuliDir_g
		file_open(f, StimuliDir_g & "/response.txt");
		while not endfile(f) loop
			wait until OutVldA = '1' and rising_edge(Clk);
			readline(f, l);
			read(l, s);
			e := PsiFixFromBitsAsInt(s, OutFmt_c);
			assert e = OutDataA report "###ERROR###: Received wrong data ChA in sample " & integer'image(i) &
									   " (got " & integer'image(to_integer(signed(OutDataA))) &
									   " expected " & integer'image(to_integer(signed(e))) & ")" severity error;
			if i >= 1 then
				assert OutVldB = '1' report "###ERRROR###: ChannelB not valid" severity error;
				e := PsiFixFromBitsAsInt(slast, OutFmt_c);
				assert e = OutDataB report "###ERROR###: Received wrong data ChB in sample " & integer'image(i) &
										   " (got " & integer'image(to_integer(signed(OutDataB))) &
									       " expected " & integer'image(to_integer(signed(e))) & ")" severity error;
			end if;
			i := i + 1;
			slast := s;
		end loop;
		file_close(f);
		
		-- Finish
		wait;
	end process;
	

end sim;