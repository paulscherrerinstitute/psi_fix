------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a moving average with different options for the 
-- gain correction (none, rough by shifting, exact by shifting and multiplication).

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
entity psi_fix_mov_avg is
	generic (
	    InFmt_g 	: PsiFixFmt_t:=(1,0,16);	-- $$ constant=(1,0,10) $$
		OutFmt_g 	: PsiFixFmt_t:=(1,0,16);	-- $$ constant=(1,1,12) $$
		Taps_g		: positive:=5;		-- $$ constant=7 $$
	    GainCorr_g	: string		:= "ROUGH";	-- ROUGH, NONE or EXACT $$ export=true $$
		Round_g		: PsiFixRnd_t	:= PsiFixRound;
		Sat_g		: PsiFixSat_t	:= PsiFixSat;
		OutRegs_g	: natural		:= 1 -- $$ export=true $$
	);
	port(
		-- Control Signals
		Clk			: in	std_logic;	-- $$ type=clk; freq=100e6 $$
		Rst			: in	std_logic;	-- $$ type=rst; clk=Clk $$
		
		-- Input data
		InVld		: in	std_logic;											
		InData		: in	std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0); 	
		
		-- Output data
		OutVld		: out	std_logic;											
		OutData		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0)
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_mov_avg is
	--
	--attribute use_dsp48 : string;
	--attribute use_dsp48 of rtl : architecture is "yes";

	-- Constants
	constant Gain_c				: integer			:= Taps_g;
	constant AdditionalBits_c	: integer			:= log2ceil(Gain_c);
	
	-- Formats
	constant DiffFmt_c			: PsiFixFmt_t		:= (1, InFmt_g.I+1, InFmt_g.F);
	constant SumFmt_c			: PsiFixFmt_t		:= (1, inFmt_g.I+AdditionalBits_c, InFmt_g.F);
	constant GcInFmt_c			: PsiFixFmt_t		:= (1, InFmt_g.I, work.psi_common_math_pkg.min(24-inFmt_g.I, SumFmt_c.F+AdditionalBits_c));
	constant GcCoefFmt_c		: PsiFixFmt_t		:= (0, 1, 16);
	
	-- Gain correction coefficient calculation
	constant Gc_c : std_logic_vector(PsiFixSize(GcCoefFmt_c)-1 downto 0) := PsiFixFromReal(2.0**real(AdditionalBits_c)/real(Gain_c), GcCoefFmt_c);
	
	-- types
	type OutReg_t is array (natural range <>) of std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);

	-- Two Process Method
	type two_process_r is record
		Vld					: std_logic_vector(0 to 2);
		Diff_0				: std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);
		Sum_1				: std_logic_vector(PsiFixSize(SumFmt_c)-1 downto 0);
		RoughCorr_2			: std_logic_vector(PsiFixSize(GcInFmt_c)-1 downto 0);
		OutRegs				: OutReg_t(0 to OutRegs_g-1);
		VldOutRegs			: std_logic_vector(0 to OutRegs_g-1);
	end record;		
	signal r, r_next : two_process_r;
	
	-- Component instantiation signals
	signal DataDel	: std_logic_vector(InData'range);
	
begin

	assert GainCorr_g = "NONE" or GainCorr_g = "ROUGH" or GainCorr_g = "EXACT" report "###ERROR###: psi_fix_mov_avg: GainCorr_g must be NONE, ROUGH or EXACT" severity error;

	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, InVld, InData, DataDel)	
		variable v : two_process_r;
		variable CalcOut_v	: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		variable CalcVld_v	: std_logic;
	begin	
		-- Variable initialization
		CalcOut_v := (others => '0');
		CalcVld_v := '0';
	
		-- hold variables stable
		v := r;
		
		-- *** Pipe Handling ***
		v.Vld(v.Vld'low+1 to v.Vld'high) 						:= r.Vld(r.Vld'low to r.Vld'high-1);
		v.VldOutRegs(v.VldOutRegs'low+1 to v.VldOutRegs'high) 	:= r.VldOutRegs(r.VldOutRegs'low to r.VldOutRegs'high-1);
		v.OutRegs(v.OutRegs'low+1 to v.OutRegs'high) 			:= r.OutRegs(r.OutRegs'low to r.OutRegs'high-1);
		
		-- *** Stage 0 ***
		v.Diff_0	:= PsiFixSub(InData, InFmt_g, DataDel, InFmt_g, DiffFmt_c, PsiFixTrunc, PsiFixWrap);
		v.Vld(0)	:= InVld;
		
		-- *** Stage 1 ***
		if r.Vld(0) = '1' then
			v.Sum_1	:= PsiFixAdd(r.Sum_1, SumFmt_c, r.Diff_0, DiffFmt_c, SumFmt_c, PsiFixTrunc, PsiFixWrap);
		end if;
		
		-- *** Stage 2 ***
		if GainCorr_g = "NONE" then
			CalcOut_v 	:= PsiFixResize(r.Sum_1, SumFmt_c, OutFmt_g, Round_g, Sat_g);
			CalcVld_v 	:= r.Vld(1);
		elsif GainCorr_g = "ROUGH" then
			CalcOut_v 	:= PsiFixShiftRight(r.Sum_1, SumFmt_c, AdditionalBits_c, AdditionalBits_c, OutFmt_g, Round_g, Sat_g);
			CalcVld_v 	:= r.Vld(1);
		else
			v.RoughCorr_2	:= PsiFixShiftRight(r.Sum_1, SumFmt_c, AdditionalBits_c, AdditionalBits_c, GcInFmt_c, PsiFixTrunc, PsiFixWrap);
		end if;
		
		-- *** Stage 3 ***
		if GainCorr_g = "EXACT" then
			CalcOut_v	:= PsiFixMult(r.RoughCorr_2, GcInFmt_c, Gc_c, GcCoefFmt_c, OutFmt_g, Round_g, Sat_g);
			CalcVld_v	:= r.Vld(2);
		end if;	
		
		-- *** Output Registers ***
		if OutRegs_g = 0 then
			OutVld 	<= CalcVld_v;
			OutData <= CalcOut_v;
		else
			v.OutRegs(0)	:= CalcOut_v;
			v.VldOutRegs(0)	:= CalcVld_v;
			OutData 		<= r.OutRegs(r.OutRegs'high);
			OutVld			<= r.VldOutRegs(r.VldOutRegs'high);
		end if;	
		
		-- Apply to record
		r_next <= v;
		
	end process;
	
	--------------------------------------------------------------------------
	-- Sequential Process
	--------------------------------------------------------------------------	
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.Vld			<= (others => '0');
				r.VldOutRegs	<= (others => '0');
				r.Sum_1			<= (others => '0');
			end if;
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Component Instantiation
	--------------------------------------------------------------------------		
	i_del : entity work.psi_common_delay
		generic map (
			Width_g			=> PsiFixSize(InFmt_g),
			Delay_g			=> Taps_g,
			Resource_g		=> "AUTO",
			RstState_g		=> True
		)
		port map (
			Clk			=> Clk,
			Rst			=> Rst,
			InData		=> InData,
			InVld		=> InVld,
			OutData		=> DataDel
		);

end architecture;
