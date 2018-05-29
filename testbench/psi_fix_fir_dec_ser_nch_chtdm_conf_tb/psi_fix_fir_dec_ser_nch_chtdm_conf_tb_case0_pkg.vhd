------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library std;
	use std.textio.all;
	
library psi_tb;
	use psi_tb.psi_tb_txt_util.all;
	use work.psi_fix_fir_dec_ser_nch_chtdm_conf_tb_pkg.all;
	use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg is

	constant CaseName_c : string := "Impulse Response";

	procedure run(	signal 	Config 		: out 	Config_t;
					signal 	CoefIf		: out 	CoefIn_t;
					signal 	InSig		: out 	In_t;
					signal	RdCoef		: in	std_logic_vector;
					signal 	Clk			: in 	std_logic;
							DutyCycle	: in	natural);
							
	procedure check(	signal 	OutSig		: in 	Out_t;
						signal 	Clk			: in 	std_logic);							
					
end psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg is

	procedure run(	signal 	Config 		: out 	Config_t;
					signal 	CoefIf		: out 	CoefIn_t;
					signal 	InSig		: out 	In_t;
					signal	RdCoef		: in	std_logic_vector;
					signal 	Clk			: in 	std_logic;
							DutyCycle	: in	natural) is

	begin
		-- Print Message
		print("Test: " & CaseName_c);
		
		-- Configure
		wait until rising_edge(Clk);
		Config.Ratio	<= std_logic_vector(to_unsigned(3-1, Config.Ratio'length));
		Config.Taps		<= std_logic_vector(to_unsigned(7-1, Config.Taps'length));
		wait until rising_edge(Clk);
		
		-- Setup coefficients and check if they can be read back
		for i in 0 to 6 loop
			WriteCoef(i, 0.5/2**i, CoefIf, Clk);
		end loop;
		for i in 0 to 6 loop
			CheckCoef(i, 0.5/2**i, RdCoef, CoefIf, Clk);
		end loop;
		
		-- Inject Zeros
		wait until rising_edge(Clk);
		-- Inject 0.5 on channel 0
		InSig.Vld 		<= '1';
		InSig.Data	<= PsiFixFromReal(0.0, InFmt_c);		
		for i in 0 to DutyCycle loop
			wait until rising_edge(Clk);
			InSig.Vld 	<= '0';
			InSig.Data	<= (others => '0');
		end loop;	
		-- channel 1 stays zero
		InSig.Vld 		<= '1';
		InSig.Data		<= PsiFixFromReal(0.5, InFmt_c);
		for i in 0 to DutyCycle loop
			wait until rising_edge(Clk);
			InSig.Vld 	<= '0';
			InSig.Data	<= (others => '0');
		end loop;	
		-- trailing zeros	
		InSig.Data	<=  (others => '0');
		for i in 0 to 30 loop
			for ch in 0 to 1 loop
				InSig.Vld 	<= '1';
				for i in 0 to DutyCycle loop
					wait until rising_edge(Clk);
					InSig.Vld 	<= '0';
				end loop;
			end loop;
		end loop;			
		
	end procedure;
	
	procedure check(	signal 	OutSig		: in 	Out_t;
						signal 	Clk			: in 	std_logic) is
	begin
		CheckOut((0.0, 0.5*0.5), OutSig, Clk);
		CheckOut((0.0, 0.5/2**3*0.5), OutSig, Clk);
		CheckOut((0.0, 0.5/2**6*0.5), OutSig, Clk);
		CheckOut((0.0, 0.0), OutSig, Clk);
	end procedure;
	
	
end psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg;

