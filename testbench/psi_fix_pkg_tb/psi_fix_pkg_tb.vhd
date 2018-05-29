------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library psi_tb;
	use work.psi_fix_pkg.all;
	use psi_tb.psi_tb_txt_util.all;
	

entity psi_fix_pkg_tb is
end entity psi_fix_pkg_tb;

architecture sim of psi_fix_pkg_tb is

	procedure CheckStdlv(	expected : std_logic_vector;
							actual	 : std_logic_vector;
							msg		 : string) is
	begin
		assert expected = actual
			report "###ERROR### " & msg & " [expected: " & str(expected) & ", got: " & str(actual) & "]"
			severity error;
	end procedure;
	
	procedure CheckInt(	expected : integer;
						actual	 : integer;
						msg		 : string) is
	begin
		assert expected = actual
			report "###ERROR### " & msg & " [expected: " & str(expected) & ", got: " & str(actual) & "]"
			severity error;
	end procedure;	
	
	procedure CheckReal(	expected : real;
							actual	 : real;
							msg		 : string) is
	begin
		assert expected = actual
			report "###ERROR### " & msg & " [expected: " & real'image(expected) & ", got: " & real'image(actual) & "]"
			severity error;
	end procedure;		
	
	procedure CheckBoolean(	expected : boolean;
							actual	 : boolean;
							msg		 : string) is
	begin
		assert expected = actual
			report "###ERROR### " & msg & " [expected: " & boolean'image(expected) & ", got: " & boolean'image(actual) & "]"
			severity error;
	end procedure;			

