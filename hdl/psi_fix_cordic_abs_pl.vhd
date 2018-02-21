------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculates the absolute value of a complex number using the
-- cordic algorithm. The implementation is pipelined (i.e. it can take one
-- input sample per clock cycle)

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_fix_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_fix_cordic_abs_pl is
	generic (
		InFmt_g					: PsiFixFmt_t	:= (1, 0, 17);	-- Must be signed
		OutFmt_g				: PsiFixFmt_t	:= (0, 0, 17);	-- Must be unsigned
		InternalFmt_g			: PsiFixFmt_t	:= (1, 0, 25);	-- Must be signed
		Iterations_g			: natural		:= 13;
		PipelineFactor_g		: natural		:= 1;			-- 1 = 1 PL stage for every iteration, 2 = 1 PL stage for every 2 iterations, ...
		Round_g 				: PsiFixRnd_t	:= PsiFixTrunc;
		Sat_g					: PsiFixSat_t	:= PsiFixWrap
	);
	port (
		-- Control Signals
		Clk			: in 	std_logic;
		Rst			: in 	std_logic;
		-- Input
		InVld		: in	std_logic;
		InI			: in	std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		InQ			: in	std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		-- Output
		OutVld		: out	std_logic;
		OutAbs		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_cordic_abs_pl is

	-- Types
	type IntArr_t is array (natural range <>) of std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
	
	-- Two process method
	type two_process_r is record
		x 	: IntArr_t(0 to Iterations_g);
		y 	: IntArr_t(0 to Iterations_g);
		Vld	: std_logic_vector(0 to Iterations_g);
	end record;
	signal r, r_next : two_process_r;
	
	
begin
	--------------------------------------------
	-- Assertions
	--------------------------------------------
	assert InFmt_g.S = 1 report "psi_fix_cordic_abs_pl: InFmt_g must be signed" severity error;
	assert OutFmt_g.S = 0 report "psi_fix_cordic_abs_pl: OutFmt_g must be unsigned" severity error;
	assert InternalFmt_g.S = 1 report "psi_fix_cordic_abs_pl: InternalFmt_g must be signed" severity error;
	
	--------------------------------------------
	-- Combinatorial Process
	--------------------------------------------
	p_comb : process(InVld, InI, InQ, r)
		variable v : two_process_r;
		variable xin_v, yin_v : std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
		variable x_v, y_v : std_logic_vector(PsiFixSize(InternalFmt_g)-1 downto 0);
		variable Vld_v : std_logic;
	begin
		-- *** Hold variables stable ***
		v := r;
		
		-- *** Implementation ***	
		v.x(0) 		:= PsiFixAbs(InI, InFmt_g, InternalFmt_g, Round_g, Sat_g);
		v.y(0) 		:= PsiFixResize(InQ, InFmt_g, InternalFmt_g, Round_g, Sat_g);
		v.Vld(0)	:= InVld;
		for i in 0 to Iterations_g-1 loop
			-- Select pipeline stage or combinatorial
			if i mod PipelineFactor_g = 0 then
				Vld_v 	:= r.Vld(i);
				xin_v		:= r.x(i);
				yin_v		:= r.y(i);
			else
				xin_v		:= x_v;
				yin_v		:= y_v;				
			end if;
			
			-- Implement cordic
			if signed(yin_v) < 0 then
				x_v	:= PsiFixSub(	xin_v, InternalFmt_g, 
									yin_v, (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
				y_v	:= PsiFixAdd(	yin_v, InternalFmt_g,
											xin_v, (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
			else
				x_v	:= PsiFixAdd(	xin_v, InternalFmt_g, 
											yin_v, (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
				y_v	:= PsiFixSub(	yin_v, InternalFmt_g,
											xin_v, (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
			end if;			
			
			-- Stove results in FF (non-used FFs will be optimized away during synthesis)
			v.Vld(i+1) := Vld_v;
			v.y(i+1) := y_v;
			v.x(i+1) := x_v;
		end loop;
		
		-- *** Assign to signal ***
		r_next <= v;
	end process;
	
	--------------------------------------------
	-- Outputs
	--------------------------------------------
	OutAbs <= PsiFixResize(r.x(Iterations_g), InternalFmt_g, OutFmt_g, Round_g, Sat_g);
	OutVld <= r.Vld(Iterations_g);
	
	--------------------------------------------
	-- Sequential Process
	--------------------------------------------
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then	
			r <= r_next;
			if Rst = '1' then	
				r.Vld <= (others => '0');
			end if;
		end if;
	end process;
end;	





