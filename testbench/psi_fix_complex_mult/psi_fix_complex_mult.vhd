--=================================================================
--	Paul Scherrer Institut <PSI> Villigen, Schweiz
-- 	Copyright ©, 2018, Benoit STEF, all rights reserved 
--=================================================================
-- unit		: psi_fix_complex_mult_tb(tb)
-- file		: psi_fix_complex_mult_tb.vhd
-- project	: PSI Fixed Point Elemental Tb
-- Author	:  stef_b - 8221 DSV group WBBA/302
--					  benoit.stef@psi.ch
--					  PSI Aarebrücke
--					  CH-5232 Villigen - Switzerland
-- purpose	: Tb for psi_fix_matrix_rotation_2D
-- SIM tool	: Modelsim SE 10.6
-- EDA tool	: Xilinx ISE 13.4
-- Target	: Xilinx FPGA Virtex-6  - xc6vlx130t-1fff1156 
-- misc		:
-- date		: 08.05.2018
--=================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library psi_fix;
use psi_fix.psi_fix_pkg.all;

entity psi_fix_complex_mult_tb is
	generic(freq_clock_g     : real    := 100.0e6;	--frequency clock
	        angle_g          : real    := 90.0;	--same as python model
	        Pipeline_g       : boolean := True;	--set pipeline
	        inp_txt_stim_g   : string  := "..\Scripts\stimuli_inphase.txt";
	        qua_txt_stim_g   : string  := "..\Scripts\stimuli_quadrature.txt";
	        rotInp_txt_obs_g : string  := "..\Scripts\model_result_rotX.txt";
	        rotQua_txt_obs_g : string  := "..\Scripts\model_result_rotY.txt"
	       );
end entity;

architecture tb of psi_fix_complex_mult_tb is
	-- Format definition
	constant InFixFmt_c    : PsiFixFmt_t := (1, 1, 15); --same as python model
	constant CoefFixFmt_c  : PsiFixFmt_t := (1, 1, 15); --same as python model
	constant OutFmt_c      : PsiFixFmt_t := (1, 1, 15); --same as python model
	constant InternalFmt_c : PsiFixFmt_t := (1, 2, 30); --same as python model

	--typedef for next function
	type matrix_array_t is array (0 to 3) of std_logic_vector(PsiFixSize(CoefFixFmt_c) - 1 downto 0);

	--function to compute coef
	function angle_matrix(constant angle     : real; --in degree
	                      constant amplitude : real; --in SI
	                      constant scale     : real; --360.0 <=> SLV equivalent
	                      constant fmt       : PsiFixFmt_t) return matrix_array_t is --format
		variable array_v : matrix_array_t;
		constant theta   : real := angle/180.0*MATH_PI;
	begin
		array_v(0) := std_logic_vector(to_signed(integer(amplitude*scale*COS(theta)), PsiFixSize(fmt)));
		array_v(1) := std_logic_vector(to_signed(integer(amplitude*scale*SIN(theta)), PsiFixSize(fmt)));
		array_v(2) := std_logic_vector(to_signed(integer(amplitude*scale*(SIN(theta))), PsiFixSize(fmt)));
		array_v(3) := std_logic_vector(to_signed(integer(amplitude*scale*COS(theta)), PsiFixSize(fmt)));
		return array_v;
	end function;

	--timedef
	constant period_c : time := (1 sec)/freq_clock_g;

	--internal signals definition
	signal clk_i        : std_logic      := '0';
	signal rst_i        : std_logic      := '1';
	signal data_ipath_i : std_logic_vector(PsiFixSize(InFixFmt_c) - 1 downto 0);
	signal data_qpath_i : std_logic_vector(PsiFixSize(InFixFmt_c) - 1 downto 0);
	--str can be modified if necessary here used as constant to 1
	constant str_i        : std_logic      := '1';
	constant coef_cmd_i : matrix_array_t := angle_matrix(angle_g, 1.0, 2.0**(CoefFixFmt_c.F), CoefFixFmt_c);

	--merge signal from DUT
	signal data_inphase_o    : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
	signal data_quadrature_o : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
	signal str_o             : std_logic;

	--Merge signal from file
	shared variable obs_ipath_s : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);
	shared variable obs_qpath_s : std_logic_vector(PsiFixSize(OutFmt_c) - 1 downto 0);

	shared variable count_mismatch  : integer := 0;
	shared variable count_mismatch2 : integer := 0;
