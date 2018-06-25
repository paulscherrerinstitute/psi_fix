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
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim,check $$
entity psi_fix_demod_real2cplx is
	generic (
		RstPol_g  	: std_logic   	:= '1';			-- $$ constant = '1' $$
	    DataFmt_g 	: PsiFixFmt_t;					-- $$ constant=(1,0,15) $$
	    Ratio_g   	: natural     	:= 5;			-- $$ constant=5 $$
		GainCorr_g	: string		:= "NONE"		-- NONE, EXACT or ROUGH (see psi_fix_mov_avg for details)
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
	
	--constant SubType_t				: PsiFixFmt_t	:= (DataFmt_g.S, DataFmt_g.I+1, DataFmt_g.F);
	
	type OutPipe_t is array (natural range <>) of std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	--
	signal cptInt					: integer range 0 to Ratio_g - 1 := 0;		
	signal cpt_s                    : integer range 0 to Ratio_g - 1 := 0;
	signal mult_i_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	--
	signal mult_i_dff_s             : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_dff_s             : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_i_dff2_s            : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal mult_q_dff2_s            : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal coef_i_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal coef_q_s                 : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal data_s                   : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal data_dff_s                : std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal strIn					: std_logic_vector(0 to 4);
	signal strOut					: std_logic_vector(7 to 8);
	signal outQ_dffs				: OutPipe_t(7 to 8);
	signal outI_dffs				: OutPipe_t(7 to 8);
	signal RstPos					: std_logic;
	signal VldMvAvg					: std_logic;
	signal OutMvAvgI				: std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	signal OutMvAvgQ				: std_logic_vector(PsiFixSize(DataFmt_g) - 1 downto 0);
	
begin 

	RstPos <= '1' when rst_i = RstPol_g else '0';

	--===========================================================================
	-- 		LIMIT the phase offset to max value and check value change
	--===========================================================================
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				data_s      <= (others => '0');
				data_dff_s  <= (others => '0');
				strIn		<= (others => '0');
				strOut		<= (others => '0');
			else
				strIn(0)					<= str_i;
				strIn(1 to strIn'high)		<= strIn(0 to strIn'high-1);
				strOut(strOut'low)			<= VldMvAvg;
				strOut(strOut'low+1 to strOut'high)	<= strOut(strOut'low to strOut'high-1);
				data_s          	<= data_i;		
				data_dff_s			<= data_s;
			end if;
		end if;
	end process;
	str_o <= strOut(strOut'high);

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
	
	process(clk_i)
		variable cptIntOffs : integer range 0 to 2*Ratio_g - 1 := 0;
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				cpt_s <= 0;
			else
				assert unsigned(phi_offset_i) <= Ratio_g-1 report "###ERROR###: psi_fix_demod_real2cpls: phi_offset_i must be <= Ratio_g-1" severity error;
				cptIntOffs := cptInt + to_integer(unsigned(phi_offset_i));
				if unsigned(phi_offset_i) > Ratio_g-1 then
					cpt_s <= cptInt + Ratio_g-1;
				elsif cptIntOffs > Ratio_g-1 then
					cpt_s <= cptIntOffs - Ratio_g;
				else
					cpt_s <= cptIntOffs;
				end if;
			end if;
		end if;
	end process;

	--===========================================================================
	-- I PATH
	--===========================================================================
	imult_proc : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				-- before moving avg
				mult_i_s      	<= (others => '0');
				mult_i_dff_s  	<= (others => '0');
				mult_i_dff2_s 	<= (others => '0');
				coef_i_s 		<= (others => '0');
				-- after moving avg
				outI_dffs		<= (others => (others => '0'));
			else
				-- before moving avg
				coef_i_s 	 <= nonIQ_table_sin(cpt_s);
				mult_i_s       <= PsiFixMult(data_dff_s, DataFmt_g,
				                             coef_i_s, DataFmt_g,
				                             DataFmt_g, PsiFixRound, PsiFixSat);
				mult_i_dff_s   <= mult_i_s;
				mult_i_dff2_s  <= mult_i_dff_s;
				-- after moving avg
				outI_dffs(outI_dffs'low)						<= OutMvAvgI;
				outI_dffs(outI_dffs'low+1 to outI_dffs'high)	<= outI_dffs(outI_dffs'low to outI_dffs'high-1);
			end if;
		end if;
	end process;
	data_I_o <= outI_dffs(outI_dffs'high);
	
	i_mov_avg_i : entity work.psi_fix_mov_avg
		generic map (
			InFmt_g 	=> DataFmt_g,
			OutFmt_g 	=> DataFmt_g,
			Taps_g		=> Ratio_g,
			GainCorr_g	=> GainCorr_g,
			Round_g		=> PsiFixRound,
			Sat_g		=> PsiFixSat
		)
		port map (
			Clk			=> clk_i,
			Rst			=> RstPos,
			InVld		=> strIn(4),										
			InData		=> mult_i_dff2_s,
			OutVld		=> VldMvAvg,										
			OutData		=> OutMvAvgI
		);

	--===========================================================================
	-- Q PATH
	--===========================================================================
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				mult_q_s      <= (others => '0');
				mult_q_dff_s  <= (others => '0');
				mult_q_dff2_s <= (others => '0');
				coef_q_s 	  <= (others => '0');
				outQ_dffs	  <= (others => (others => '0'));
			else
				coef_q_s 		<= nonIQ_table_cos(cpt_s);
				mult_q_s       	<= PsiFixMult(data_dff_s, DataFmt_g,
				                              coef_q_s, DataFmt_g,
				                              DataFmt_g, PsiFixRound, PsiFixSat);
				mult_q_dff_s   <= mult_q_s;
				mult_q_dff2_s  <= mult_q_dff_s;
				outQ_dffs(outQ_dffs'low)						<= OutMvAvgQ;
				outQ_dffs(outQ_dffs'low+1 to outQ_dffs'high)	<= outQ_dffs(outQ_dffs'low to outQ_dffs'high-1);
			end if;
		end if;
	end process;
	data_Q_o <= outQ_dffs(outQ_dffs'high);

	i_mov_avg_q : entity work.psi_fix_mov_avg
		generic map (
			InFmt_g 	=> DataFmt_g,
			OutFmt_g 	=> DataFmt_g,
			Taps_g		=> Ratio_g,
			GainCorr_g	=> GainCorr_g,
			Round_g		=> PsiFixRound,
			Sat_g		=> PsiFixSat
		)
		port map (
			Clk			=> clk_i,
			Rst			=> RstPos,
			InVld		=> strIn(4),										
			InData		=> mult_q_dff2_s,
			OutVld		=> open,										
			OutData		=> OutMvAvgQ
		);

end architecture;
