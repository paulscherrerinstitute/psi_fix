------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ processes=stim, resp $$
entity psi_fix_pol2cart_approx is
	generic (
		InAbsFmt_g				: PsiFixFmt_t	:= (0, 0, 15);	-- Must be unsigned		$$ constant=(0,0,16) $$
		InAngleFmt_g			: PsiFixFmt_t	:= (0, 0, 15);	-- Must be unsigned		$$ constant=(0,0,15) $$
		OutFmt_g				: PsiFixFmt_t	:= (1, 0, 16);	-- Usually signed		$$ constant=(1,0,16) $$	
		Round_g 				: PsiFixRnd_t	:= PsiFixRound;	--					
		Sat_g					: PsiFixSat_t	:= PsiFixSat	--					
	);
	port
	(
		-- Control Signals
		Clk			: in 	std_logic;											-- $$ type=clk; freq=100e6 $$
		Rst			: in 	std_logic;											-- $$ type=rst; clk=Clk $$
		-- Input
		InVld		: in	std_logic;
		InAbs		: in	std_logic_vector(PsiFixSize(InAbsFmt_g)-1 downto 0);
		InAng		: in	std_logic_vector(PsiFixSize(InAngleFmt_g)-1 downto 0);
		-- Output
		OutVld		: out	std_logic;
		OutI		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutQ		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0)
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_pol2cart_approx is 
	-- Constants
	constant SinOutFmt_c		: PsiFixFmt_t		:= (1, 0, 17);
	constant SinInFmt_c			: PsiFixFmt_t		:= (0, 0, 20);
	constant CosOffs_c			: std_logic_vector(PsiFixSize(SinInFmt_c)-1 downto 0)	:= PsiFixFromReal(0.25, SinInFmt_c);
	
	-- Types
	type Abs_t is array (natural range <>) of std_logic_vector(InAbs'range);
	
	-- Two Process Method
	type two_process_r is record
		VldIn				: std_logic_vector(0 to 9);
		AbsPipe				: Abs_t(0 to 8);
		PhaseIn_0			: std_logic_vector(PsiFixSize(InAngleFmt_g)-1 downto 0);
		PhaseSin_1			: std_logic_vector(PsiFixSize(SinInFmt_c)-1 downto 0);
		PhaseCos_1			: std_logic_vector(PsiFixSize(SinInFmt_c)-1 downto 0);
		OutI_9				: std_logic_vector(OutI'range);
		OutQ_9				: std_logic_vector(OutQ'range);
	end record;	
	signal r, r_next : two_process_r;
	
	-- Component Connection Signals
	signal SinVld_8, CosVld_8		: std_logic;
	signal SinData_8, CosData_8		: std_logic_vector(PsiFixSize(SinOutFmt_c)-1 downto 0);
	

begin
	--------------------------------------------------------------------------
	-- Assertions
	--------------------------------------------------------------------------
	assert InAngleFmt_g.S = 0 report "psi_fix_pol2cart_approx: InAngleFmt_g must be unsigned" severity error;
	assert InAbsFmt_g.S = 0 report "psi_fix_pol2cart_approx: InAngleFmt_g must be unsigned" severity error;
	assert InAngleFmt_g.I <= 0 report "psi_fix_pol2cart_approx: InAngleFmt_g must be (1,0,x)" severity error;
	
	p_assert : process(Clk)
	begin
		if rising_edge(Clk) then
			if Rst = '0' then
				assert SinVld_8 = CosVld_8 report "###ERROR###: psi_fix_pol2cart_approx: SinVld / CosVld mismatch" severity error;
				assert SinVld_8 = r.VldIn(8) report "###ERROR###: psi_fix_pol2cart_approx: SinVld / Pipeline Vld mismatch" severity error;
			end if;
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, InVld, InAbs, InAng, 
						SinVld_8, CosVld_8, SinData_8, CosData_8)	
		variable v : two_process_r;
	begin	
		-- hold variables stable
		v := r;
		
		-- *** Pipe Handling ***
		v.VldIn(v.VldIn'low+1 to v.VldIn'high) 			:= r.VldIn(r.VldIn'low to r.VldIn'high-1);
		v.AbsPipe(v.AbsPipe'low+1 to v.AbsPipe'high) 	:= r.AbsPipe(r.AbsPipe'low to r.AbsPipe'high-1);
		
		-- *** Stage 0 ***
		-- Input Registers
		v.VldIn(0)		:= InVld;
		v.AbsPipe(0)	:= InAbs;
		v.PhaseIn_0 	:= InAng;
									
		-- *** Stage 1 ***
		-- Sine and cosine phase
		v.PhaseSin_1 := PsiFixResize(	r.PhaseIn_0, InAngleFmt_g, SinInFmt_c, Round_g, Sat_g);
		v.PhaseCos_1 := PsiFixAdd(	r.PhaseIn_0, InAngleFmt_g, 
									CosOffs_c, SinInFmt_c,
									SinInFmt_c, Round_g, PsiFixWrap);
		
		-- *** Stages 2 - 8 ***
		-- Reserved for Linear approximation	

		-- *** Stage 8 ***
		-- Output Multiplications
		v.OutI_9 := PsiFixMult(r.AbsPipe(8), InAbsFmt_g, CosData_8, SinOutFmt_c, OutFmt_g, Round_g, Sat_g);
		v.OutQ_9 := PsiFixMult(r.AbsPipe(8), InAbsFmt_g, SinData_8, SinOutFmt_c, OutFmt_g, Round_g, Sat_g);

		-- *** Outputs ***
		OutVld 	<= r.VldIn(9);
		OutQ	<= r.OutQ_9;
		OutI	<= r.OutI_9;
		
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
				r.VldIn			<= (others => '0');
			end if;
		end if;
	end process;
	
	--------------------------------------------------------------------------
	-- Component Instantiation
	--------------------------------------------------------------------------	
	i_sincos : entity work.psi_fix_lin_approx_sin18b_dual
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Input
			InVldA		=> r.VldIn(1),
			InDataA		=> r.PhaseSin_1,
			InVldB		=> r.VldIn(1),
			InDataB		=> r.PhaseCos_1,
			-- Output
			OutVldA		=> SinVld_8,
			OutDataA	=> SinData_8,
			OutVldB		=> CosVld_8,
			OutDataB	=> CosData_8		
		);
 
end rtl;
