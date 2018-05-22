------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity is a simple demodulator with real input and complex output. It
-- demodulates the signal and filters the results with a comb-filter of length
-- 1/Fcarrier (zeros at Fcarrier where DC ends up and Fcarrier*2 where the
-- demodulation alias occurs).
-- The demodulator only works well for very narrowband signals with very little
-- out of band noise. The signal frequency must be an integer multiple of the 
-- sample frequency.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_fix_pkg.all;
	
-- TODO: Gaincorr

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim,check $$
entity psi_fix_demod_real2cplx is
	generic (
		RstPol_g  : std_logic   := '1';			-- $$ constant = '1' $$
	    DataFmt_g : PsiFixFmt_t;				-- $$ constant=(1,0,15) $$
	    Ratio_g   : natural     := 5			-- $$ constant=5 $$
	);
	port(
		clk_i				: in  	std_logic; 												-- $$ type=clk; freq=100e6 $$
		rst_i				: in  	std_logic; 												-- $$ type=rst; clk=clk_i $$
		str_i				: in	std_logic;												
		data_i				: in  	std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);	
		phi_offset_i		: in	std_logic_vector(log2ceil(Ratio_g) - 1 downto 0);
		--
		data_I_o			: out 	std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
		data_Q_o			: out 	std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
		str_o				: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture RTL of psi_fix_demod_real2cplx is

	type coef_array_t is array(0 to Ratio_g-1) of std_logic_vector(PsiFixSize(DataFmt_g)-1 downto 0);
	
	constant coef_scale_c : real := 1.0-2.0**(-real(DataFmt_g.F));	-- prevent +/- 1.0

	--SIN coef function <=> Q coef n = (sin(nx2pi/Ratio)(2/Ratio))
	function coef_sin_array_func return coef_array_t is
		variable array_v : coef_array_t;
	begin
		for i in 0 to Ratio_g - 1 loop
			array_v(i) := PsiFixFromReal(sin(2.0*MATH_PI*real(i)/real(Ratio_g))*coef_scale_c, DataFmt_g);
		end loop;
		return array_v;
	end function;

	--COS coef function <=> Q coef n = (cos(nx2pi/Ratio)(2/Ratio))
	function coef_cos_array_func return coef_array_t is
		variable array_v : coef_array_t;
	begin
		for i in 0 to Ratio_g - 1 loop
			array_v(i) := PsiFixFromReal(cos(2.0*MATH_PI*real(i)/real(Ratio_g))*coef_scale_c, DataFmt_g);
		end loop;
		return array_v;
	end function;

	-- I coef n = (sin(nx2pi/5)(2/5))
	constant nonIQ_table_sin        : coef_array_t                   := coef_sin_array_func;
	-- Q coef n = (cos(nx2pi/5)(2/5))
	constant nonIQ_table_cos        : coef_array_t                   := coef_cos_array_func;
	--xilinx constraint
	attribute rom_style             : string;
	attribute rom_style of nonIQ_table_sin, nonIQ_table_cos : constant is "distributed";
	
	constant SubType_t				: PsiFixFmt_t	:= (DataFmt_g.S, DataFmt_g.I+1, DataFmt_g.F);
	--
	signal phi_offset_s             : std_logic_vector(log2ceil(Ratio_g) - 1 downto 0);
	signal cptInt					: integer range 0 to Ratio_g - 1 := 0;		
	signal cpt_s                    : integer range 0 to Ratio_g - 1 := 0;
	signal mult_i_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal data_sr_i_s, data_sr_q_s : coef_array_t;
	--
	signal i_sub_s                  : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal i_add_s                  : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal q_sub_s                  : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal q_add_s                  : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal i_sub_dff_s              : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal i_sub_dff2_s             : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal q_sub_dff_s              : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal q_sub_dff2_s             : std_logic_vector(PsiFixSize(SubType_t) - 1 downto 0);
	signal mult_i_dff_s             : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_dff_s             : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_i_dff2_s            : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_dff2_s            : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal coef_i_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal coef_q_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal data_s                   : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal str						: std_logic_vector(0 to 8);
	
