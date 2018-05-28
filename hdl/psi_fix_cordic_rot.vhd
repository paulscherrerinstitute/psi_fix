------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component convertes polar coordinates to cartesian coordinates using
-- a vectoring CORDIC kernel. In pipelined mode it requires more logic but
-- can take one input sample every clock cycle. In serial mode it requires
-- N clock cycles but requires less logic.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_fix_pkg.all;
	use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim, resp $$
entity psi_fix_cordic_rot is
	generic (
		InAbsFmt_g				: PsiFixFmt_t	:= (0, 0, 15);	-- Must be unsigned		$$ constant=(0,0,16) $$
		InAngleFmt_g			: PsiFixFmt_t	:= (0, 0, 15);	-- Must be unsigned		$$ constant=(0,0,15) $$
		OutFmt_g				: PsiFixFmt_t	:= (1, 2, 16);	-- Usually signed		$$ constant=(1,2,16) $$
		InternalFmt_g			: PsiFixFmt_t	:= (1, 2, 22);	-- Must be signed		$$ constant=(1,2,22) $$
		AngleIntFmt_g			: PsiFixFmt_t	:= (1, 0, 18);	-- Must be (1, -2, x)	$$ constant=(1,-2,23) $$
		Iterations_g			: natural		:= 13;			--						$$ constant=21 $$
		GainComp_g				: boolean		:= False;		--						$$ export=true $$
		Round_g 				: PsiFixRnd_t	:= PsiFixTrunc;	--						$$ export=true $$
		Sat_g					: PsiFixSat_t	:= PsiFixWrap;	--						$$ export=true $$
		Mode_g					: string		:= "SERIAL"	-- PIPELINED or SERIAL	$$ export=true $$
	);
	port (
		-- Control Signals
		Clk			: in 	std_logic;											-- $$ type=clk; freq=100e6 $$
		Rst			: in 	std_logic;											-- $$ type=rst; clk=Clk $$
		-- Input
		InVld		: in	std_logic;
		InRdy		: out	std_logic;											-- $$ lowactive=true $$
		InAbs		: in	std_logic_vector(PsiFixSize(InAbsFmt_g)-1 downto 0);
		InAng		: in	std_logic_vector(PsiFixSize(InAngleFmt_g)-1 downto 0);
		-- Output
		OutVld		: out	std_logic;
		OutI		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutQ		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_cordic_rot is

	-- *** Constants ***
	constant AngleTableReal_c : t_areal(0 to 31)	:= (0.125, 				0.0737918088252,	0.0389895651887,	0.0197917120803,
														0.00993426215277,	0.00497197391179,	0.00248659363948,	0.00124337269683,
														0.000621695834357,	0.000310849102962,	0.000155424699705,	7.77123683806e-05,
														3.88561865063e-05,	1.94280935426e-05,	9.71404680751e-06,	4.85702340828e-06,
														2.4285117047e-06,	1.21425585242e-06,	6.0712792622e-07,	3.03563963111e-07,
														1.51781981556e-07,	7.58909907779e-08,	3.7945495389e-08,	1.89727476945e-08,
														9.48637384724e-09,	4.74318692362e-09,	2.37159346181e-09,	1.1857967309e-09,
														5.92898365452e-10,	2.96449182726e-10,	1.48224591363e-10,	7.41122956816e-11);													
	type AngleTable_t is array (0 to Iterations_g-1) of std_logic_vector(PsiFixSize(AngleIntFmt_g)-1 downto 0);
	
	function AngleTableStdlv return AngleTable_t is
		variable Table : AngleTable_t;
	begin
		for i in 0 to Iterations_g-1 loop
			Table(i) := PsiFixFromReal(AngleTableReal_c(i), AngleIntFmt_g);
		end loop;
		return Table;
	end function;
	
	constant AngleTable_c : AngleTable_t := AngleTableStdlv;
													
	
	function CordicGain(iterations : integer) return real is
		variable g : real := 1.0;
	begin
		for i in 0 to iterations-1 loop
			g := g * sqrt(1.0+2.0**(-2.0*real(i)));
		end loop;
		return g;
	end function;
	
	constant GcFmt_c		: PsiFixFmt_t												:= (0, 0, 17);
	constant AngleIntExtFmt	: PsiFixFmt_t												:= (AngleIntFmt_g.S, max(AngleIntFmt_g.I, 1), AngleIntFmt_g.F);
	constant GcCoef_c		: std_logic_vector(PsiFixSize(GcFmt_c)-1 downto 0)			:= PsiFixFromReal(1.0/CordicGain(Iterations_g), GcFmt_c);	
	constant QuadFmt_c		: PsiFixFmt_t												:= (0,0,2);


	-- *** Functions ***
	-- Cordic step for X
	function CordicStepX (	xLast		: std_logic_vector;
							yLast		: std_logic_vector;
							zLast		: std_logic_vector;
							shift		: integer) return std_logic_vector is
		constant yShifted 		: std_logic_vector := PsiFixShiftRight(yLast, InternalFmt_g, shift, Iterations_g-1, InternalFmt_g, PsiFixTrunc, PsiFixWrap, true);
	begin
	
		if signed(zLast) > 0 then
			return PsiFixSub(	xLast, InternalFmt_g, 
								yShifted, InternalFmt_g, 
								InternalFmt_g, PsiFixTrunc, PsiFixWrap);
		else
			return PsiFixAdd(	xLast, InternalFmt_g, 
								yShifted, InternalFmt_g, 
								InternalFmt_g, PsiFixTrunc, PsiFixWrap);

		end if;			
	end function;
	
	-- Cordic step for Y
	function CordicStepY (	xLast		: std_logic_vector;
							yLast		: std_logic_vector;
							zLast		: std_logic_vector;
							shift		: integer) return std_logic_vector is
		constant xShifted 		: std_logic_vector := PsiFixShiftRight(xLast, InternalFmt_g, shift, Iterations_g-1, InternalFmt_g, PsiFixTrunc, PsiFixWrap, true);
	begin
	
		if signed(zLast) > 0 then
			return	PsiFixAdd(	yLast, InternalFmt_g,
								xShifted, InternalFmt_g, 
								InternalFmt_g, PsiFixTrunc, PsiFixWrap);
		else
			return	PsiFixSub(	yLast, InternalFmt_g,
								xShifted, InternalFmt_g, 
								InternalFmt_g, PsiFixTrunc, PsiFixWrap);
		end if;			
	end function;

	-- Cordic step for Z
	function CordicStepZ (	zLast		: std_logic_vector;
							iteration	: integer) return std_logic_vector is
		constant Atan_c : std_logic_vector(PsiFixSize(AngleIntFmt_g)-1 downto 0) := AngleTable_c(iteration);
	begin
		if signed(zLast) > 0 then
			return	PsiFixSub(	zLast, AngleIntFmt_g,
								Atan_c, AngleIntFmt_g, 
								AngleIntFmt_g, PsiFixTrunc, PsiFixWrap);
		else
			return	PsiFixAdd(	zLast, AngleIntFmt_g,
								Atan_c, AngleIntFmt_g, 
								AngleIntFmt_g, PsiFixTrunc, PsiFixWrap);
		end if;			
	end function;	
	
	
	
	-- Types
	type IntArr_t is array (natural range <>) of std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
	type AngArr_t is array (natural range <>) of std_logic_vector(PsiFixSize(AngleIntFmt_g)-1 downto 0);
		
begin
	--------------------------------------------
	-- Assertions
	--------------------------------------------
	assert InAngleFmt_g.S /= 1 report "psi_fix_cordic_rot: InAngleFmt_g must be unsigned" severity error;
	assert AngleIntFmt_g.S = 1 report "psi_fix_cordic_rot: AngleIntFmt_g must be signed" severity error;
	assert AngleIntFmt_g.I = -2 report "psi_fix_cordic_rot: AngleIntFmt_g must be (1,-2,x)" severity error;
	assert InAbsFmt_g.S /= 1 report "psi_fix_cordic_rot: InAbsFmt_g must be unsigned" severity error;
	assert InternalFmt_g.S = 1 report "psi_fix_cordic_rot: InternalFmt_g must be signed" severity error;
	assert Mode_g = "PIPELINED" or Mode_g = "SERIAL" report "psi_fix_cordic_rot: Mode_g must be PIPELINED or SERIAL" severity error;
	assert InternalFmt_g.I > InAbsFmt_g.I report "psi_fix_cordic_rot: InternalFmt_g must have at least one more bit than InAbsFmt_g" severity error;
	
	--------------------------------------------
	-- Pipelined Implementation
	--------------------------------------------	
	g_pipelined : if Mode_g = "PIPELINED" generate
		signal X, Y				: IntArr_t(0 to Iterations_g);
		signal Z				: AngArr_t(0 to Iterations_g);
		signal Vld				: std_logic_vector(0 to Iterations_g);
		signal Quad				: t_aslv2(0 to Iterations_g);
		signal yQc, xQc			: std_logic_vector(PsiFixsize(InternalFmt_g)-1 downto 0);
		signal QcVld			: std_logic;
	begin
		-- Pipelined implementation can take a sample every clock cycle
		InRdy <= '1';
	
		-- Implementation
		p_cordic_pipelined : process(Clk)
		begin
			if rising_edge(Clk) then
				if Rst = '1' then
					Vld 		<= (others => '0');
					OutVld		<= '0';
					QcVld		<= '0';
				else
					-- Initialization
					X(0)	<= PsiFixResize(InAbs, InAbsFmt_g, InternalFmt_g, Round_g, Sat_g);
					Y(0)	<= (others => '0');
					Z(0)	<= PsiFixResize(InAng, InAngleFmt_g, AngleIntFmt_g, Round_g, PsiFixWrap);
					Quad(0)	<= PsiFixResize(InAng, InAngleFmt_g, QuadFmt_c, PsiFixTrunc, PsiFixWrap);
					Vld(0)	<= InVld;
					
					-- Cordic Iterations_g
					Vld(1 to Vld'high) <= Vld(0 to Vld'high-1);
					Quad(1 to Quad'high) <= Quad(0 to Quad'high-1);
					for i in 0 to Iterations_g-1 loop
						X(i+1) <= CordicStepX(X(i), Y(i), Z(i), i);
						Y(i+1) <= CordicStepY(X(i), Y(i), Z(i), i);
						Z(i+1) <= CordicStepZ(Z(i), i); 
					end loop;
					
					-- Quadrant Correction
					QcVld <= Vld(Iterations_g);
					if (Quad(Iterations_g) = "00") or (Quad(Iterations_g) = "11") then
						yQc <= Y(Iterations_g);
						xQc <= X(Iterations_g);
					else
						yQc <= PsiFixNeg(Y(Iterations_g), InternalFmt_g, InternalFmt_g, Round_g, Sat_g);
						xQc <= PsiFixNeg(X(Iterations_g), InternalFmt_g, InternalFmt_g, Round_g, Sat_g);
					end if;
					
					-- Output 
					OutVld <= QcVld;
					if GainComp_g then
						OutI <= PsiFixMult(xQc, InternalFmt_g, GcCoef_c, GcFmt_c, OutFmt_g, Round_g, Sat_g);
						OutQ <= PsiFixMult(yQc, InternalFmt_g, GcCoef_c, GcFmt_c, OutFmt_g, Round_g, Sat_g);
					else
						OutI <= PsiFixResize(xQc, InternalFmt_g, OutFmt_g, Round_g, Sat_g);
						OutQ <= PsiFixResize(yQc, InternalFmt_g, OutFmt_g, Round_g, Sat_g);
					end if;
				end if;
			end if;
		end process;
	end generate;
	
	--------------------------------------------
	-- Serial Implementation
	--------------------------------------------
	g_serial : if Mode_g = "SERIAL" generate
		signal Xin, Yin		: std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
		signal Zin			: std_logic_vector(PsiFixSize(AngleIntFmt_g)-1 downto 0);
		signal XinVld		: std_logic;	
		signal Quadin		: std_logic_vector(1 downto 0);
		signal X, Y			: std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
		signal Z			: std_logic_vector(PsiFixSize(AngleIntFmt_g)-1 downto 0);
		signal CordVld		: std_logic;
		signal IterCnt		: integer range 0 to Iterations_g-1;
		signal Quad			: std_logic_vector(1 downto 0);
		signal yQc, xQc		: std_logic_vector(PsiFixsize(InternalFmt_g)-1 downto 0);
		signal QcVld		: std_logic;
	begin
		InRdy <= not XinVld;
	
		p_cordic_serial : process(Clk)
			variable Xshifted, Yshifted : std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
		begin		
			if rising_edge(Clk) then
				if Rst = '1' then
					XinVld	<= '0';
					IterCnt	<= 0;			
					OutVld 	<= '0';
					CordVld <= '0';
				else
					-- Input latching
					if XinVld = '0' and InVld = '1' then
						XinVld <= '1';
						Xin		<= PsiFixResize(InAbs, InAbsFmt_g, InternalFmt_g, Round_g, Sat_g);
						Yin		<= (others => '0');	
						Zin		<= PsiFixResize(InAng, InAngleFmt_g, AngleIntFmt_g, Round_g, PsiFixWrap);
						Quadin	<= PsiFixResize(InAng, InAngleFmt_g, QuadFmt_c, PsiFixTrunc, PsiFixWrap);
					end if;
					
					-- CORDIC loop
					CordVld <= '0';
					if IterCnt = 0 then
						-- start of calculation
						if XinVld = '1' then
							X <= CordicStepX(Xin, Yin, Zin, 0);
							Y <= CordicStepY(Xin, Yin, Zin, 0);
							Quad <= Quadin;
							Z <= CordicStepZ(Zin, 0);
							IterCnt <= IterCnt+1;
							XinVld <= '0';
						end if;
					else
						-- Normal Calculation Step
						X <= CordicStepX(X, Y, Z, IterCnt);
						Y <= CordicStepY(X, Y, Z, IterCnt);
						Z <= CordicStepZ(Z, IterCnt);

						if IterCnt = Iterations_g-1 then
							IterCnt <= 0;
							CordVld <= '1';
						else	
							IterCnt <= IterCnt+1;
						end if;
					end if;
					
					-- Quadrant Correction
					QcVld <= CordVld;
					if (Quad = "00") or (Quad = "11") then
						yQc <= Y;
						xQc <= X;
					else
						yQc <= PsiFixNeg(Y, InternalFmt_g, InternalFmt_g, Round_g, Sat_g);
						xQc <= PsiFixNeg(X, InternalFmt_g, InternalFmt_g, Round_g, Sat_g);
					end if;
					
					-- Output 
					OutVld <= QcVld;
					if GainComp_g then
						OutI <= PsiFixMult(xQc, InternalFmt_g, GcCoef_c, GcFmt_c, OutFmt_g, Round_g, Sat_g);
						OutQ <= PsiFixMult(yQc, InternalFmt_g, GcCoef_c, GcFmt_c, OutFmt_g, Round_g, Sat_g);
					else
						OutI <= PsiFixResize(xQc, InternalFmt_g, OutFmt_g, Round_g, Sat_g);
						OutQ <= PsiFixResize(yQc, InternalFmt_g, OutFmt_g, Round_g, Sat_g);
					end if;					
					
				end if;
			end if;
		end process;
	end generate;
end;	





