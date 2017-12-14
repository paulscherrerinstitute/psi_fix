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
	begin
		-- *** Hold variables stable ***
		v := r;
		
		-- *** Implementation ***	
		v.x(0) 		:= PsiFixAbs(InI, InFmt_g, InternalFmt_g, Round_g, Sat_g);
		v.y(0) 		:= PsiFixResize(InQ, InFmt_g, InternalFmt_g, Round_g, Sat_g);
		v.Vld(0)	:= InVld;
		for i in 0 to Iterations_g-1 loop
			v.Vld(i+1) := r.Vld(i);
			if signed(r.y(i)) < 0 then
				v.x(i+1)	:= PsiFixSub(	r.x(i), InternalFmt_g, 
											r.y(i), (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
				v.y(i+1)	:= PsiFixAdd(	r.y(i), InternalFmt_g,
											r.x(i), (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
			else
				v.x(i+1)	:= PsiFixAdd(	r.x(i), InternalFmt_g, 
											r.y(i), (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
				v.y(i+1)	:= PsiFixSub(	r.y(i), InternalFmt_g,
											r.x(i), (1, InternalFmt_g.I-i, InternalFmt_g.F+i), 
											InternalFmt_g, Round_g, Sat_g);
			end if;
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





