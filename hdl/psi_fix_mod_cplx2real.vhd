------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity is a simple modulator with complex input and real output. It
-- modulates the signal with a specific ratio given comared to its clock
-- it automatically computes sin(w) cos(w) where w=2pi/ratio.Fclk.t 
-- and perform the following computation RF = I.sin(w)+Q.cos(w)
------------------------------------------------------------------------------

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
entity psi_fix_mod_cplx2real is
	generic(RstPol_g  : std_logic   := '1'; 	   -- $$ constant = '1' $$
	        InpFmt_g  : PsiFixFmt_t := (1, 1, 15); -- $$ constant=(1,1,15) $$
	        CoefFmt_g : PsiFixFmt_t := (1, 1, 15); -- $$ constant=(1,1,15) $$
	        IntFmt_g : PsiFixFmt_t  := (1, 1, 15); -- $$ constant=(1,1,15) $$
	        OutFmt_g  : PsiFixFmt_t := (1, 1, 15); -- $$ constant=(1,1,15) $$
	        Ratio_g   : natural     := 5 		   -- $$ constant=5 $$
	       );
	port(
		clk_i    : in  std_logic;       -- $$ type=clk; freq=100e6 $$
		rst_i    : in  std_logic;       -- $$ type=rst; clk=clk_i $$
		vld_i    : in  std_logic;       -- valid
		--in
		data_I_i : in  std_logic_vector(PsiFixSize(InpFmt_g) - 1 downto 0);
		data_Q_i : in  std_logic_vector(PsiFixSize(InpFmt_g) - 1 downto 0);
		--out
		data_o   : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
		str_o    : out std_logic
	);
end entity;

architecture rtl of psi_fix_mod_cplx2real is

	type coef_array_t is array (0 to Ratio_g - 1) of std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
	constant coef_scale_c : real := 1.0 - 2.0**(-real(CoefFmt_g.F)); -- prevent +/- 1.0 -
	------------------------------------------------------------------------------
	--Sin coef function <=> Q coef n = (cos(nx2pi/Ratio))
	------------------------------------------------------------------------------

	function coef_sin_array_func return coef_array_t is
		variable array_v : coef_array_t;
	begin
		for i in 0 to Ratio_g - 1 loop
			array_v(i) := PsiFixFromReal(sin(2.0*MATH_PI*real(i)/real(Ratio_g))*coef_scale_c, CoefFmt_g);
		end loop;
		return array_v;
	end function;

	------------------------------------------------------------------------------	
	--COS coef function <=> Q coef n = (cos(nx2pi/Ratio))
	------------------------------------------------------------------------------
	function coef_cos_array_func return coef_array_t is
		variable array_v : coef_array_t;
	begin
		for i in 0 to Ratio_g - 1 loop
			array_v(i) := PsiFixFromReal(cos(2.0*MATH_PI*real(i)/real(Ratio_g))*coef_scale_c, CoefFmt_g);
		end loop;
		return array_v;
	end function;

	-------------------------------------------------------------------------------
	constant MultFmt_c                    : PsiFixFmt_t  := (1, InpFmt_g.I + CoefFmt_g.I + 1, CoefFmt_g.F + InpFmt_g.F);
	constant AddFmt_c                     : PsiFixFmt_t  := (1, IntFmt_g.I + IntFmt_g.I, IntFmt_g.F);
	--Definitin within the above package
	constant table_sin                    : coef_array_t := coef_sin_array_func;
	constant table_cos                    : coef_array_t := coef_cos_array_func;
	-------------------------------------------------------------------------------
	signal sin_s                          : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
	signal cos_s                          : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
	signal mult_i_s                       : std_logic_vector(PsiFixSize(MultFmt_c) - 1 downto 0);
	signal mult_i_dff_s                   : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
	signal mult_q_s                       : std_logic_vector(PsiFixSize(MultFmt_c) - 1 downto 0);
	signal mult_q_dff_s                   : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
	signal sum_s                          : std_logic_vector(PsiFixSize(AddFmt_c) - 1 downto 0);
	--xilinx constraint
	attribute rom_style                   : string;
	attribute rom_style of table_sin : constant is "block";
	attribute rom_style of table_cos : constant is "block";
	-------------------------------------------------------------------------------
	--signal cos_dff_s                      : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
	--signal sin_dff_s                      : std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
	signal str1_s, str2_s, str3_s, str4_s : std_logic;
	
	--uncomment for debugging
	--signal dbg_multi_s, dbg_multq_s       : real:=0.0;
	--signal dbg_cos_s, dbg_sin_s           : real:=0.0;
	signal datInp_s : std_logic_vector(PsiFixSize(InpFmt_g) - 1 downto 0);
	signal datQua_s : std_logic_vector(PsiFixSize(InpFmt_g) - 1 downto 0);

