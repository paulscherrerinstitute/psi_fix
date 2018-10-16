------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Add or Sub of two complex numbers

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim, resp $$
entity psi_fix_complex_addsub is
	generic(RstPol_g      : std_logic   := '1'; -- set reset polarity														$$ constant='1' $$
	        Pipeline_g    : boolean     := false; -- when false 3 pipes stages, when false 6 pipes (increase Fmax)			$$ export=true $$
	        InAFmt_g      : PsiFixFmt_t := (1, 0, 15); -- Input A Fixed Point format 										$$ constant=(1,0,15) $$
	        InBFmt_g      : PsiFixFmt_t := (1, 0, 24); -- Input B Fixed Point format 										$$ constant=(1,0,24) $$
	        OutFmt_g      : PsiFixFmt_t := (1, 0, 20); -- Output Fixed Point format											$$ constant=(1,0,20) $$
	        Round_g       : PsiFixRnd_t := PsiFixRound; --																	$$ constant=PsiFixRound $$
	        Sat_g         : PsiFixSat_t := PsiFixSat; --																	$$ constant=PsiFixSat $$
	        AddSub_g      : string      := "ADD");
	port(InClk     : in  std_logic;     -- clk 																				$$ type=clk; freq=100e6 $$
	     InRst     : in  std_logic;     -- sync. rst																		$$ type=rst; clk=clk_i $$

	     InIADat 	: in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- Inphase input of signal A
	     InQADat 	: in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- Quadrature input of signal A
	     InIBDat 	: in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- Inphase input of signal B
	     InQBDat 	: in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- Quadrature input of signal B
	     InVld     	: in  std_logic;     -- strobe input

	     OutIDat 	: out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output I
	     OutQDat 	: out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0); -- data output Q
	     OutVld    	: out std_logic      -- strobe output
	    );
begin
	assert AddSub_g = "ADD" or AddSub_g = "SUB"
	report "AddSub generic value is wrong! must be ADD or SUB" severity error;
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_complex_addsub is

	constant SumFmt_c : PsiFixFmt_t := (max(InAFmt_g.S,InBFmt_g.S), max(InAFmt_g.I,InBFmt_g.I) + 1, max(InAFmt_g.F,InBFmt_g.F));
	constant RndFmt_c : PsiFixFmt_t := (SumFmt_c.S, SumFmt_c.I + 1, OutFmt_g.F);

	-- Two process method
	type two_process_r is record
		-- Registers always present
		Vld   : std_logic_vector(0 to 3);

		AddII : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);
		AddQQ : std_logic_vector(PsiFixSize(SumFmt_c) - 1 downto 0);

		OutI  : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
		OutQ  : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
		-- Additional registers for pipelined version
		AiIn  : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
		AqIn  : std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
		BiIn  : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
		BqIn  : std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
		--
		RndI  : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
		RndQ  : std_logic_vector(PsiFixSize(RndFmt_c) - 1 downto 0);
	end record;
	signal r, r_next : two_process_r;

begin
	--------------------------------------------
	-- Combinatorial Process
	--------------------------------------------
	p_comb : process(r, InIADat, InQADat, InIBDat, InQBDat, InVld)
		variable v : two_process_r;
	begin
		-- *** Hold variables stable ***
		v := r;

		-- *** Vld Handling ***
		v.Vld(0)      := InVld;
		v.Vld(1 to 3) := r.Vld(0 to 2);

		-- *** pipeline ***
		if Pipeline_g then
			v.AiIn := InIADat;
			v.AqIn := InQADat;
			v.BiIn := InIBDat;
			v.BqIn := InQBDat;
		end if;
		--*** Add or Sub ***
		if AddSub_g = "ADD" then
			v.AddII := PsiFixAdd(choose(Pipeline_g, r.AiIn, InIADat), InAFmt_g,
			                     choose(Pipeline_g, r.BiIn, InIBDat), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
			v.AddQQ := PsiFixAdd(choose(Pipeline_g, r.AqIn, InQADat), InAFmt_g,
			                     choose(Pipeline_g, r.BqIn, InQBDat), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
		elsif AddSub_g = "SUB" then
			v.AddII := PsiFixSub(choose(Pipeline_g, r.AiIn, InIADat), InAFmt_g,
			                     choose(Pipeline_g, r.BiIn, InIBDat), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
			v.AddQQ := PsiFixSub(choose(Pipeline_g, r.AqIn, InQADat), InAFmt_g,
			                     choose(Pipeline_g, r.BqIn, InQBDat), InBFmt_g, SumFmt_c, PsiFixTrunc, PsiFixWrap);
		end if;
		-- *** Resize ***
		if Pipeline_g then
			v.RndI := PsiFixResize(r.AddII, SumFmt_c, RndFmt_c, Round_g, PsiFixWrap); -- Never wrapps
			v.RndQ := PsiFixResize(r.AddQQ, SumFmt_c, RndFmt_c, Round_g, PsiFixWrap); -- Never wrapps
			v.OutI := PsiFixResize(r.RndI, RndFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
			v.OutQ := PsiFixResize(r.RndQ, RndFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
		else
			v.OutI := PsiFixResize(r.AddII, SumFmt_c, OutFmt_g, Round_g, Sat_g);
			v.OutQ := PsiFixResize(r.AddQQ, SumFmt_c, OutFmt_g, Round_g, Sat_g);
		end if;

		-- *** Assign to signal ***
		r_next <= v;

	end process;

	-- *** Outputs ***
	g_pl : if Pipeline_g generate
		OutVld <= r.Vld(3);
	end generate;
	g_npl : if not Pipeline_g generate
		OutVld <= r.Vld(1);
	end generate;
	OutIDat <= r.OutI;
	OutQDat <= r.OutQ;

	--------------------------------------------
	-- Sequential Process
	--------------------------------------------
	p_seq : process(InClk)
	begin
		if rising_edge(InClk) then
			r <= r_next;
			if InRst = RstPol_g then
				r.Vld <= (others => '0');
			end if;
		end if;
	end process;

end architecture;
