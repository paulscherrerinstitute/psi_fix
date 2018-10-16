------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_textfile_pkg.all;

entity psi_fix_lut_gen_tb is
	generic(FileFolder_g : string := "../testbench/psi_fix_lut_gen_tb/Data");
end entity;

architecture tb of psi_fix_lut_gen_tb is

	constant clk_freq_c : real := 100.0E6;
	constant period_c   : time := (1 sec)/clk_freq_c;

	constant data_fmt_c   : PsiFixFmt_t := (1, 0, 15);
	signal tb_run         : boolean     := true;
	signal clk_sti        : std_logic   := '0';
	signal rst_sti        : std_logic;
	signal radd_sti       : std_logic_vector(log2ceil(61) - 1 downto 0);
	signal rena_sti       : std_logic   := '0';
	signal data_obs       : std_logic_vector(PsiFixSize((data_fmt_c)) - 1 downto 0);
	signal process_done_s : std_logic   := '0';
	signal SigOut		  : TextfileData_t(0 to 0) := (others => 0);		
begin
	--clock process
	proc_ck : process
	begin
		while tb_run loop
			clk_sti <= not clk_sti;
			wait for period_c/2;
			clk_sti <= not clk_sti;
			wait for period_c/2;
		end loop;
		wait;
	end process;

	SigOut(0) <= to_integer(signed(data_obs));
	p_check : process
	begin
		-- start of process !DO NOT EDIT
		wait until rst_sti = '0';
		-- Check
		CheckTextfileContent(  Clk         => clk_sti,
		                       Rdy         => PsiTextfile_SigUnused,
		                       Vld         => rena_sti,
		                       Data        => SigOut,
		                       Filepath    => (FileFolder_g & "/model.txt"),
		                       IgnoreLines => 1);
		process_done_s <= '1';
	end process;

	process(clk_sti)
		variable count_v : integer range 0 to 61 := 0;
	begin
		if rising_edge(clk_sti) then
			--	rena_dff_sti <= rena_sti;
			if rena_sti = '1' then
				if count_v < 60 then
					count_v := count_v + 1;
				else
					count_v := 0;
				end if;
			end if;
		end if;
		radd_sti <= std_logic_vector(to_unsigned(count_v, radd_sti'length));
	end process;

	--insert your DUT
	inst_dut : entity work.psi_fix_lut_test1
		generic map(rst_pol_g   => '1',
		            rom_stlye_g => "block")
		port map(InClk   => clk_sti,
		         InRst   => rst_sti,
		         InRdAdd => radd_sti,
		         InRdEna => rena_sti,
		         OutDat  => data_obs);

	proc_stim : process
		--	variable count_v : integer range 0 to 5 := 0;
	begin
		tb_run   <= true;
		rst_sti  <= '1';
		wait for 10* period_c;
		rst_sti  <= '0';
		rena_sti <= '1';
		while process_done_s = '0' loop
			wait until unsigned(radd_sti) = to_unsigned(60, radd_sti'length);
			--count_v := count_v + 1;
		end loop;
		tb_run   <= false;
		wait;
	end process;

end architecture;
