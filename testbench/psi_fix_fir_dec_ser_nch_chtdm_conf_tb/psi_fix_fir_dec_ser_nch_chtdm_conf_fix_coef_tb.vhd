------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Radoslaw Rybaniec
------------------------------------------------------------------------------

-- This testbench is only very brief and required only to check if the fixed coefficient
-- mode works. All bittrue tests are executed in the configurable TB.

-- Changelog
-- 28.02.2023 Added checking after multiple resets

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_fix_pkg.all;
	use work.psi_common_array_pkg.all;

entity psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb is
	generic (
		TestRamInit_g : boolean := false
	);
end entity psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb;

architecture sim of psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb is
	
	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant ClockFrequency_c	: real		:= 100.0e6;
	constant ClockPeriod_c		: time		:= (1 sec)/ClockFrequency_c;
	signal TbRunning			: boolean 	:= True;
	signal ResponseDone			: boolean	:= False;
	
	constant CoefFmt_c			: PsiFixFmt_t	:= (1, 0, 15);
	constant DataFmt_c			: PsiFixFmt_t	:= (1, 0, 15);
	
	constant Coefs_c			: t_areal(0 to 9)	:= (1.0/2.0**8.0, 2.0/2.0**8.0, 3.0/2.0**8.0, 4.0/2.0**8.0,
														5.0/2.0**8.0, 6.0/2.0**8.0, 7.0/2.0**8.0, 8.0/2.0**8.0, 
														9.0/2.0**8.0, 10.0/2.0**8.0);
    signal noise_sig : std_logic:='0';
    
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal Clk		: std_logic												:= '0';
	signal Rst		: std_logic												:= '1';
	signal InVld	: std_logic												:= '0';
	signal InData	: std_logic_vector(PsiFixSize(DataFmt_c)-1 downto 0)	:= (others => '0');
	signal OutVld	: std_logic												:= '0';
	signal OutData	: std_logic_vector(PsiFixSize(DataFmt_c)-1 downto 0)	:= (others => '0');


begin


	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.psi_fix_fir_dec_ser_nch_chtdm_conf
		generic map (
			InFmt_g				=> DataFmt_c,
			OutFmt_g			=> DataFmt_c,
			CoefFmt_g			=> CoefFmt_c,
			Channels_g			=> 2,
			MaxRatio_g			=> 3,
			MaxTaps_g			=> 10,
			Rnd_g				=> PsiFixTrunc,
			Sat_g				=> PsiFixSat,
			UseFixCoefs_g		=> not TestRamInit_g,
			Coefs_g				=> Coefs_c
		)
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
	p_control : process(Clk, Rst) is
      variable v_cnt : integer := 0;
	begin
      if Rst = '1' then
        v_cnt := 0;
      elsif rising_edge(Clk) then
        -- Apply Input
       
        case v_cnt is
          when 0 =>
            InVld 	<= '1'; 
            InData	<= PsiFixFromReal(0.5, DataFmt_c);
          when 1 =>
            InVld 	<= '0';
          when 4 =>
            InVld 	<= '1';
            InData	<= PsiFixFromReal(0.0, DataFmt_c);
          when 300 =>
            assert ResponseDone report "###ERROR###: Response aquisition not completed" severity error;
            TbRunning <= false;
          when others =>
            InVld <= '0';
        end case;

        if v_cnt mod 4 = 0 then
          InVld 	<= '1';
        else
          InVld 	<= '0';
        end if;
        
        v_cnt := v_cnt + 1;
      end if;
        
	end process;
	
	p_check : process(Clk, Rst) is
      variable v_cnt : integer := 0;
	begin

      if Rst = '1' then
        v_cnt := 0;
        ResponseDone <= False;
      elsif rising_edge(Clk) and OutVld = '1' then
        
        case v_cnt is
          when 0 =>
            assert OutData = PsiFixFromReal(0.5*Coefs_c(0), DataFmt_c) report "###ERROR###: Wrong CH0 output 0" severity error;
          when 1 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 0" severity error;
          when 2 => assert OutData = PsiFixFromReal(0.5*Coefs_c(3), DataFmt_c) report "###ERROR###: Wrong CH0 output 1" severity error;
          when 3 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 1" severity error;
          when 4 => assert OutData = PsiFixFromReal(0.5*Coefs_c(6), DataFmt_c) report "###ERROR###: Wrong CH0 output 2" severity error;
          when 5 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 2" severity error;
          when 6 => assert OutData = PsiFixFromReal(0.5*Coefs_c(9), DataFmt_c) report "###ERROR###: Wrong CH0 output 3" severity error;
          when 7 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 3" severity error;
          when 8 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH0 output 4" severity error;
          when 9 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 4" severity error;
          when 10 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH0 output 5" severity error;
          when 11 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH1 output 5" severity error;
          when 12 => assert OutData = PsiFixFromReal(0.0, DataFmt_c) report "###ERROR###: Wrong CH0 output 6" severity error;
          when 15 =>
          -- TB done
            ResponseDone <= True;
          when others => null;
        end case;
        v_cnt := v_cnt + 1;    
      end if;

    
    end process;
	
    process
    begin
      for rst_cnt in 0 to 3 loop
        Rst <= '1';
        wait for 10 ns;
        Rst <= '0';
        wait for 2 us;
      end loop;
      wait;
    end process;

end sim;