begin

	clk_i <= not clk_i after period_c/2;
	
	------------------------------------------------------------------------
	-- Process to read inphase data STIMULI 
	-- TODO one procedure to read data file
	------------------------------------------------------------------------
	inp_stim_read_proc : process(rst_i, clk_i)
		constant NUM_COL_c          : integer := 1;
		type t_integer_array is array (integer range <>) of integer;
		file test_vector_f          : text open read_mode is inp_txt_stim_g;
		variable row                : line;
		variable v_data_read        : t_integer_array(1 to NUM_COL_c);
		variable v_data_row_counter : integer := 0;
	begin
		if rst_i = '1' then
			v_data_row_counter := 0;
			v_data_read        := (others => 0);
			------------------------------------
		elsif rising_edge(clk_i) then

			if str_i = '1' then
				if not endfile(test_vector_f) then
					v_data_row_counter := v_data_row_counter + 1;
					readline(test_vector_f, row);
				end if;

				-- read integer number from "row" variable in integer array
				for i in 1 to NUM_COL_c loop
					read(row, v_data_read(i));
				end loop;
				data_ipath_i <= std_logic_vector(to_signed(v_data_read(1), PsiFixSize(InFixFmt_c)));
			end if;
		end if;
	end process;

	------------------------------------------------------------------------
	-- Process to read quadrature data STIMULI
	------------------------------------------------------------------------
	qua_stim_read_proc : process(rst_i, clk_i)
		constant NUM_COL_c          : integer := 1;
		type t_integer_array is array (integer range <>) of integer;
		file test_vector_f          : text open read_mode is qua_txt_stim_g;
		variable row                : line;
		variable v_data_read        : t_integer_array(1 to NUM_COL_c);
		variable v_data_row_counter : integer := 0;
	begin
		if rst_i = '1' then
			v_data_row_counter := 0;
			v_data_read        := (others => 0);
			------------------------------------
		elsif rising_edge(clk_i) then

			if str_i = '1' then
				if not endfile(test_vector_f) then
					v_data_row_counter := v_data_row_counter + 1;
					readline(test_vector_f, row);
				end if;

				for i in 1 to NUM_COL_c loop
					read(row, v_data_read(i));
				end loop;
				data_qpath_i <= std_logic_vector(to_signed(v_data_read(1), PsiFixSize(InFixFmt_c)));
			end if;
		end if;
	end process;

	------------------------------------------------------------------------
	-- Process to read inphase data OBSERVABLE
	------------------------------------------------------------------------
	inp_obs_read_proc : process(rst_i, clk_i)
		constant NUM_COL_c          : integer := 1;
		type t_integer_array is array (integer range <>) of integer;
		file test_vector_f          : text open read_mode is rotInp_txt_obs_g;
		variable row                : line;
		variable v_data_read        : t_integer_array(1 to NUM_COL_c);
		variable v_data_row_counter : integer := 0;
	begin
		if rst_i = '1' then
			v_data_row_counter := 0;
			v_data_read        := (others => 0);
			------------------------------------
		elsif falling_edge(clk_i) then

			if str_o = '1' then
				if not endfile(test_vector_f) then
					v_data_row_counter := v_data_row_counter + 1;
					readline(test_vector_f, row);
				end if;

				for i in 1 to NUM_COL_c loop
					read(row, v_data_read(i));
				end loop;
				obs_ipath_s := std_logic_vector(to_signed(v_data_read(1), PsiFixSize(InFixFmt_c)));
			end if;
		end if;
	end process;

	------------------------------------------------------------------------
	-- Process to read quadrature data OBSERVABLE
	------------------------------------------------------------------------
	qua_obs_read_proc : process(rst_i, clk_i)
		constant NUM_COL_c          : integer := 1;
		type t_integer_array is array (integer range <>) of integer;
		file test_vector_f          : text open read_mode is rotQua_txt_obs_g;
		variable row                : line;
		variable v_data_read        : t_integer_array(1 to NUM_COL_c);
		variable v_data_row_counter : integer := 0;
	begin
		if rst_i = '1' then
			v_data_row_counter := 0;
			v_data_read        := (others => 0);
			------------------------------------
		elsif falling_edge(clk_i) then

			if str_o = '1' then
				if not endfile(test_vector_f) then
					v_data_row_counter := v_data_row_counter + 1;
					readline(test_vector_f, row);
				end if;

				for i in 1 to NUM_COL_c loop
					read(row, v_data_read(i));
				end loop;
				obs_qpath_s := std_logic_vector(to_signed(v_data_read(1), PsiFixSize(InFixFmt_c)));
			end if;
		end if;
	end process;
	
	------------------------------------------------------------------------
	-- DUT mapping
	------------------------------------------------------------------------
	DUT : entity work.psi_fix_complex_mult
		generic map(InternalFmt_g => InternalFmt_c,
		            OutFmt_g      => OutFmt_c,
		            RstPol_g      => '1',
		            Pipeline_g    => Pipeline_g,
		            InFixFmt_g    => InFixFmt_c,
		            CoefFixFmt_g  => CoefFixFmt_c)
		port map(
			clk_i             => clk_i,
			rst_i             => rst_i,
			data_ipath_i      => data_ipath_i,
			data_qpath_i      => data_qpath_i,
			str_i             => str_i,
			coef_i1_cmd_i     => coef_cmd_i(0),
			coef_i2_cmd_i     => coef_cmd_i(1),
			coef_q1_cmd_i     => coef_cmd_i(2),
			coef_q2_cmd_i     => coef_cmd_i(3),
			data_inphase_o    => data_inphase_o,
			data_quadrature_o => data_quadrature_o,
			str_o             => str_o);


	assert_proc : process(clk_i)
		variable count_sample_v : integer := 0;
	begin
		if rising_edge(clk_i) then
			if rst_i = '0' then
				if str_o = '1' then
					count_sample_v := count_sample_v + 1;
					assert signed(data_inphase_o) = signed(obs_ipath_s)
					report "## ERROR ##  mismatch for Inphase path @Sample n°: " & integer'image(count_sample_v) severity error;

					if signed(data_inphase_o) = signed(obs_ipath_s) then
						count_mismatch := count_mismatch;
					else
						count_mismatch := count_mismatch + 1;
					end if;

					assert signed(data_quadrature_o) = signed(obs_qpath_s)
					report "## ERROR ##  mismatch for Quadrature path @Sample n°: " & integer'image(count_sample_v) severity error;
					if signed(data_quadrature_o) = signed(obs_qpath_s) then
						count_mismatch2 := count_mismatch2;
					else
						count_mismatch2 := count_mismatch2 + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	process
		variable lout : line;
	begin
		----------------------------------------------------------------------------
		write(lout, string'(" ***************************************************** "));
		writeline(output, lout);
		write(lout, string'(" **             Paul Scherrer Institut              ** "));
		writeline(output, lout);
		write(lout, string'(" ** Simulation Bit True Model Matrix Rotation PsiFix** "));
		writeline(output, lout);
		write(lout, string'(" ***************************************************** "));
		writeline(output, lout);
		----------------------------------------------------------------------------

		rst_i <= '1';
		wait for 10* period_c;
		rst_i <= '0';
		wait for 8192*period_c;

		if count_mismatch2 = 0 and count_mismatch = 0 then
			write(lout, string'("  Time :  "));
			write(lout, now);
			write(lout, string'(" ----->     SUCCESS!! Bit True model for Matrix Rotation 100% Match "));
			writeline(output, lout);
		else
			write(lout, string'("  Time :  "));
			write(lout, now);
			write(lout, string'(" ----->     FAIL!! Bit True model for Matrix Rotation contains ERRORs "));
			writeline(output, lout);
			write(lout, string'("  Time :  "));
			write(lout, now);
			write(lout, string'(" ----->     Bit True model mismatch count Inphase path is:     " & to_string(count_mismatch)));
			writeline(output, lout);
			write(lout, string'("  Time :  "));
			write(lout, now);
			write(lout, string'(" ----->     Bit True model mismatch count Quadarature path is: " & to_string(count_mismatch2)));
			writeline(output, lout);
		end if;

		assert false report "end of simulation" severity failure;
		wait;
	end process;

end architecture;