begin

	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
	begin
		-- *** PsiFixSize ***
		print("*** PsiFixSize ***");
		CheckInt(3, PsiFixSize((0, 3, 0)), "PsiFixSize Wrong: Integer only, Unsigned, NoFractional Bits");
		CheckInt(4, PsiFixSize((1, 3, 0)), "PsiFixSize Wrong: Integer only, Signed, NoFractional Bits");
		CheckInt(3, PsiFixSize((0, 0, 3)), "PsiFixSize Wrong: Fractional only, Unsigned, No Integer Bits");
		CheckInt(4, PsiFixSize((1, 0, 3)), "PsiFixSize Wrong: Fractional only, Signed, No Integer Bits");
		CheckInt(7, PsiFixSize((1, 3, 3)), "PsiFixSize Wrong: Integer and Fractional Bits");
		CheckInt(2, PsiFixSize((1, -2, 3)), "PsiFixSize Wrong: Negative integer bits");
		CheckInt(2, PsiFixSize((1, 3, -2)), "PsiFixSize Wrong: Negative fractional bits");
	
		-- *** PsiFixFromReal ***
		print("*** PsiFixFromReal ***");
		CheckStdlv(	"0011", 	
					PsiFixFromReal(	3.0, (1, 3, 0)), 
					"FixFromReal Wrong: Integer only, Signed, NoFractional Bits, Positive");
		CheckStdlv(	"1101", 	
					PsiFixFromReal(	-3.0, (1, 3, 0)), 
					"FixFromReal Wrong: Integer only, Signed, NoFractional Bits, Negative");			
		CheckStdlv(	"011", 	
					PsiFixFromReal(	3.0, (0, 3, 0)), 
					"FixFromReal Wrong: Integer only, Unsigned, NoFractional Bits, Positive");
		CheckStdlv(	"110011", 	
					PsiFixFromReal(	-3.25, (1, 3, 2)), 
					"FixFromReal Wrong: Integer and Fractional");	
		CheckStdlv(	"11010", 	
					PsiFixFromReal(	-3.24, (1, 3, 1)), 
					"FixFromReal Wrong: Rounding");	
		CheckStdlv(	"01", 	
					PsiFixFromReal(	0.125, (0, -1, 3)), 
					"FixFromReal Wrong: Negative Integer Bits");	
		CheckStdlv(	"010", 	
					PsiFixFromReal(	4.0, (1, 3, -1)), 
					"FixFromReal Wrong: Negative Fractional Bits");	
					
		-- *** PsiFixToReal ***
		print("*** PsiFixToReal ***");
		CheckReal(	3.0, 	
					PsiFixToReal(PsiFixFromReal(	3.0, (1, 3, 0)), (1, 3, 0)), 
					"PsiFixToReal Wrong: Integer only, Signed, NoFractional Bits, Positive");
		CheckReal(	-3.0, 	
					PsiFixToReal(PsiFixFromReal(	-3.0, (1, 3, 0)), (1, 3, 0)),
					"PsiFixToReal Wrong: Integer only, Signed, NoFractional Bits, Negative");			
		CheckReal(	3.0, 	
					PsiFixToReal(PsiFixFromReal(	3.0, (0, 3, 0)), (0, 3, 0)),
					"PsiFixToReal Wrong: Integer only, Unsigned, NoFractional Bits, Positive");
		CheckReal(	-3.25, 	
					PsiFixToReal(PsiFixFromReal(	-3.25, (1, 3, 2)), (1, 3, 2)),
					"PsiFixToReal Wrong: Integer and Fractional");	
		CheckReal(	-3.0, 	
					PsiFixToReal(PsiFixFromReal(	-3.24, (1, 3, 1)), (1, 3, 1)),
					"PsiFixToReal Wrong: Rounding");	
		CheckReal(	0.125, 	
					PsiFixToReal(PsiFixFromReal(	0.125, (0, -1, 3)), (0, -1, 3)),
					"PsiFixToReal Wrong: Negative Integer Bits");	
		CheckReal(	4.0, 	
					PsiFixToReal(PsiFixFromReal(	4.0, (1, 3, -1)), (1, 3, -1)),
					"PsiFixToReal Wrong: Negative Fractional Bits");		
					
		-- *** PsiFixFromBitsAsInt ***
		print("*** PsiFixFromBitsAsInt ***");
		CheckStdlv("0011", PsiFixFromBitsAsInt(3, (0, 4, 0)), "PsiFixFromBitsAsInt: Unsigned Positive");
		CheckStdlv("0011", PsiFixFromBitsAsInt(3, (1, 3, 0)), "PsiFixFromBitsAsInt: Signed Positive");
		CheckStdlv("1101", PsiFixFromBitsAsInt(-3, (1, 3, 0)), "PsiFixFromBitsAsInt: Signed Negative");
		CheckStdlv("1101", PsiFixFromBitsAsInt(-3, (1, 1, 2)), "PsiFixFromBitsAsInt: Fractional"); -- binary point position is not important
		CheckStdlv("0001", PsiFixFromBitsAsInt(17, (0, 4, 0)), "PsiFixFromBitsAsInt: Wrap Unsigned");		
		
		-- *** PsiFixGetBitsAsInt ***
		print("*** PsiFixGetBitsAsInt ***");
		CheckInt(3, PsiFixGetBitsAsInt("11", (0,2,0)), "PsiFixGetBitsAsInt: Unsigned Positive");
		CheckInt(3, PsiFixGetBitsAsInt("011", (1,2,0)), "PsiFixGetBitsAsInt: Signed Positive");
		CheckInt(-3, PsiFixGetBitsAsInt("1101", (1,3,0)), "PsiFixGetBitsAsInt: Signed Negative");
		CheckInt(-3, PsiFixGetBitsAsInt("1101", (1,1,2)), "PsiFixGetBitsAsInt: Fractional"); -- binary point position is not important

		-- *** PsiFixResize ***
		print("*** PsiFixResize ***");
		CheckStdlv(	"0101", PsiFixResize("0101", (1, 2, 1), (1, 2, 1)), 
					"PsiFixResize: No formatchange");
					
		CheckStdlv(	"010", PsiFixResize("0101", (1, 2, 1), (1, 2, 0), PsiFixTrunc), 
					"PsiFixResize: Remove Frac Bit 1 Trunc");
		CheckStdlv(	"011", PsiFixResize("0101", (1, 2, 1), (1, 2, 0), PsiFixRound), 
					"PsiFixResize: Remove Frac Bit 1 Round");
		CheckStdlv(	"010", PsiFixResize("0100", (1, 2, 1), (1, 2, 0), PsiFixTrunc), 
					"PsiFixResize: Remove Frac Bit 0 Trunc");
		CheckStdlv(	"010", PsiFixResize("0100", (1, 2, 1), (1, 2, 0), PsiFixRound), 
					"PsiFixResize: Remove Frac Bit 0 Round");	
					
		CheckStdlv(	"01000", PsiFixResize("0100", (1, 2, 1), (1, 2, 2), PsiFixRound), 
					"PsiFixResize: Add Fractional Bit Signed");	
		CheckStdlv(	"1000", PsiFixResize("100", (0, 2, 1), (0, 2, 2), PsiFixRound), 
					"PsiFixResize: Add Fractional Bit Unsigned");	

		CheckStdlv(	"0111", PsiFixResize("00111", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Integer Bit, Signed, NoSat, Positive");
		CheckStdlv(	"1001", PsiFixResize("11001", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixSat), 
					"PsiFixResize: Remove Integer Bit, Signed, NoSat, Negative");
		CheckStdlv(	"1011", PsiFixResize("01011", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Integer Bit, Signed, Wrap, Positive");
		CheckStdlv(	"0011", PsiFixResize("10011", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Integer Bit, Signed, Wrap, Negative");			
		CheckStdlv(	"0111", PsiFixResize("01011", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixSat), 
					"PsiFixResize: Remove Integer Bit, Signed, Sat, Positive");
		CheckStdlv(	"1000", PsiFixResize("10011", (1, 3, 1), (1, 2, 1), PsiFixTrunc, PsiFixSat), 
					"PsiFixResize: Remove Integer Bit, Signed, Sat, Negative");
					
		CheckStdlv(	"111", PsiFixResize("0111", (0, 3, 1), (0, 2, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Integer Bit, Unsigned, NoSat, Positive");
		CheckStdlv(	"011", PsiFixResize("1011", (0, 3, 1), (0, 2, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Integer Bit, Unsigned, Wrap, Positive");		
		CheckStdlv(	"111", PsiFixResize("1011", (0, 3, 1), (0, 2, 1), PsiFixTrunc, PsiFixSat), 
					"PsiFixResize: Remove Integer Bit, Unsigned, Sat, Positive");					
					
		CheckStdlv(	"0111", PsiFixResize("00111", (1, 3, 1), (0, 3, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Sign Bit, Signed, NoSat, Positive");
		CheckStdlv(	"0011", PsiFixResize("10011", (1, 3, 1), (0, 3, 1), PsiFixTrunc, PsiFixWrap), 
					"PsiFixResize: Remove Sign Bit, Signed, Wrap, Negative");			
		CheckStdlv(	"0000", PsiFixResize("10011", (1, 3, 1), (0, 3, 1), PsiFixTrunc, PsiFixSat), 
					"PsiFixResize: Remove Sign Bit, Signed, Sat, Negative");

		CheckStdlv(	"1000", PsiFixResize("01111", (1, 3, 1), (1, 3, 0), PsiFixRound, PsiFixWrap), 
					"PsiFixResize: Overflow due rounding, Signed, Wrap");
		CheckStdlv(	"0111", PsiFixResize("01111", (1, 3, 1), (1, 3, 0), PsiFixRound, PsiFixSat), 
					"PsiFixResize: Overflow due rounding, Signed, Sat");
		CheckStdlv(	"000", PsiFixResize("1111", (0, 3, 1), (0, 3, 0), PsiFixRound, PsiFixWrap), 
					"PsiFixResize: Overflow due rounding, Unsigned, Wrap");
		CheckStdlv(	"111", PsiFixResize("1111", (0, 3, 1), (0, 3, 0), PsiFixRound, PsiFixSat), 
					"PsiFixResize: Overflow due rounding, Unsigned, Sat");
					
		-- error cases
		CheckStdlv(	"0000101000", PsiFixResize(PsiFixFromReal(2.5, (0, 5, 4)), (0, 5, 4), (0, 6, 4)), 
					"PsiFixResize: Overflow due rounding, Unsigned, Sat");
		CheckStdlv(	"000010100", PsiFixResize(PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3), (0, 5, 4)), 
					"PsiFixResize: Overflow due rounding, Unsigned, Sat");
						
		-- *** PsiFixAdd ***
		print("*** PsiFixAdd ***");					
		CheckStdlv(	PsiFixFromReal(-2.5+1.25, (1, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(-2.5, (1, 5, 3)), (1, 5, 3),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixAdd: Same Fmt Signed");	
		CheckStdlv(	PsiFixFromReal(2.5+1.25, (0, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(2.5, (0, 5, 3)), (0, 5, 3),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixAdd: Same Fmt Usigned");		
		CheckStdlv(	PsiFixFromReal(-2.5+1.25, (1, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(-2.5, (1, 6, 3)), (1, 6, 3),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixAdd: Different Int Bits Signed");	
		CheckStdlv(	PsiFixFromReal(2.5+1.25, (0, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(2.5, (0, 6, 3)), (0, 6, 3),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixAdd: Different Int Bits Usigned");	
		CheckStdlv(	PsiFixFromReal(-2.5+1.25, (1, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(-2.5, (1, 5, 4)), (1, 5, 4),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixAdd: Different Frac Bits Signed");	
		CheckStdlv(	PsiFixFromReal(2.5+1.25, (0, 5, 3)), 
					PsiFixAdd(	PsiFixFromReal(2.5, (0, 5, 4)), (0, 5, 4),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixAdd: Different Frac Bits Usigned");	
		CheckStdlv(	PsiFixFromReal(0.75+4.0, (0, 5, 5)), 
					PsiFixAdd(	PsiFixFromReal(0.75, (0, 0, 4)), (0, 0, 4),
								PsiFixFromReal(4.0, (0, 4, -1)), (0, 4, -1),
								(0, 5, 5)),
					"PsiFixAdd: Different Ranges Unsigned");	
		CheckStdlv(	PsiFixFromReal(5.0, (0, 5, 0)), 
					PsiFixAdd(	PsiFixFromReal(0.75, (0, 0, 4)), (0, 0, 4),
								PsiFixFromReal(4.0, (0, 4, -1)), (0, 4, -1),
								(0, 5, 0), PsiFixRound),
					"PsiFixAdd: Round");		
		CheckStdlv(	PsiFixFromReal(15.0, (0, 4, 0)), 
					PsiFixAdd(	PsiFixFromReal(0.75, (0, 0, 4)), (0, 0, 4),
								PsiFixFromReal(15.0, (0, 4, 0)), (0, 4, 0),
								(0, 4, 0), PsiFixRound, PsiFixSat),
					"PsiFixAdd: Satturate");
					
		-- *** PsiFixSub ***
		print("*** PsiFixSub ***");					
		CheckStdlv(	PsiFixFromReal(-2.5-1.25, (1, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(-2.5, (1, 5, 3)), (1, 5, 3),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixSub: Same Fmt Signed");	
		CheckStdlv(	PsiFixFromReal(2.5-1.25, (0, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(2.5, (0, 5, 3)), (0, 5, 3),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixSub: Same Fmt Usigned");		
		CheckStdlv(	PsiFixFromReal(-2.5-1.25, (1, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(-2.5, (1, 6, 3)), (1, 6, 3),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixSub: Different Int Bits Signed");	
		CheckStdlv(	PsiFixFromReal(2.5-1.25, (0, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(2.5, (0, 6, 3)), (0, 6, 3),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixSub: Different Int Bits Usigned");	
		CheckStdlv(	PsiFixFromReal(-2.5-1.25, (1, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(-2.5, (1, 5, 4)), (1, 5, 4),
								PsiFixFromReal(1.25, (1, 5, 3)), (1, 5, 3),
								(1, 5, 3)),
					"PsiFixSub: Different Frac Bits Signed");	
		CheckStdlv(	PsiFixFromReal(2.5-1.25, (0, 5, 3)), 
					PsiFixSub(	PsiFixFromReal(2.5, (0, 5, 4)), (0, 5, 4),
								PsiFixFromReal(1.25, (0, 5, 3)), (0, 5, 3),
								(0, 5, 3)),
					"PsiFixSub: Different Frac Bits Usigned");	
		CheckStdlv(	PsiFixFromReal(4.0-0.75, (0, 5, 5)), 
					PsiFixSub(	PsiFixFromReal(4.0, (0, 4, -1)), (0, 4, -1),	
								PsiFixFromReal(0.75, (0, 0, 4)), (0, 0, 4),								
								(0, 5, 5)),
					"PsiFixSub: Different Ranges Unsigned");	
		CheckStdlv(	PsiFixFromReal(4.0, (0, 5, 0)), 
					PsiFixSub(	PsiFixFromReal(4.0, (0, 4, -1)), (0, 4, -1),
								PsiFixFromReal(0.25, (0, 0, 4)), (0, 0, 4),								
								(0, 5, 0), PsiFixRound),
					"PsiFixSub: Round");		
		CheckStdlv(	PsiFixFromReal(0.0, (0, 4, 0)), 
					PsiFixSub(	PsiFixFromReal(0.75, (0, 0, 4)), (0, 0, 4),
								PsiFixFromReal(5.0, (0, 4, 0)), (0, 4, 0),
								(0, 4, 0), PsiFixRound, PsiFixSat),
					"PsiFixSub: Satturate");
		CheckStdlv(	PsiFixFromReal(-16.0, (1, 4, 0)), 
					PsiFixSub(	PsiFixFromReal(0.0, (1, 4, 0)), (1, 4, 0),
								PsiFixFromReal(-16.0, (1, 4, 0)), (1, 4, 0),
								(1, 4, 0), PsiFixRound, PsiFixWrap),
					"PsiFixSub: Invert most negative signed, noSat");
		CheckStdlv(	PsiFixFromReal(15.0, (1, 4, 0)), 
					PsiFixSub(	PsiFixFromReal(0.0, (1, 4, 0)), (1, 4, 0),
								PsiFixFromReal(-16.0, (1, 4, 0)), (1, 4, 0),
								(1, 4, 0), PsiFixRound, PsiFixSat),
					"PsiFixSub: Invert most negative signed, Sat");		
		CheckStdlv(	PsiFixFromReal(0.0, (0, 4, 0)), 
					PsiFixSub(	PsiFixFromReal(0.0, (0, 4, 0)), (0, 4, 0),
								PsiFixFromReal(16.0, (0, 4, 0)), (0, 4, 0),
								(0, 4, 0), PsiFixRound, PsiFixWrap),
					"PsiFixSub: Invert most negative unsigned, noSat");
		CheckStdlv(	PsiFixFromReal(0.0, (0, 4, 0)), 
					PsiFixSub(	PsiFixFromReal(0.0, (0, 4, 0)), (0, 4, 0),
								PsiFixFromReal(15.0, (0, 4, 0)), (0, 4, 0),
								(0, 4, 0), PsiFixRound, PsiFixSat),
					"PsiFixSub: Invert unsigned, Sat");	

		-- *** PsiFixMult ***
		print("*** PsiFixMult ***");					
		CheckStdlv(	PsiFixFromReal(2.5*1.25, (0, 5, 5)), 
					PsiFixMult(	PsiFixFromReal(2.5, (0, 5, 1)), (0, 5, 1),
								PsiFixFromReal(1.25, (0, 5, 2)), (0, 5, 2),
								(0, 5, 5)),
					"PsiFixMult: A unsigned positive, B unsigned positive");		
		CheckStdlv(	PsiFixFromReal(2.5*1.25, (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (1, 2, 1)), (1, 2, 1),
								PsiFixFromReal(1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A signed positive, B signed positive");	
		CheckStdlv(	PsiFixFromReal(2.5*(-1.25), (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (1, 2, 1)), (1, 2, 1),
								PsiFixFromReal(-1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A signed positive, B signed negative");	
		CheckStdlv(	PsiFixFromReal((-2.5)*1.25, (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(-2.5, (1, 2, 1)), (1, 2, 1),
								PsiFixFromReal(1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A signed negative, B signed positive");		
		CheckStdlv(	PsiFixFromReal((-2.5)*(-1.25), (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(-2.5, (1, 2, 1)), (1, 2, 1),
								PsiFixFromReal(-1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A signed negative, B signed negative");
		CheckStdlv(	PsiFixFromReal(2.5*1.25, (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (0, 2, 1)), (0, 2, 1),
								PsiFixFromReal(1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A unsigned positive, B signed positive");
		CheckStdlv(	PsiFixFromReal(2.5*(-1.25), (1, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (0, 2, 1)), (0, 2, 1),
								PsiFixFromReal(-1.25, (1, 1, 2)), (1, 1, 2),
								(1, 3, 3)),
					"PsiFixMult: A unsigned positive, B signed negative");	
		CheckStdlv(	PsiFixFromReal(2.5*1.25, (0, 3, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (0, 2, 1)), (0, 2, 1),
								PsiFixFromReal(1.25, (1, 1, 2)), (1, 1, 2),
								(0, 3, 3)),
					"PsiFixMult: A unsigned positive, B signed positive, result unsigned");			
		CheckStdlv(	PsiFixFromReal(1.875, (0, 1, 3)), 
					PsiFixMult(	PsiFixFromReal(2.5, (0, 2, 1)), (0, 2, 1),
								PsiFixFromReal(1.25, (1, 1, 2)), (1, 1, 2),
								(0, 1, 3), PsiFixTrunc, PsiFixSat),
					"PsiFixMult: A unsigned positive, B signed positive, saturate");			

		-- *** PsiFixAbs ***
		print("*** PsiFixMult ***");					
		CheckStdlv(	PsiFixFromReal(2.5, (0, 5, 5)), 
					PsiFixAbs(	PsiFixFromReal(2.5, (0, 5, 1)), (0, 5, 1),
								(0, 5, 5)),
					"PsiFixAbs: positive stay positive");		
		CheckStdlv(	PsiFixFromReal(4.0, (1, 3, 3)), 
					PsiFixAbs(	PsiFixFromReal(-4.0, (1, 2, 2)), (1, 2, 2),
								(1, 3, 3)),
					"PsiFixAbs: negative becomes positive");	
		CheckStdlv(	PsiFixFromReal(3.75, (1, 2, 2)), 
					PsiFixAbs(	PsiFixFromReal(-4.0, (1, 2, 2)), (1, 2, 2),
								(1, 2, 2), PsiFixTrunc, PsiFixSat),
					"PsiFixAbs: most negative value sat");		
					
		-- *** PsiFixNeg ***
		print("*** PsiFixNeg ***");
		CheckStdlv(	PsiFixFromReal(-2.5, (1, 5, 5)), 
					PsiFixNeg(	PsiFixFromReal(2.5, (1, 5, 1)), (1, 5, 1),
								(1, 5, 5)),
					"PsiFixNeg: positive to negative (signed -> signed)");	
		CheckStdlv(	PsiFixFromReal(-2.5, (1, 5, 5)), 
					PsiFixNeg(	PsiFixFromReal(2.5, (0, 5, 1)), (0, 5, 1),
								(1, 5, 5)),
					"PsiFixNeg: positive to negative (unsigned -> signed)");	
		CheckStdlv(	PsiFixFromReal(2.5, (1, 5, 5)), 
					PsiFixNeg(	PsiFixFromReal(-2.5, (1, 5, 1)), (1, 5, 1),
								(1, 5, 5)),
					"PsiFixNeg: negative to positive (signed -> signed)");			
		CheckStdlv(	PsiFixFromReal(2.5, (0, 5, 5)), 
					PsiFixNeg(	PsiFixFromReal(-2.5, (1, 5, 1)), (1, 5, 1),
								(0, 5, 5)),
					"PsiFixNeg: negative to positive (signed -> unsigned)");		
		CheckStdlv(	PsiFixFromReal(3.75, (1, 2, 2)), 
					PsiFixNeg(	PsiFixFromReal(-4.0, (1, 2, 4)), (1, 2, 4),
								(1, 2, 2), PsiFixTrunc, PsiFixSat),
					"PsiFixNeg: saturation (signed -> signed)");			
		CheckStdlv(	PsiFixFromReal(-4.0, (1, 2, 2)), 
					PsiFixNeg(	PsiFixFromReal(-4.0, (1, 2, 4)), (1, 2, 4),
								(1, 2, 2), PsiFixTrunc, PsiFixWrap),
					"PsiFixNeg: wrap (signed -> signed)");	
		CheckStdlv(	PsiFixFromReal(0.0, (0, 5, 5)), 
					PsiFixNeg(	PsiFixFromReal(2.5, (1, 5, 1)), (1, 5, 1),
								(0, 5, 5), PsiFixTrunc, PsiFixSat),
					"PsiFixNeg: positive to negative saturate (signed -> unsigned)");	
		
		-- *** PsiFixShiftLeft ***
		print("*** PsiFixShiftLeft ***");
		CheckStdlv(	PsiFixFromReal(2.5, (0, 3, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(1.25, (0, 3, 2)),	(0, 3, 2),
										1, 10,
										(0, 3, 2)),
										"Shift same format unsigned");
		CheckStdlv(	PsiFixFromReal(2.5, (1, 3, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(1.25, (1, 3, 2)),	(1, 3, 2),
										1, 10,
										(1, 3, 2)),
										"Shift same format signed");			
		CheckStdlv(	PsiFixFromReal(2.5, (0, 3, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(1.25, (1, 1, 2)),	(1, 1, 2),
										1, 10,
										(0, 3, 2)),
										"Shift format change");	
		CheckStdlv(	PsiFixFromReal(3.75, (1, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(2.0, (1, 2, 2)),	(1, 2, 2),
										1, 10,
										(1, 2, 2), PsiFixTrunc, PsiFixSat),
										"saturation signed");
		CheckStdlv(	PsiFixFromReal(3.75, (1, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(2.0, (0, 3, 2)),	(0, 3, 2),
										1, 10,
										(1, 2, 2), PsiFixTrunc, PsiFixSat),
										"saturation unsigned to signed");		
		CheckStdlv(	PsiFixFromReal(0.0, (0, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(-0.5, (1, 3, 2)),	(1, 3, 2),
										1, 10,
										(0, 2, 2), PsiFixTrunc, PsiFixSat),
										"saturation signed to unsigned");		
		CheckStdlv(	PsiFixFromReal(-4.0, (1, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(2.0, (1, 2, 2)),	(1, 2, 2),
										1, 10,
										(1, 2, 2), PsiFixTrunc, PsiFixWrap),
										"wrap signed");		
		CheckStdlv(	PsiFixFromReal(-4.0, (1, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(2.0, (0, 3, 2)),	(0, 3, 2),
										1, 10,
										(1, 2, 2), PsiFixTrunc, PsiFixWrap),
										"wrap unsigned to signed");	
		CheckStdlv(	PsiFixFromReal(3.0, (0, 2, 2)), 
					PsiFixShiftLeft(	PsiFixFromReal(-0.5, (1, 3, 2)), (1, 3, 2),
										1, 10,
										(0, 2, 2), PsiFixTrunc, PsiFixWrap),
										"wrap signed to unsigned");	
		CheckStdlv(	PsiFixFromReal(0.5, (1, 5, 5)), 
					PsiFixShiftLeft(	PsiFixFromReal(0.5, (1, 5, 5)), (1, 5, 5),
										0, 10,
										(1, 5, 5), PsiFixTrunc, PsiFixWrap),
										"shift 0");		
		CheckStdlv(	PsiFixFromReal(-4.0, (1, 5, 5)), 
					PsiFixShiftLeft(	PsiFixFromReal(-0.5, (1, 5, 5)), (1, 5, 5),
										3, 10,
										(1, 5, 5), PsiFixTrunc, PsiFixWrap),
										"shift 3");			
		
		-- *** PsiFixShiftRight ***
		print("*** PsiFixShiftRight ***");
		CheckStdlv(	PsiFixFromReal(1.25, (0, 3, 2)), 
					PsiFixShiftRight(	PsiFixFromReal(2.5, (0, 3, 2)),	(0, 3, 2),
										1, 10,
										(0, 3, 2)),
										"Shift same format unsigned");
		CheckStdlv(	PsiFixFromReal(1.25, (1, 3, 2)), 
					PsiFixShiftRight(	PsiFixFromReal(2.5, (1, 3, 2)),	(1, 3, 2),
										1, 10,
										(1, 3, 2)),
										"Shift same format signed");			
		CheckStdlv(	PsiFixFromReal(1.25, (1, 1, 2)), 
					PsiFixShiftRight(	PsiFixFromReal(2.5, (0, 3, 2)),	(0, 3, 2),
										1, 10,
										(1, 1, 2)),
										"Shift format change");		
		CheckStdlv(	PsiFixFromReal(0.0, (0, 2, 2)), 
					PsiFixShiftRight(	PsiFixFromReal(-0.5, (1, 3, 2)),	(1, 3, 2),
										1, 10,
										(0, 2, 2), PsiFixTrunc, PsiFixSat),
										"saturation signed to unsigned");		
		CheckStdlv(	PsiFixFromReal(0.5, (1, 5, 5)), 
					PsiFixShiftRight(	PsiFixFromReal(0.5, (1, 5, 5)), (1, 5, 5),
										0, 10,
										(1, 5, 5), PsiFixTrunc, PsiFixWrap),
										"shift 0");		
		CheckStdlv(	PsiFixFromReal(-0.5, (1, 5, 5)), 
					PsiFixShiftRight(	PsiFixFromReal(-4.0, (1, 5, 5)), (1, 5, 5),
										3, 10,
										(1, 5, 5), PsiFixTrunc, PsiFixWrap),
										"shift 3");	
										
		-- *** PsiFixUpperBoundStdlv ***
		print("*** PsiFixUpperBoundStdlv ***");		
		CheckStdlv(	"1111", PsiFixupperBoundStdlv((0,2,2)), "unsigned");
		CheckStdlv(	"0111", PsiFixupperBoundStdlv((1,1,2)), "signed");
		
		-- *** PsiFixLowerBoundStdlv ***
		print("*** PsiFixLowerBoundStdlv ***");		
		CheckStdlv(	"0000", PsiFixLowerBoundStdlv((0,2,2)), "unsigned");
		CheckStdlv(	"1000", PsiFixLowerBoundStdlv((1,1,2)), "signed");
		
		-- *** PsiFixUpperBoundReal ***
		print("*** PsiFixUpperBoundReal ***");		
		CheckReal(	3.75, PsiFixUpperBoundReal((0,2,2)), "unsigned");
		CheckReal(	1.75, PsiFixUpperBoundReal((1,1,2)), "signed");
		
		-- *** PsiFixLowerBoundReal ***
		print("*** PsiFixLowerBoundReal ***");		
		CheckReal(	0.0, PsiFixLowerBoundReal((0,2,2)), "unsigned");
		CheckReal(	-2.0, PsiFixLowerBoundReal((1,1,2)), "signed");
		
		-- *** PsiFixInRange ***
		print("*** PsiFixInRange ***");	
		CheckBoolean(	true, 
						PsiFixInRange(PsiFixFromReal(1.25, (1, 4, 2)), (1, 4, 2),
									 (1, 2, 4), PsiFixTrunc),
						"In Range Normal");
		CheckBoolean(	false, 
						PsiFixInRange(PsiFixFromReal(6.25, (1, 4, 2)), (1, 4, 2),
									 (1, 2, 4), PsiFixTrunc),
						"Out Range Normal");
		CheckBoolean(	false, 
						PsiFixInRange(PsiFixFromReal(-1.25, (1, 4, 2)), (1, 4, 2),
									 (0, 5, 2), PsiFixTrunc),
						"signed -> unsigned OOR");
		CheckBoolean(	false, 
						PsiFixInRange(PsiFixFromReal(15.0, (0, 4, 2)), (0, 4, 2),
									 (1, 3, 2), PsiFixTrunc),
						"unsigned -> signed OOR");		
		CheckBoolean(	true, 
						PsiFixInRange(PsiFixFromReal(15.0, (0, 4, 2)), (0, 4, 2),
									 (1, 4, 2), PsiFixTrunc),
						"unsigned -> signed OK");	
		CheckBoolean(	false, 
						PsiFixInRange(PsiFixFromReal(15.5, (0, 4, 2)), (0, 4, 2),
									 (1, 4, 0), PsiFixRound),
						"rounding OOR");			
		CheckBoolean(	true, 
						PsiFixInRange(PsiFixFromReal(15.5, (0, 4, 2)), (0, 4, 2),
									 (1, 4, 1), PsiFixRound),
						"rounding OK 1");	
		CheckBoolean(	true, 
						PsiFixInRange(PsiFixFromReal(15.5, (0, 4, 2)), (0, 4, 2),
									 (0, 5, 0), PsiFixRound),
						"rounding OK 2");							
		
		wait;
	end process;


end sim;
