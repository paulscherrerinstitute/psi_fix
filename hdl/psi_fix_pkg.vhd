------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library psi_common;
	use psi_common.psi_common_math_pkg.all;
	use psi_common.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_fix_pkg is

	--------------------------------------------------------------------------
	-- Definitions
	--------------------------------------------------------------------------
	type PsiFixFmt_t is record
		S	: natural range 0 to 1;	-- Sign bit
		I	: integer;				-- Integer bits
		F	: integer;				-- Fractional bits
	end record;
	
	type PsiFixRnd_t is (PsiFixRound, PsiFixTrunc);
	
	type PsiFixSat_t is (PsiFixWrap, PsiFixSat);

	--------------------------------------------------------------------------
	-- Bittrue available in Python
	--------------------------------------------------------------------------	
	function PsiFixSize(	fmt : PsiFixFmt_t)
							return integer;

	function PsiFixFromReal(	a 		: real;
								rFmt	: PsiFixFmt_t) 
								return std_logic_vector;
							
	function PsiFixFromBitsAsInt(	a 		: integer;
									aFmt 	: PsiFixFmt_t)
									return std_logic_vector;
	
	function PsiFixGetBitsAsInt(	a		: std_logic_vector;
									aFmt	: PsiFixFmt_t)
									return integer;
								
	function PsiFixResize(	a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector;	
							
	function PsiFixAdd(	a		: std_logic_vector;
						aFmt	: PsiFixFmt_t;
						b		: std_logic_vector;
						bFmt	: PsiFixFmt_t;
						rFmt	: PsiFixFmt_t;
						rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
						sat		: PsiFixSat_t	:= PsiFixWrap) 
						return std_logic_vector;
						
	function PsiFixSub(	a		: std_logic_vector;
						aFmt	: PsiFixFmt_t;
						b		: std_logic_vector;
						bFmt	: PsiFixFmt_t;
						rFmt	: PsiFixFmt_t;
						rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
						sat		: PsiFixSat_t	:= PsiFixWrap) 
						return std_logic_vector;						
						
	function PsiFixMult(	a		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							b		: std_logic_vector;
							bFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector;

	function PsiFixAbs(		a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector;
							
	function PsiFixNeg(		a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector;	

	function PsiFixShiftLeft(	a 			: std_logic_vector;
								aFmt		: PsiFixFmt_t;
								shift		: integer;
								maxShift	: integer;
								rFmt		: PsiFixFmt_t;
								rnd			: PsiFixRnd_t 	:= PsiFixTrunc;
								sat			: PsiFixSat_t	:= PsiFixWrap;
								dynamic		: boolean		:= False) 
								return std_logic_vector;
								
	function PsiFixShiftRight(	a 			: std_logic_vector;
								aFmt		: PsiFixFmt_t;
								shift		: integer;
								maxShift	: integer;
								rFmt		: PsiFixFmt_t;
								rnd			: PsiFixRnd_t 	:= PsiFixTrunc;
								sat			: PsiFixSat_t	:= PsiFixWrap;
								dynamic		: boolean		:= False) 
								return std_logic_vector;	

	function PsiFixUpperBoundStdlv(	fmt 	: PsiFixFmt_t)
									return std_logic_vector;
									
	function PsiFixLowerBoundStdlv(	fmt 	: PsiFixFmt_t)
									return std_logic_vector;		

	function PsiFixUpperBoundReal(	fmt 	: PsiFixFmt_t)
									return real;
									
	function PsiFixLowerBoundReal(	fmt 	: PsiFixFmt_t)
									return real;	

	function PsiFixInRange(	a		: std_logic_vector;
							aFmt 	: PsiFixFmt_t;
							rFmt 	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc)
							return boolean;
								
	--------------------------------------------------------------------------
	-- VHDL Only
	--------------------------------------------------------------------------		
	function PsiFixToReal(	a		: std_logic_vector;
							aFmt	: PsiFixFmt_t) 
							return real;	
  
end psi_fix_pkg;	 

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_fix_pkg is 

	-- *** PsiFixSize ***
	function PsiFixSize(	fmt : PsiFixFmt_t)
							return integer is
	begin
		return fmt.S+fmt.I+fmt.F;
	end function;
  
	-- *** PsiFixFromReal ***
	function PsiFixFromReal(	a 		: real;
								rFmt	: PsiFixFmt_t) 
								return std_logic_vector is
		constant RealSft_c 	: real		:= a * 2.0**rFmt.F;
		constant Int_c		: integer	:= integer(RealSft_c);
		variable Stdlv_v	: std_logic_vector(PsiFixSize(rFmt)-1 downto 0);
	begin
		-- assertions
		assert (rFmt.S = 1) or (a >= 0.0) report "PsiFixFromReal: Unsigned format but negative number" severity error;
		-- implementation
		if rFmt.S = 1 then
			Stdlv_v := std_logic_vector(to_signed(Int_c, Stdlv_v'length));
		else
			Stdlv_v := std_logic_vector(to_unsigned(Int_c, Stdlv_v'length));
		end if;
		return Stdlv_v;
	end function;
	
	-- *** PsiFixToReal ***
	function PsiFixToReal(	a		: std_logic_vector;
							aFmt	: PsiFixFmt_t) 
							return real is
		variable IntValue_v	: integer;
		variable Real_v		: real;
		
	begin
		if aFmt.S = 1 then
			IntValue_v := to_integer(signed(a));
		else
			IntValue_v := to_integer(unsigned(a));
		end if;
		Real_v := real(IntValue_v);
		Real_v := Real_v / 2.0**aFmt.F;
		return Real_v;
	end function;
	
	-- *** PsiFixFromBitsAsInt ***
	function PsiFixFromBitsAsInt(	a 		: integer;
									aFmt 	: PsiFixFmt_t)
									return std_logic_vector is
	begin
		if aFmt.S = 1 then
			return std_logic_vector(to_signed(a, PsiFixSize(aFmt)));
		else
			return std_logic_vector(to_unsigned(a, PsiFixSize(aFmt)));
		end if;
	end function;
	
	-- *** PsiFixFromBitsAsInt ***
	function PsiFixGetBitsAsInt(	a		: std_logic_vector;
									aFmt	: PsiFixFmt_t)
									return integer is
	begin
		if aFmt.S = 1 then
			return to_integer(signed(a));
		else
			return to_integer(unsigned(a));
		end if;
	end function;
	
	-- *** PsiFixResize ***
	function PsiFixResize(	a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector is
		constant FullFmt_c		: PsiFixFmt_t := (max(aFmt.S, rFmt.S), max(aFmt.I, rFmt.I)+1, max(aFmt.F, rFmt.F));
		variable Full_v 		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0) := (others => '0');
		constant FullFracFmt_c	: PsiFixFmt_t := (aFmt.S, aFmt.I, FullFmt_c.F);
		variable FullFrac_v		: std_logic_vector(PsiFixSize(FullFracFmt_c)-1 downto 0) := (others => '0');
		constant NoFracFmt_c	: PsiFixFmt_t := (FullFmt_c.S, FullFmt_c.I, rFmt.F);
		variable NoFrac_v 		: std_logic_vector(PsiFixSize(NoFracFmt_c)-1 downto 0) := (others => '0');
		constant NoIntFmt_c		: PsiFixFmt_t := (FullFmt_c.S, rFmt.I, rFmt.F);
		variable NoInt_v 		: std_logic_vector(PsiFixSize(NoIntFmt_c)-1 downto 0) := (others => '0');
		variable IntSignExt_v	: std_logic_vector(NoFrac_v'left downto NoInt_v'left);
		variable CutBits_v		: std_logic_vector(NoFrac_v'left downto NoInt_v'left+1);
		variable NoSign_v		: std_logic_vector(PsiFixSize(rFmt)-1 downto 0);		
		variable RoundingConstant_v	: unsigned(PsiFixSize(FullFmt_c)-1 downto 0);
	begin
		-- assertions
		assert a'length = PsiFixSize(aFmt) report "PsiFixResize: Format does not match parameter" severity error;
		-- Convert to full format
		FullFrac_v(FullFrac_v'left downto FullFmt_c.F-aFmt.F) := a; 
		Full_v(FullFrac_v'left downto 0) := FullFrac_v;
		--Full_v(a'left+FullFmt_c.F-aFmt.F downto FullFmt_c.F-aFmt.F) :=	a;
		if aFmt.S = 1 then
			Full_v(Full_v'left downto FullFrac_v'left+1)	:= (others => a(a'left));
		end if;
		-- Remove fractional bits if required
		if rFmt.F < aFmt.F then			
			if rnd = PsiFixRound then
				RoundingConstant_v := to_unsigned(2**(aFmt.F-rFmt.F-1), RoundingConstant_v'length);
				Full_v := std_logic_vector(unsigned(Full_v) + RoundingConstant_v);
			end if;
			NoFrac_v := Full_v(Full_v'left downto Full_v'left-NoFrac_v'left);
		else
			NoFrac_v := Full_v;
		end if;
		-- Remove integer bits 
		NoInt_v := NoFrac_v(NoInt_v'left downto 0);
		if sat = PsiFixSat then				
			-- Signed satturation handling
			if aFmt.S = 1 then 		
				IntSignExt_v := (others => NoFrac_v(NoFrac_v'left));
				if NoFrac_v(NoFrac_v'left downto NoInt_v'left) /= IntSignExt_v then
					NoInt_v(NoInt_v'left) 				:= NoFrac_v(NoFrac_v'left);
					NoInt_v(NoInt_v'left-1 downto 0)	:= (others => not NoFrac_v(NoFrac_v'left));
				end if;
			-- Unsigned satturation handling
			else
				CutBits_v := NoFrac_v(NoFrac_v'left downto NoInt_v'left+1);
				if unsigned(CutBits_v) /= 0 then
					NoInt_v		:= (others => '1');
				end if;
			end if;
		end if;				

		-- Remove sign bit if required
		if rFmt.S < aFmt.S then
			NoSign_v := NoInt_v(NoSign_v'left downto 0);
			if sat = PsiFixSat then
				if NoInt_v(NoInt_v'left) = '1' then
					NoSign_v := (others => '0');
				end if;
			end if;
		else
			NoSign_v := NoInt_v;
		end if;
		
		return NoSign_v;
	end function;
	
	-- *** PsiFixAdd ***
	function PsiFixAdd(	a		: std_logic_vector;
						aFmt	: PsiFixFmt_t;
						b		: std_logic_vector;
						bFmt	: PsiFixFmt_t;
						rFmt	: PsiFixFmt_t;
						rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
						sat		: PsiFixSat_t	:= PsiFixWrap) 
						return std_logic_vector is
		constant FullFmt_c		: PsiFixFmt_t := (max(aFmt.S, bFmt.S), max(aFmt.I, bFmt.I)+1, max(aFmt.F, bFmt.F));
		constant FullA_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0) := PsiFixResize(a, aFmt, FullFmt_c);
		constant FullB_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0) := PsiFixResize(b, bFmt, FullFmt_c);
		variable FullAdd_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0);
	begin
		if FullFmt_c.S = 1 then
			FullAdd_v := std_logic_vector(signed(FullA_v) + signed(FullB_v));
		else
			FullAdd_v := std_logic_vector(unsigned(FullA_v) + unsigned(FullB_v));
		end if;
		return PsiFixResize(FullAdd_v, FullFmt_c, rFmt, rnd, sat);
	end function;
	
	-- *** PsiFixSub ***
	function PsiFixSub(	a		: std_logic_vector;
						aFmt	: PsiFixFmt_t;
						b		: std_logic_vector;
						bFmt	: PsiFixFmt_t;
						rFmt	: PsiFixFmt_t;
						rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
						sat		: PsiFixSat_t	:= PsiFixWrap) 
						return std_logic_vector is
		constant FullFmt_c		: PsiFixFmt_t := (1, max(aFmt.I, bFmt.I+bFmt.S), max(aFmt.F, bFmt.F));
		constant FullA_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0) := PsiFixResize(a, aFmt, FullFmt_c);
		constant FullB_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0) := PsiFixResize(b, bFmt, FullFmt_c);
		variable FullSub_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0);						
	begin
		if FullFmt_c.S = 1 then
			FullSub_v := std_logic_vector(signed(FullA_v) - signed(FullB_v));
		else
			FullSub_v := std_logic_vector(unsigned(FullA_v) - unsigned(FullB_v));
		end if;
		return PsiFixResize(FullSub_v, FullFmt_c, rFmt, rnd, sat);
	end function;
	
	-- *** PsiFixSub ***
	function PsiFixMult(	a		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							b		: std_logic_vector;
							bFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector is
		constant FullFmt_c		: PsiFixFmt_t := (1, aFmt.I+bFmt.I+1, aFmt.F + bFmt.F);
		variable Result_v		: std_logic_vector(PsiFixSize(FullFmt_c)-1 downto 0);
		constant InAFmt_c		: PsiFixFmt_t := (1, aFmt.I, aFmt.F);
		variable SignedA_v		: std_logic_vector(PsiFixSize(InAFmt_c)-1 downto 0);
		constant InBFmt_c		: PsiFixFmt_t := (1, bFmt.I, bFmt.F);
		variable SignedB_v		: std_logic_vector(PsiFixSize(InBFmt_c)-1 downto 0);
	begin
		SignedA_v := PsiFixResize(a, aFmt, InAFmt_c);
		SignedB_v := PsiFixResize(b, bFmt, InBFmt_c);
		Result_v := std_logic_vector(signed(SignedA_v)*signed(SignedB_v));
		return PsiFixResize(std_logic_vector(Result_v), FullFmt_c, rFmt, rnd, sat);
	end function;
	
	-- *** PsiFixAbs ***
	function PsiFixAbs(		a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector is
		constant AFullFmt_c	: PsiFixFmt_t := (1, aFmt.I+aFmt.S, aFmt.F);
		variable AFull_v	: std_logic_vector(PsiFixSize(AFullFmt_c)-1 downto 0);
		variable Neg_v		: std_logic_vector(PsiFixSize(AFullFmt_c)-1 downto 0);
	begin
		AFull_v := PsiFixResize(a, aFmt, AFullFmt_c);
		if signed(AFull_v) < 0 then
			Neg_v	:= std_logic_vector(-signed(AFull_v));
		else
			Neg_v 	:= AFull_v;
		end if;
		return PsiFixResize(Neg_v, AFullFmt_c, rFmt, rnd, sat);
	end function;
	
	-- *** PsiFixNeg ***
	function PsiFixNeg(		a 		: std_logic_vector;
							aFmt	: PsiFixFmt_t;
							rFmt	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc;
							sat		: PsiFixSat_t	:= PsiFixWrap) 
							return std_logic_vector is
		constant AFullFmt_c	: PsiFixFmt_t := (1, aFmt.I+aFmt.S, aFmt.F);
		variable AFull_v	: std_logic_vector(PsiFixSize(AFullFmt_c)-1 downto 0);
		variable Neg_v		: std_logic_vector(PsiFixSize(AFullFmt_c)-1 downto 0);
	begin
		AFull_v := PsiFixResize(a, aFmt, AFullFmt_c);
		Neg_v	:= std_logic_vector(-signed(AFull_v));
		return PsiFixResize(Neg_v, AFullFmt_c, rFmt, rnd, sat);
	end function;	
	
	-- *** PsiFixShiftLeft ***
	function PsiFixShiftLeft(	a 			: std_logic_vector;
								aFmt		: PsiFixFmt_t;
								shift		: integer;
								maxShift	: integer;
								rFmt		: PsiFixFmt_t;
								rnd			: PsiFixRnd_t 	:= PsiFixTrunc;
								sat			: PsiFixSat_t	:= PsiFixWrap;
								dynamic		: boolean		:= False) 
								return std_logic_vector is
		constant FullFmt_c	: PsiFixFmt_t	:= (max(aFmt.S, rFmt.S), max(aFmt.I+maxShift, rFmt.I), max(aFmt.F, rFmt.F));
		variable FullA_v	: std_logic_vector(PsiFixsize(FullFmt_c)-1 downto 0);
		variable FullOut_v	: std_logic_vector(FullA_v'range);
	begin
		assert shift >= 0 report "PsiFixShiftLeft: Shift must be >= 0" severity error;
		assert shift <= maxShift report "PsiFixShiftLeft: Shift must be <= maxShift" severity error;
		FullA_v 	:= PsiFixResize(a, aFmt, FullFmt_c);
		if not dynamic then
			FullOut_v	:= ShiftLeft(FullA_v, shift);
		else
			for i in 0 to maxShift loop
				if i = shift then
					FullOut_v	:= ShiftLeft(FullA_v, i);
				end if;
			end loop;
		end if;
		return PsiFixResize(FullOut_v, FullFmt_c, rFmt, rnd, sat);
	end function;
	
	-- *** PsiFixShiftRight ***
	function PsiFixShiftRight(	a 			: std_logic_vector;
								aFmt		: PsiFixFmt_t;
								shift		: integer;
								maxShift	: integer;
								rFmt		: PsiFixFmt_t;
								rnd			: PsiFixRnd_t 	:= PsiFixTrunc;
								sat			: PsiFixSat_t	:= PsiFixWrap;
								dynamic		: boolean		:= False) 
								return std_logic_vector is
		constant FullFmt_c	: PsiFixFmt_t	:= (max(aFmt.S, rFmt.S), max(aFmt.I, rFmt.I), max(aFmt.F+maxShift, rFmt.F+1));	-- Additional bit for rounding
		variable FullA_v	: std_logic_vector(PsiFixsize(FullFmt_c)-1 downto 0);
		variable FullOut_v	: std_logic_vector(FullA_v'range);
	begin
		assert shift >= 0 report "PsiFixShiftRight: Shift must be >= 0" severity error;
		assert shift <= maxShift report "PsiFixShiftRight: Shift must be <= maxShift" severity error;
		FullA_v 	:= PsiFixResize(a, aFmt, FullFmt_c);
		if not dynamic then
			if aFmt.S = 1 then
				FullOut_v	:= ShiftRight(FullA_v, shift, FullA_v(FullA_v'left));
			else
				FullOut_v	:= ShiftRight(FullA_v, shift, '0');
			end if;
		else
			for i in 0 to maxShift loop	-- make a loop to ensure the shift is a constant (required by the tools)
				if i = shift then
					if aFmt.S = 1 then
						FullOut_v	:= ShiftRight(FullA_v, i, FullA_v(FullA_v'left));
					else
						FullOut_v	:= ShiftRight(FullA_v, i, '0');
					end if;
				end if;
			end loop;		
		end if;
		return PsiFixResize(FullOut_v, FullFmt_c, rFmt, rnd, sat);
	end function;	
	
	-- *** PsiFixUpperBoundStdlv ***
	function PsiFixUpperBoundStdlv(	fmt 	: PsiFixFmt_t)
									return std_logic_vector is
	begin
		if fmt.S = 1 then
			return '0' & OnesVector(PsiFixSize(fmt)-1);
		else
			return OnesVector(PsiFixSize(fmt));
		end if;
	end function;
	
	-- *** PsiFixLowerBoundStdlv ***	
	function PsiFixLowerBoundStdlv(	fmt 	: PsiFixFmt_t)
									return std_logic_vector is
	begin
		if fmt.S = 1 then
			return '1' & ZerosVector(PsiFixSize(fmt)-1);
		else
			return ZerosVector(PsiFixSize(fmt));
		end if;
	end function;
	
	-- *** PsiFixUpperBoundReal ***
	function PsiFixUpperBoundReal(	fmt 	: PsiFixFmt_t)
									return real is
	begin
		return 2.0**real(fmt.I)-2.0**real(-fmt.F);
	end function;
		
	-- *** PsiFixLowerBoundReal ***
	function PsiFixLowerBoundReal(	fmt 	: PsiFixFmt_t)
									return real is
	begin
		if fmt.S = 1 then
			return -(2.0**real(fmt.I));
		else
			return 0.0;
		end if;
	end function;
	
	-- *** PsiFixInRange ***
	function PsiFixInRange(	a		: std_logic_vector;
							aFmt 	: PsiFixFmt_t;
							rFmt 	: PsiFixFmt_t;
							rnd		: PsiFixRnd_t 	:= PsiFixTrunc)
							return boolean is
		constant RndFmt_c		: PsiFixFmt_t	:= (1, max(aFmt.I+1, rFmt.I), max(aFmt.F, rFmt.F));
		variable ValRnd_v		: std_logic_vector(PsiFixSize(RndFmt_c)-1 downto 0);
		constant UpperBound_c	: std_logic_vector(PsiFixSize(RndFmt_c)-1 downto 0) := PsiFixResize(PsiFixUpperBoundStdlv(rFmt), rFmt, RndFmt_c);
		constant LowerBound_c	: std_logic_vector(PsiFixSize(RndFmt_c)-1 downto 0) := PsiFixResize(PsiFixLowerBoundStdlv(rFmt), rFmt, RndFmt_c);
	begin
		ValRnd_v	:= PsiFixResize(a, aFmt, RndFmt_c, rnd);
		return (signed(ValRnd_v) <= signed(UpperBound_c)) and (signed(ValRnd_v) >= signed(LowerBound_c));
	end function;
	
	
end psi_fix_pkg;