begin
	------------------------------------------------
	--dbg_cos_s   <= PsiFixToReal(cos_s, CoefFmt_g);
	--dbg_sin_s   <= PsiFixToReal(sin_s, CoefFmt_g);
	------------------------------------------------
	--dbg_multi_s <= PsiFixToReal(mult_i_s, MultFmt_c);
	--dbg_multq_s <= PsiFixToReal(mult_q_s, MultFmt_c);

	-------------------------------------------------------------------------------
	-- simple ROM pointer for both array
	-------------------------------------------------------------------------------
	proc_add_coef : process(clk_i)
		variable cpt_v : integer range 0 to Ratio_g := 0;
	begin
		if rising_edge(clk_i) then
			if rst_i = RstPol_g then
				cpt_v := 0;
			else
				if vld_i = '1' then
					if cpt_v < Ratio_g - 1 then
						cpt_v := cpt_v + 1;
					else
						cpt_v := 0;
					end if;
				end if;
			end if;
		end if;
		sin_s <= table_sin(cpt_v);--TODO perhaps add dff stage to help timing
		cos_s <= table_cos(cpt_v);--TODO perhaps add dff stage to help timing
	end process;

	-------------------------------------------------------------------------------
	-- Multiplier and Adder process
	-------------------------------------------------------------------------------
	proc_dsp : process(clk_i)
	begin
		if rising_edge(clk_i) then

			if rst_i = RstPol_g then
				str_o  <= '0';
				str1_s <= '0';
				str2_s <= '0';
				str3_s <= '0';
				str4_s <= '0';
			else
				-- *** stage 1 ***
				str1_s       <= vld_i;
				datInp_s     <= data_I_i;
				datQua_s     <= data_Q_i;
				
				-- *** stage 2 ***
				str2_s       <= str1_s;
				mult_i_s     <= PsiFixMult(sin_s, CoefFmt_g,
				                           datInp_s, InpFmt_g,
				                           MultFmt_c, PsiFixTrunc, PsiFixWrap);
				mult_q_s     <= PsiFixMult(cos_s, CoefFmt_g,
				                           datQua_s, InpFmt_g,
				                           MultFmt_c, PsiFixTrunc, PsiFixWrap);
				-- *** stage 3 ***
				str3_s       <= str2_s;
				mult_i_dff_s <= PsiFixResize(mult_i_s, MultFmt_c, IntFmt_g, PsiFixTrunc, PsiFixWrap);
				mult_q_dff_s <= PsiFixResize(mult_q_s, MultFmt_c, IntFmt_g, PsiFixTrunc, PsiFixWrap);
				
				-- *** stage 4 ***
				str4_s       <= str3_s;
				sum_s        <= PsiFixAdd(mult_i_dff_s, IntFmt_g,
				                          mult_q_dff_s, IntFmt_g,
				                          AddFmt_c, PsiFixTrunc, PsiFixWrap);
				-- *** stage 5 ***
				data_o       <= PsiFixResize(sum_s, AddFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
				str_o        <= str4_s;
			end if;
		end if;
	end process;

end architecture;
