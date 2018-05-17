--=================================================================
--	Paul Scherrer Institut <PSI> Villigen, Schweiz
-- 	Copyright ©, 2018, Benoit STEF, all rights reserved 
--=================================================================
-- unit		: psi_fix_complex_mult(RTL)
-- file		: psi_fix_complex_mult.vhd
-- project	: Psi Fixed Point Library Elemental
-- Author	: stef_b - 8460 LLRF group WBBA302
-- purpose	: rotation matrix for I, Q path I*ci1 +Ici2 / Q*cq1+Q*cq2
--
--	 __    MATRIX ROTATION    __   __	MATRIX ROTATION		__
--	|						    | | 						  |
--	| iCOS(theta) -	qSIN(theta) | | inphase x i1 - quad x i2  |
--	| iSIN(theta) +  qCOS(theta)| | inphase x q1 + quad x q2  |
--	|__					      __| |__						__|
--
-- SIM tool	: Modelsim SE 10.6
-- EDA tool	: Xilinx ISE 13.4
-- Target	: Xilinx FPGA Virtex-6  - xc6vlx130t-1fff1156 
-- misc		:
-- synth	:  
-- date		: 14.03.2018
--=================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;

entity psi_fix_complex_mult is
	generic(RstPol_g      : std_logic   := '0'; -- set reset polarity
	        Pipeline_g    : boolean     := false; -- when false 3 pipes stages, when false 6 pipes (increase Fmax)
	        InFixFmt_g    : PsiFixFmt_t := (1, 0, 15); -- Input Fixed Point format 
	        InternalFmt_g : PsiFixFmt_t := (1, 0, 15); -- Internal Calc. Fixed Point format
	        CoefFixFmt_g  : PsiFixFmt_t := (1, 0, 24); -- Matrix Coef Fixed Point format
	        OutFmt_g      : PsiFixFmt_t := (1, 0, 24)); -- Output Fixed Point format
	port(clk_i   : in  std_logic;       -- clk 
	     rst_i   : in  std_logic;       -- sync. rst
	     ipath_i : in  std_logic_vector(PsiFixSize(InFixFmt_g) - 1 downto 0); -- data input I
	     qpath_i : in  std_logic_vector(PsiFixSize(InFixFmt_g) - 1 downto 0); -- data input Q
	     vld_i   : in  std_logic;       -- strobe input
	     --
	     i1_i    : in  std_logic_vector(PsiFixSize(CoefFixFmt_g) - 1 downto 0); -- I1
	     i2_i    : in  std_logic_vector(PsiFixSize(CoefFixFmt_g) - 1 downto 0); -- I2
	     q1_i    : in  std_logic_vector(PsiFixSize(CoefFixFmt_g) - 1 downto 0); -- Q1
	     q2_i    : in  std_logic_vector(PsiFixSize(CoefFixFmt_g) - 1 downto 0); -- Q2
	     --
	     iout_o  : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output I
	     qout_o  : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output Q
	     vld_o   : out std_logic);      -- strobe output
end entity;

