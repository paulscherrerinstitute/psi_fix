------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculates a binary division of two fixed point values.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library psi_common;
	use work.psi_fix_pkg.all;
	use psi_common.psi_common_logic_pkg.all;
	use psi_common.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_fix_bin_div is
	generic (
		NumFmt_g				: PsiFixFmt_t	:= (1, 0, 17);	
		DenomFmt_g				: PsiFixFmt_t	:= (0, 0, 17);	
		OutFmt_g				: PsiFixFmt_t	:= (1, 0, 25);
		Round_g					: PsiFixRnd_t	:= PsiFixTrunc;
		Sat_g					: PsiFixSat_t	:= PsiFixSat
	);
	port (
		-- Control Signals
		Clk			: in 	std_logic;
		Rst			: in 	std_logic;
		-- Input
		InVld		: in	std_logic;
		InRdy		: out	std_logic;
		InNum		: in	std_logic_vector(PsiFixSize(NumFmt_g)-1 downto 0);
		InDenom		: in	std_logic_vector(PsiFixSize(DenomFmt_g)-1 downto 0);
		-- Output
		OutVld		: out	std_logic;
		OutQuot		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_bin_div is

	-- constants
	constant FirstShift_c	: integer			:= OutFmt_g.I;
	constant NumAbsFmt_c	: PsiFixFmt_t		:= (0, NumFmt_g.I+NumFmt_g.S, NumFmt_g.F);
	constant DenomAbsFmt_c	: PsiFixFmt_t		:= (0, DenomFmt_g.I+DenomFmt_g.S, DenomFmt_g.F);
	constant ResultIntFmt_c	: PsiFixFmt_t		:= (1, OutFmt_g.I+1, OutFmt_g.F+1);
	constant DenomCompFmt_c	: PsiFixFmt_t		:= (0, DenomAbsFmt_c.I+FirstShift_c, DenomAbsFmt_c.F-FirstShift_c);
	constant NumCompFmt_c	: PsiFixFmt_t		:= (0, max(DenomCompFmt_c.I, NumAbsFmt_c.I), max(DenomCompFmt_c.F, NumAbsFmt_c.F));
	constant Iterations_c	: integer			:= OutFmt_g.I+OutFmt_g.F+2;
	
	-- types
	type State_t is (Idle_s, Init1_s, Init2_s, Calc_s, Output_s);

	
	-- Two process method
	type two_process_r is record
		State		: State_t;
		Num			: std_logic_vector(InNum'range);
		Denom 		: std_logic_vector(InDenom'range);
		NumSign		: std_logic;
		DenomSign	: std_logic;
		NumAbs 		: std_logic_vector(PsiFixSize(NumAbsFmt_c)-1 downto 0);
		DenomAbs 	: std_logic_vector(PsiFixSize(DenomAbsFmt_c)-1 downto 0);
		DenomComp	: std_logic_vector(PsiFixSize(DenomCompFmt_c)-1 downto 0);
		NumComp		: std_logic_vector(PsiFixSize(NumCompFmt_c)-1 downto 0);
		IterCnt		: integer range 0 to Iterations_c-1;
		ResultInt	: std_logic_vector(PsiFixSize(ResultIntFmt_c)-1 downto 0);
		OutVld		: std_logic;
		OutQuot		: std_logic_vector(PsiFixsize(OutFmt_g)-1 downto 0);
		InRdy		: std_logic;
	end record;
	signal r, r_next : two_process_r;
	
	
begin
	--------------------------------------------
	-- Combinatorial Process
	--------------------------------------------
	p_comb : process(InVld, InNum, InDenom, r)
		variable v : two_process_r;
		variable NumInDenomFmt_v	: std_logic_vector(PsiFixSize(DenomCompFmt_c) -1 downto 0);
	begin
		-- *** Hold variables stable ***
		v := r;
		
		-- *** State Machine ***
		v.InRdy := '0';
		v.OutVld := '0';
		NumInDenomFmt_v := (others => '0');
		case r.State is
			when Idle_s =>
				-- start execution if valid
				if InVld = '1' then
					v.State	:= Init1_s;
					v.Num	:= InNum;
					v.Denom	:= InDenom;
				else 
					v.InRdy := '1';
				end if;					
			
			when Init1_s =>
				-- state handling
				v.State := Init2_s;
				-- latch signs
				if NumFmt_g.S = 0 then
					v.NumSign := '0';
				else	
					v.NumSign := r.Num(r.Num'left);
				end if;
				if DenomFmt_g.S = 0 then
					v.DenomSign := '0';
				else
					v.DenomSign := r.Denom(r.Denom'left);
				end if;
				-- calculate absolute values
				v.NumAbs 	:= PsiFixAbs(r.Num, NumFmt_g, NumAbsFmt_c);
				v.DenomAbs	:= PsiFixAbs(r.Denom, DenomFmt_g, DenomAbsFmt_c);
				
			when Init2_s =>
				-- state handling
				v.State := Calc_s;
				-- Initialize calculation
				v.DenomComp := PsiFixShiftLeft(r.DenomAbs, DenomAbsFmt_c, FirstShift_c, FirstShift_c, DenomCompFmt_c);
				v.NumComp 	:= PsiFixResize(r.NumAbs, NumAbsFmt_c, NumCompFmt_c);
				v.IterCnt 	:= Iterations_c-1;
				v.ResultInt := (others => '0');
				
			when Calc_s =>
				-- state handling
				if r.IterCnt = 0 then
					v.State := Output_s;
				else
					v.IterCnt := r.IterCnt - 1;
				end if;
				
				-- Calculation
				v.ResultInt := ShiftLeft(r.ResultInt, 1);
				NumInDenomFmt_v := PsiFixResize(r.NumComp, NumCompFmt_c, DenomCompFmt_c, PsiFixTrunc, PsiFixWrap);
				if unsigned(r.DenomComp) <= unsigned(NumInDenomFmt_v) then
					v.ResultInt(0) := '1';
					v.NumComp := PsiFixSub(r.NumComp, NumCompFmt_c, r.DenomComp, DenomCompFmt_c, NumCompFmt_c);
				end if;
				v.NumComp := PsiFixShiftLeft(v.NumComp, NumCompFmt_c, 1, 1, NumCompFmt_c, PsiFixTrunc, PsiFixSat);
				
			when Output_s => 
				v.State := Idle_s;
				v.OutVld := '1';
				v.InRdy := '1';
				if OutFmt_g.S = 1 then
					if r.NumSign /= r.DenomSign then
						v.OutQuot := PsiFixNeg(r.ResultInt, ResultIntFmt_c, OutFmt_g, Round_g, Sat_g);
					else
						v.OutQuot := PsiFixResize(r.ResultInt, ResultIntFmt_c, OutFmt_g, Round_g, Sat_g);
					end if;
				else
					v.OutQuot := PsiFixResize(r.ResultInt, ResultIntFmt_c, OutFmt_g, Round_g, Sat_g);
				end if;			
				
			when others => null;
		end case;		
		
		-- *** Assign to signal ***
		r_next <= v;
		
	end process;
	
	-- *** Outputs ***
	OutVld <= r.OutVld;
	OutQuot <= r.OutQuot;
	InRdy <= r.InRdy;
	
	--------------------------------------------
	-- Sequential Process
	--------------------------------------------
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then	
			r <= r_next;
			if Rst = '1' then	
				r.State <= Idle_s;
				r.OutVld <= '0';
				r.InRdy <= '0';
			end if;
		end if;
	end process;
end;	





