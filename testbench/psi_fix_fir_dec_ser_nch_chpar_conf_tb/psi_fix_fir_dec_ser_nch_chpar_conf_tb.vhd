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
	use work.psi_tb_txt_util.all;
	use work.psi_fix_pkg.all;
	use work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg.all;
	use work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.all;
	use work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.all;

entity psi_fix_fir_dec_ser_nch_chpar_conf_tb is
	generic (
		DutyCycle_g		: natural		:= 32;
		StimuliPath_g	: string		:= "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Data";
		RamBehavior_g	: string		:= "RBW"
	);
end entity psi_fix_fir_dec_ser_nch_chpar_conf_tb;

architecture sim of psi_fix_fir_dec_ser_nch_chpar_conf_tb is
	
	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant ClockFrequency_c	: real		:= 100.0e6;
	constant ClockPeriod_c		: time		:= (1 sec)/ClockFrequency_c;
	signal TbRunning			: boolean 	:= True;
	signal TestCase				: integer	:= -1;	
	signal ResponseDone			: integer := -1;

	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal Clk		: std_logic			:= '0';
	signal Rst		: std_logic			:= '1';
	signal SigIn	: In_t				:= (Vld => '0',
											Data => (Others => (others => '0')));
	signal SigOut	: Out_t				:= (Vld => '0',
											Data => (Others => (others => '0')));
	signal Config 	: Config_t			:= (others => (others => '0'));	
	signal CoefIn	: CoefIn_t			:= (	Wr => '0',
												Addr => (others => '0'),
												Data => (others => '0'));
	signal CoefOut	: std_logic_vector(PsiFixSize(CoefFmt_c)-1 downto 0);
	
	signal InDataDut	: std_logic_vector(PsiFixSize(InFmt_c)*Channels_c-1 downto 0);
	signal OutDataDut	: std_logic_vector(PsiFixSize(OutFmt_c)*Channels_c-1 downto 0);


begin


	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	g_array : for i in 0 to Channels_c-1 generate
		InDataDut(PsiFixSize(InFmt_c)*(i+1)-1 downto PsiFixSize(InFmt_c)*i) <= SigIn.Data(i);
		SigOut.Data(i) <= OutDataDut(PsiFixSize(OutFmt_c)*(i+1)-1 downto PsiFixSize(OutFmt_c)*i);
	end generate;
	
	i_dut : entity work.psi_fix_fir_dec_ser_nch_chpar_conf
		generic map (
			InFmt_g				=> InFmt_c,
			OutFmt_g			=> OutFmt_c,
			CoefFmt_g			=> CoefFmt_c,
			Channels_g			=> Channels_c,
			MaxRatio_g			=> MaxRatio_c,
			MaxTaps_g			=> MaxTaps_c,
			Rnd_g				=> PsiFixRound,
			Sat_g				=> PsiFixSat,
			RamBehavior_g		=> RamBehavior_g
		)
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Input
			InVld		=> SigIn.Vld,
			InData		=> InDataDut,
			-- Output
			OutVld		=> SigOut.Vld,
			OutData		=> OutDataDut,
			-- Parallel Configuration Interface
			Ratio		=> Config.Ratio,
			Taps		=> Config.Taps,
			-- Coefficient interface
			CoefClk		=> Clk,
			CoefWr		=> CoefIn.Wr,
			CoefAddr	=> CoefIn.Addr,
			CoefWrData	=> CoefIn.Data,
			CoefRdData	=> CoefOut
		);
	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_pclk : process
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
	begin
		-- Reset
		Rst <= '1';
		wait for 1 us;
		wait until rising_edge(Clk);
		Rst <= '0';
		wait for 1 us;
		
		-- Test Cases
		TestCase <= 0;
		work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.run(Config, CoefIn, SigIn, CoefOut, Clk, DutyCycle_g);
		if ResponseDone /= 0 then
			wait until ResponseDone = 0;
		end if;
		
		wait until rising_edge(Clk);
		Rst <= '1';
		wait until rising_edge(Clk);
		Rst <= '0';
		TestCase <= 1;
		work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.run(Config, CoefIn, SigIn, Clk, DutyCycle_g, StimuliPath_g);
		if ResponseDone /= 1 then
			wait until ResponseDone = 1;
		end if;		
		
		-- TB done
		TbRunning <= false;
		wait;
	end process;
	
	p_check : process
	begin
		-- Test Cases
		if TestCase /= 0 then
			wait until TestCase = 0;
		end if;
		work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.check(SigOut, Clk);
		ResponseDone <= 0;
		
		if TestCase /= 1 then
			wait until TestCase = 1;
		end if;
		work.psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.check(SigOut, Clk, StimuliPath_g);
		ResponseDone <= 1;		
		
		-- TB done
		wait;
	end process;
	
	

end sim;