architecture rtl of psi_fix_complex_mult is
	--internal declaration
	signal coef_i1_cmd_s                             : std_logic_vector(i1_i'range);
	signal coef_i2_cmd_s                             : std_logic_vector(i1_i'range);
	signal coef_q1_cmd_s                             : std_logic_vector(i1_i'range);
	signal coef_q2_cmd_s                             : std_logic_vector(i1_i'range);
	--
	signal rot_inp1_s, mult_i1_dff_s, mult_i1_dff2_s : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	signal rot_inp2_s, mult_i2_dff_s, mult_i2_dff2_s : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	signal rot_qua1_s, mult_q1_dff_s, mult_q1_dff2_s : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	signal rot_qua2_s, mult_q2_dff_s, mult_q2_dff2_s : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	--                                          
	signal sum_inp_s, sum_qua_s                      : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	signal sum1_dff_s, sum2_dff_s                    : std_logic_vector(PsiFixSize(InternalFmt_g) - 1 downto 0);
	--process pipeline
	signal dff0_s, dff1_s, dff2_s                    : std_logic;
	signal dff3_s, dff4_s, dff5_s                    : std_logic;

	--uncomment to debug 
	--signal dbg_rot_in_1, dbg_rot_in_2, dbg_rot_qua1, dbg_rot_qua2, dbg_sum_inp, dbg_sum_qua : real;

begin

	-----------------------------------------------------------------
	-- Input command Gating from Software
	-----------------------------------------------------------------
	in_proc : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				coef_i1_cmd_s <= (others => '0');
				coef_i2_cmd_s <= (others => '0');
				coef_q1_cmd_s <= (others => '0');
				coef_q2_cmd_s <= (others => '0');
			else
				coef_i1_cmd_s <= i1_i;
				coef_i2_cmd_s <= i2_i;
				coef_q1_cmd_s <= q1_i;
				coef_q2_cmd_s <= q2_i;
			end if;
		end if;
	end process;

	no_pipe_gene : if Pipeline_g = false generate
		-----------------------------------------------------------------
		-- multiplier process
		-----------------------------------------------------------------
		mult_proc : process(clk_i)
		begin
			if rising_edge(clk_i) then
				if rst_i = RstPol_g then
					-----------------------------------------------------------------
					rot_inp1_s <= (others => '0');
					rot_inp2_s <= (others => '0');
					rot_qua1_s <= (others => '0');
					rot_qua2_s <= (others => '0');
					-----------------------------------------------------------------
					dff0_s     <= '0';
				else
					dff0_s <= vld_i;
					-----------------------------------------------------------------
					if vld_i = '1' then

						rot_inp1_s <= PsiFixMult(ipath_i, InFixFmt_g,
						                         coef_i1_cmd_s, CoefFixFmt_g,
						                         InternalFmt_g, PsiFixRound, PsiFixSat);

						rot_inp2_s <= PsiFixMult(qpath_i, InFixFmt_g,
						                         coef_i2_cmd_s, CoefFixFmt_g,
						                         InternalFmt_g, PsiFixRound, PsiFixSat);

						rot_qua1_s <= PsiFixMult(ipath_i, InFixFmt_g,
						                         coef_q1_cmd_s, CoefFixFmt_g,
						                         InternalFmt_g, PsiFixRound, PsiFixSat);

						rot_qua2_s <= PsiFixMult(qpath_i, InFixFmt_g,
						                         coef_q2_cmd_s, CoefFixFmt_g,
						                         InternalFmt_g, PsiFixRound, PsiFixSat);
					end if;
				end if;
			end if;
		end process;

		--dbg_rot_in_1 <= PsiFixToReal(rot_inp1_s, InternalFmt_g);
		--dbg_rot_in_2 <= PsiFixToReal(rot_inp2_s, InternalFmt_g);
		--dbg_rot_qua1 <= PsiFixToReal(rot_qua1_s, InternalFmt_g);
		--dbg_rot_qua2 <= PsiFixToReal(rot_qua2_s, InternalFmt_g); 

		-----------------------------------------------------------------
		-- adder process
		-----------------------------------------------------------------
		adder_proc : process(clk_i)
		begin
			if rising_edge(clk_i) then
				if rst_i = RstPol_g then
					sum_inp_s <= (others => '0');
					sum_qua_s <= (others => '0');
					iout_o    <= (others => '0');
					qout_o    <= (others => '0');
					vld_o     <= '0';
					-----------------------------------------------------------------
					dff1_s    <= '0';
					dff2_s    <= '0';
				else
					dff1_s <= dff0_s;
					-----------------------------------------------------------------
					if dff0_s = '1' then
						sum_inp_s <= PsiFixSub(rot_inp1_s, InternalFmt_g,
						                       rot_inp2_s, InternalFmt_g,
						                       InternalFmt_g, PsiFixRound, PsiFixSat);

						sum_qua_s <= PsiFixAdd(rot_qua1_s, InternalFmt_g,
						                       rot_qua2_s, InternalFmt_g,
						                       InternalFmt_g, PsiFixRound, PsiFixSat);
					end if;
					--output map
					iout_o <= PsiFixResize(sum_inp_s, InternalFmt_g, OutFmt_g, PsiFixRound, PsiFixSat);
					qout_o <= PsiFixResize(sum_qua_s, InternalFmt_g, OutFmt_g, PsiFixRound, PsiFixSat);
					dff2_s <= dff1_s;
					vld_o  <= dff2_s;
				end if;
			end if;
		end process;

		--dbg_sum_inp <= PsiFixToReal(sum_inp_s, InternalFmt_g);
		--dbg_sum_qua <= PsiFixToReal(sum_qua_s, InternalFmt_g); 		

	end generate;

	pipe_gene : if Pipeline_g = true generate
		-----------------------------------------------------------------
		-- multiplier process
		-----------------------------------------------------------------
		mult_proc : process(clk_i)
		begin
			if rising_edge(clk_i) then
				if rst_i = RstPol_g then
					-----------------------------------------------------------------
					rot_inp1_s <= (others => '0');
					rot_inp2_s <= (others => '0');
					rot_qua1_s <= (others => '0');
					rot_qua2_s <= (others => '0');
					-----------------------------------------------------------------
					dff0_s     <= '0';
					dff1_s     <= '0';
				else
					dff0_s        <= vld_i;
					dff1_s        <= dff0_s;
					-----------------------------------------------------------------
					mult_i1_dff_s <= rot_inp1_s;
					mult_i2_dff_s <= rot_inp2_s;
					mult_q1_dff_s <= rot_qua1_s;
					mult_q2_dff_s <= rot_qua2_s;
					-----------------------------------------------------------------
					if vld_i = '1' then
						mult_i1_dff2_s <= mult_i1_dff_s;
						mult_i2_dff2_s <= mult_i2_dff_s;
						mult_q1_dff2_s <= mult_q1_dff_s;
						mult_q2_dff2_s <= mult_q2_dff_s;
					end if;
					-----------------------------------------------------------------
					rot_inp1_s    <= PsiFixMult(ipath_i, InFixFmt_g,
					                            coef_i1_cmd_s, CoefFixFmt_g,
					                            InternalFmt_g, PsiFixRound, PsiFixSat);
					rot_inp2_s    <= PsiFixMult(qpath_i, InFixFmt_g,
					                            coef_i2_cmd_s, CoefFixFmt_g,
					                            InternalFmt_g, PsiFixRound, PsiFixSat);
					rot_qua1_s    <= PsiFixMult(ipath_i, InFixFmt_g,
					                            coef_q1_cmd_s, CoefFixFmt_g,
					                            InternalFmt_g, PsiFixRound, PsiFixSat);
					rot_qua2_s    <= PsiFixMult(qpath_i, InFixFmt_g,
					                            coef_q2_cmd_s, CoefFixFmt_g,
					                            InternalFmt_g, PsiFixRound, PsiFixSat);

				end if;
			end if;
		end process;

		-----------------------------------------------------------------
		-- adder process
		-----------------------------------------------------------------
		adder_proc : process(clk_i)
		begin
			if rising_edge(clk_i) then
				if rst_i = RstPol_g then
					-----------------------------------------------------------------
					iout_o     <= (others => '0');
					qout_o     <= (others => '0');
					vld_o      <= '0';
					-----------------------------------------------------------------
					sum_inp_s  <= (others => '0');
					sum1_dff_s <= (others => '0');
					sum_qua_s  <= (others => '0');
					sum2_dff_s <= (others => '0');
					-----------------------------------------------------------------
					dff2_s     <= '0';
					dff3_s     <= '0';
					dff4_s     <= '0';
					dff5_s     <= '0';
				else
					-----------------------------------------------------------------
					dff2_s    <= dff1_s;
					dff3_s    <= dff2_s;
					dff4_s    <= dff3_s;
					dff5_s    <= dff4_s;
					-----------------------------------------------------------------
					sum_inp_s <= PsiFixSub(mult_i1_dff2_s, InternalFmt_g,
					                       mult_i2_dff2_s, InternalFmt_g,
					                       InternalFmt_g, PsiFixRound, PsiFixSat);

					sum_qua_s <= PsiFixAdd(mult_q1_dff2_s, InternalFmt_g,
					                       mult_q2_dff2_s, InternalFmt_g,
					                       InternalFmt_g, PsiFixRound, PsiFixSat);

					sum1_dff_s <= sum_inp_s;
					sum2_dff_s <= sum_qua_s;
					-----------------------------------------------------------------
					if dff1_s = '1' then
						iout_o <= PsiFixResize(sum1_dff_s, InternalFmt_g, OutFmt_g, PsiFixRound, PsiFixSat);
						qout_o <= PsiFixResize(sum2_dff_s, InternalFmt_g, OutFmt_g, PsiFixRound, PsiFixSat);
					end if;
					vld_o      <= dff5_s;
				end if;
			end if;
		end process;

	end generate;
end architecture;