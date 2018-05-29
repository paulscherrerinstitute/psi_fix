------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library psi_tb;
	use psi_tb.psi_tb_txt_util.all;
	use work.psi_fix_pkg.all;
	
library std;
	use std.textio.all;

entity psi_fix_cordic_abs_pl_tb is
	generic (
		DataDir_g			: string	:= "../testbench/psi_fix_cordic_abs_pl_tb/Data";
		PipelineFactor_g	: natural	:= 1
	);
end entity psi_fix_cordic_abs_pl_tb;

architecture sim of psi_fix_cordic_abs_pl_tb is

	-------------------------------------------------------------------------
	-- Constants
	-------------------------------------------------------------------------
	constant InFmt_c				: PsiFixFmt_t	:= (1, 0, 15);
	constant OutFmt_c				: PsiFixFmt_t	:= (0, 1, 17);
	constant InternalFmt_c			: PsiFixFmt_t	:= (1, 1, 20);
	constant Iterations_c			: integer		:= 13;
	constant CordicGain_c			: real			:= 1.64674;
	
	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant 	ClockFrequency_c	: real 		:= 100.0e6;
	constant	ClockPeriod_c		: time		:= (1 sec)/ClockFrequency_c;
	signal 		TbRunning			: boolean 	:= True;
	

	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal Clk						: std_logic		:= '0';
	signal Rst						: std_logic		:= '1';
	signal InVld					: std_logic		:= '0';
	signal InI, InQ					: std_logic_vector(PsiFixSize(InFmt_c)-1 downto 0);
	signal OutVld					: std_logic;
	signal OutAbs					: std_logic_vector(PsiFixSize(OutFmt_c)-1 downto 0);

	-------------------------------------------------------------------------
	-- Procedure
	-------------------------------------------------------------------------	
	procedure CheckReal(	expected : real;
							actual : real;
							tolerance : real;
							msg : string) is
	begin
		assert (actual < expected+tolerance) and (actual > expected-tolerance)
			report "###ERROR***: " & msg & " expected: " & real'image(expected) & ", received: " & real'image(actual)
			severity error;
	end procedure;

	

begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.psi_fix_cordic_abs_pl
		generic map (
			InFmt_g				=> InFmt_c,
			OutFmt_g			=> OutFmt_c,
			InternalFmt_g		=> InternalFmt_c,
			Iterations_g		=> Iterations_c,
			PipelineFactor_g	=> PipelineFactor_g
		)
		port map (
			Clk			=> Clk,
			Rst			=> Rst,
			InVld		=> InVld,
			InI			=> InI,
			InQ			=> InQ,
			OutVld		=> OutVld,
			OutAbs		=> OutAbs
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
		file fIn 		: text;
		file fOut 		: text;
		variable r 		: line;
		variable iI		: integer;
		variable iQ		: integer;
		variable resp	: integer;
		variable idx	: integer := 0;
	begin
		-- Reset
		Rst <= '1';
		wait for 1 us;
		Rst <= '0';
		wait for 1 us;
		
		-- Check initial state
		assert OutVld = '0' report "###ERROR###: Initial state of output valid is high" severity error;
		
		-- Single samples in each quadrant
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.3, InFmt_c);
		InQ <= PsiFixFromReal(0.4, InFmt_c);
		InVld <= '1';
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.0, InFmt_c);
		InQ <= PsiFixFromReal(0.0, InFmt_c);
		InVld <= '0';
		wait until rising_edge(Clk) and OutVld = '1';
		CheckReal(sqrt((0.3**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Output 0");
		
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.5, InFmt_c);
		InQ <= PsiFixFromReal(-0.4, InFmt_c);
		InVld <= '1';
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.0, InFmt_c);
		InQ <= PsiFixFromReal(0.0, InFmt_c);
		InVld <= '0';
		wait until rising_edge(Clk) and OutVld = '1';
		CheckReal(sqrt((0.5**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Output 1");		
		
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(-0.9, InFmt_c);
		InQ <= PsiFixFromReal(-0.4, InFmt_c);
		InVld <= '1';
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.0, InFmt_c);
		InQ <= PsiFixFromReal(0.0, InFmt_c);
		InVld <= '0';
		wait until rising_edge(Clk) and OutVld = '1';
		CheckReal(sqrt((0.9**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Output 2");		

		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(-0.9, InFmt_c);
		InQ <= PsiFixFromReal(0.4, InFmt_c);
		InVld <= '1';
		wait until rising_edge(Clk);
		InI <= PsiFixFromReal(0.0, InFmt_c);
		InQ <= PsiFixFromReal(0.0, InFmt_c);
		InVld <= '0';
		wait until rising_edge(Clk) and OutVld = '1';
		CheckReal(sqrt((0.9**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Output 3");	

		-- Test burst operation
		if PipelineFactor_g < 13 then		-- This test case does not work for fully parallel implementation since first results are already output when next inputs are provided.
			wait until rising_edge(Clk);
			InVld <= '1';
			InI <= PsiFixFromReal(0.3, InFmt_c);
			InQ <= PsiFixFromReal(0.4, InFmt_c);
			wait until rising_edge(Clk);
			InI <= PsiFixFromReal(0.5, InFmt_c);
			InQ <= PsiFixFromReal(-0.4, InFmt_c);
			wait until rising_edge(Clk);
			InI <= PsiFixFromReal(-0.9, InFmt_c);
			InQ <= PsiFixFromReal(-0.4, InFmt_c);
			wait until rising_edge(Clk);
			InI <= PsiFixFromReal(-0.9, InFmt_c);
			InQ <= PsiFixFromReal(0.35, InFmt_c);
			wait until rising_edge(Clk);
			InVld <= '0';
			wait until rising_edge(Clk) and OutVld = '1';
			CheckReal(sqrt((0.3**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Burst Output 0");
			wait until rising_edge(Clk);
			assert OutVld = '1' report "###ERROR###: Output was not burst";
			CheckReal(sqrt((0.5**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Burst Output 1");
			wait until rising_edge(Clk);
			assert OutVld = '1' report "###ERROR###: Output was not burst";
			CheckReal(sqrt((0.9**2.0)+(0.4**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Burst Output 2");
			wait until rising_edge(Clk);
			assert OutVld = '1' report "###ERROR###: Output was not burst";
			CheckReal(sqrt((0.9**2.0)+(0.35**2.0))*CordicGain_c, PsiFixtoReal(OutAbs, OutFmt_c), 0.01, "Burst Output 3");
			wait until rising_edge(Clk);
			assert OutVld = '0' report "###ERROR###: Burst was not ended";
		end if;
		
		-- Test file content (bittrueness)
		file_open(fIn, DataDir_g & "/input.txt",read_mode);
		file_open(fOut, DataDir_g & "/output.txt",read_mode);
		while not endfile(fIn) loop
			readline(fIn,r);
			read(r, iI);
			read(r, iQ);
			readline(fOut,r);
			read(r, resp);
			wait until rising_edge(Clk);
			InI <= std_logic_vector(to_signed(iI, InI'length));
			InQ <= std_logic_vector(to_signed(iQ, InQ'length));
			InVld <= '1';
			wait until rising_edge(Clk);
			InI <= PsiFixFromReal(0.0, InFmt_c);
			InQ <= PsiFixFromReal(0.0, InFmt_c);
			InVld <= '0';
			wait until rising_edge(Clk) and OutVld = '1';
			assert to_integer(unsigned(OutAbs)) = resp 
				report 	"###ERROR###: received wrong output, sample " & integer'image(idx) & 
						"[exp " & integer'image(resp) & 
						", got " & integer'image(to_integer(unsigned(OutAbs))) & "]"
				severity error;
			idx := idx+1;
		end loop;
		file_close(fIn);
		file_close(fOut);	

		
		-- TB done
		TbRunning <= false;
		wait;
	end process;


end sim;