begin
	--===========================================================================
	-- 		LIMIT the phase offset to max value and check value change
	--===========================================================================
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				phi_offset_s     <= (others => '0');
				data_s           <= (others => '0');
				str				 <= (others => '0');
			else
				str(0)				<= str_i;
				str(1 to str'high)	<= str(0 to str'high-1);
				data_s          	<= data_i;
				if unsigned(phi_offset_i) > Ratio_g - 1 then
					phi_offset_s <= std_logic_vector(to_unsigned((Ratio_g - 1), phi_offset_i'length));
				else
					phi_offset_s <= phi_offset_i;
				end if;				
			end if;
		end if;
	end process;
	str_o <= str(str'high);

	--===========================================================================
	-- 	 pointer ROM
	--===========================================================================
	process(clk_i)
		
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				cptInt    <= 0;
			else
				if str_i = '1' then
					if cptInt = Ratio_g-1 then
						cptInt <= 0;
					else
						cptInt <= cptInt+1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(cptInt)
		variable cptIntOffs : integer range 0 to 2*Ratio_g - 1 := 0;
	begin
		cptIntOffs := cptInt + to_integer(unsigned(phi_offset_s));
		if cptIntOffs > Ratio_g-1 then
			cpt_s <= cptIntOffs - Ratio_g;
		else
			cpt_s <= cptIntOffs;
		end if;	
	end process;

	--===========================================================================
	-- I PATH
	--===========================================================================
	imult_proc : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				mult_i_s      	<= (others => '0');
				mult_i_dff_s  	<= (others => '0');
				mult_i_dff2_s 	<= (others => '0');
				coef_i_s 		<= (others => '0');
				for i in 0 to Ratio_g - 1 loop
					data_sr_i_s(i) <= (others => '0');
				end loop;
			else
				coef_i_s 	 <= nonIQ_table_sin(cpt_s);
				mult_i_s       <= PsiFixMult(data_s, DataFmt_g,
				                             coef_i_s, DataFmt_g,
				                             DataFmt_g, PsiFixRound, PsiFixSat);
				mult_i_dff_s   <= mult_i_s;
				mult_i_dff2_s  <= mult_i_dff_s;
				if str(3) = '1' then
					data_sr_i_s(0) <= mult_i_dff2_s;
					for i in 1 to Ratio_g - 1 loop
						data_sr_i_s(i) <= data_sr_i_s(i - 1);
					end loop;
				end if;
			end if;
		end if;
	end process;

	--===========================================================================
	--Q path Recursive running sum
	--===========================================================================
	i_adder_proc : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				i_sub_s      <= (others => '0');
				i_sub_dff_s  <= (others => '0');
				i_sub_dff2_s <= (others => '0');
				i_add_s      <= (others => '0');
				data_I_o     <= (others => '0');
			else
				i_sub_s      <= PsiFixSub(mult_i_dff2_s, DataFmt_g, data_sr_i_s(Ratio_g - 1), DataFmt_g, SubType_t, PsiFixRound, PsiFixSat);
				i_sub_dff_s  <= i_sub_s;
				i_sub_dff2_s <= i_sub_dff_s;
				if str(6) = '1' then
					i_add_s      <= PsiFixAdd(i_add_s, DataFmt_g, i_sub_dff2_s, SubType_t, DataFmt_g, PsiFixRound, PsiFixSat);
				end if;
				data_I_o     <= i_add_s;
			end if;
		end if;
	end process;

	--===========================================================================
	-- Q PATH shift register
	--===========================================================================
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				mult_q_s      <= (others => '0');
				mult_q_dff_s  <= (others => '0');
				mult_q_dff2_s <= (others => '0');
				coef_q_s 	  <= (others => '0');
				for i in 0 to Ratio_g - 1 loop
					data_sr_q_s(i) <= (others => '0');
				end loop;
			else
				coef_q_s 		<= nonIQ_table_cos(cpt_s);
				mult_q_s       	<= PsiFixMult(data_s, DataFmt_g,
				                              coef_q_s, DataFmt_g,
				                              DataFmt_g, PsiFixRound, PsiFixSat);
				mult_q_dff_s   <= mult_q_s;
				mult_q_dff2_s  <= mult_q_dff_s;
				mult_q_dff2_s  <= mult_q_dff_s;
				if str(3) = '1' then
					data_sr_q_s(0) <= mult_q_dff2_s;
					for i in 1 to Ratio_g - 1 loop
						data_sr_q_s(i) <= data_sr_q_s(i - 1);
					end loop;
				end if;
			end if;
		end if;
	end process;

	--===========================================================================
	--Q path Recursive running sum
	--===========================================================================
	q_adder_proc : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				q_sub_s      <= (others => '0');
				q_sub_dff_s  <= (others => '0');
				q_sub_dff2_s <= (others => '0');
				q_add_s      <= (others => '0');
				data_Q_o     <= (others => '0');
			else
				q_sub_s      <= PsiFixSub(mult_q_dff2_s, DataFmt_g,
				                          data_sr_q_s(Ratio_g - 1), DataFmt_g,
				                          SubType_t, PsiFixRound, PsiFixSat);
				q_sub_dff_s  <= q_sub_s;
				q_sub_dff2_s <= q_sub_dff_s;
				if str(6) = '1' then
					q_add_s      <= PsiFixAdd(q_add_s, DataFmt_g,
											  q_sub_dff2_s, SubType_t,
											  DataFmt_g, PsiFixRound, PsiFixSat);
				end if;
				data_Q_o     <= q_add_s;
			end if;
		end if;
	end process;

end architecture;
