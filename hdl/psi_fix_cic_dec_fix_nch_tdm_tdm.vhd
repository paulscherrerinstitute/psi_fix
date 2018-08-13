------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity psi_fix_cic_dec_fix_nch_tdm_tdm is
	generic (
        Channels_g                  : integer               := 3;           -- Min. 2
		Order_g						: integer 				:= 4;
		Ratio_g						: integer 				:= 10;
		DiffDelay_g					: natural range 1 to 2	:= 1;
		InFmt_g						: PsiFixFmt_t			:= (1, 0, 15);
		OutFmt_g					: PsiFixFmt_t			:= (1, 0, 15);
		AutoGainCorr_g				: boolean				:= True			-- Uses up to 25 bits of the datapath and 17 bit correction parameter
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;
		Rst							: in 	std_logic;
		-- Data Ports
		InData						: in	std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		InVld						: in	std_logic;
		OutData						: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutVld						: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_cic_dec_fix_nch_tdm_tdm is 
	-- Constants
	constant CicGain_c				: integer			:= (Ratio_g*DiffDelay_g)**Order_g;
	constant CicAddBits_c			: integer			:= log2ceil(CicGain_c);
	constant Shift_c				: integer			:= CicAddBits_c;
	constant AccuFmt_c				: PsiFixFmt_t		:= (InFmt_g.S, InFmt_g.I+CicAddBits_c, InFmt_g.F);
	constant DiffFmt_c				: PsiFixFmt_t		:= (OutFmt_g.S, InFmt_g.I, OutFmt_g.F + Order_g + 1);
	constant GcInFmt_c				: PsiFixFmt_t		:= (1, OutFmt_g.I, work.psi_common_math_pkg.min(24-OutFmt_g.I, DiffFmt_c.F));
	constant GcCoefFmt_c			: PsiFixFmt_t		:= (0, 1, 16);
	constant GcMultFmt_c			: PsiFixFmt_t		:= (1, GcInFmt_c.I+GcCoefFmt_c.I, GcInFmt_c.F+GcCoefFmt_c.F);
	constant Gc_c					: std_logic_vector(PsiFixSize(GcCoefFmt_c)-1 downto 0) := PsiFixFromReal(2.0**real(CicAddBits_c)/real(CicGain_c), GcCoefFmt_c);
	
	-- Types
	type Accus_t is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
	type Diff_t is array (natural range <>) of std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);
	
	-- Two Process Method
	type two_process_r is record
		-- Accu Section
		Input_0		: std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		VldAccu		: std_logic_vector(0 to Order_g);		
		Accu		: Accus_t(1 to Order_g);
		Rcnt		: integer range 0 to Ratio_g-1;
		Chcnt		: integer range 0 to Channels_g-1;
		-- Diff Section
		DiffIn_0		: std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);		
		VldDiff		: std_logic_vector(0 to Order_g);	
		DiffVal		: Diff_t(1 to Order_g);
		-- GC Stages
		GcVld		: std_logic_vector(0 to 2);
		GcIn_0		: std_logic_vector(PsiFixSize(GcInFmt_c)-1 downto 0);
		GcMult_1	: std_logic_vector(PsiFixSize(GcMultFmt_c)-1 downto 0);
		GcOut_2		: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		-- Output
		Outp		: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutVld		: std_logic;
	end record;	
	signal r, r_next : two_process_r;
	
	-- Component Connection Signals
	signal DiffDel		: Diff_t(0 to Order_g-1);		
	signal IntDel		: Accus_t(1 to Order_g);
	

begin
	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, InData, InVld,
						DiffDel, IntDel)	
		variable v : two_process_r;
	begin
		-- hold variables stable
		v := r;
		
		-- *** Pipe Handling ***
		v.VldAccu(v.VldAccu'low+1 to v.VldAccu'high) 	:= r.VldAccu(r.VldAccu'low to r.VldAccu'high-1);
		v.VldDiff(v.VldDiff'low+1 to v.VldDiff'high) 	:= r.VldDiff(r.VldDiff'low to r.VldDiff'high-1);
		v.GcVld(v.GcVld'low+1 to v.GcVld'high) 			:= r.GcVld(r.GcVld'low to r.GcVld'high-1);
		
		-- *** Stage Accu 0 ***
		-- Input Registers
		v.VldAccu(0)	:= InVld;
        v.Input_0 		:= InData;
		
		-- *** Stage Accu 1 ***
		-- First accumulator
		if r.VldAccu(0) = '1' then
				v.Accu(1)	:= PsiFixAdd(	IntDel(1), AccuFmt_c,
											r.Input_0, InFmt_g,
											AccuFmt_c);
		end if;
		
		-- *** Accumuator Stages (2 to Order) ***
		for stage in 1 to Order_g-1 loop
			if r.VldAccu(stage) = '1' then
				v.Accu(stage+1)	:= PsiFixAdd(	IntDel(stage+1), AccuFmt_c,
												r.Accu(stage), AccuFmt_c,
												AccuFmt_c);
			end if;			
		end loop;
		
		-- *** Downsampling ***
		-- Decimate
		v.VldDiff(0)		:= '0';		
		if r.VldAccu(Order_g) = '1' then
			-- channel counter
			if r.Chcnt = 0 then
				v.Chcnt := Channels_g-1;
				if r.Rcnt = 0 then
					v.Rcnt 			:= Ratio_g-1;	
				else
					v.Rcnt 		:= r.Rcnt - 1;
				end if;
			else
				v.Chcnt := r.Chcnt - 1;
			end if;	
			-- ratio counter
			if r.Rcnt = 0 then
				v.VldDiff(0)	:= '1';			
				v.DiffIn_0		:= PsiFixShiftRight(r.Accu(Order_g), AccuFmt_c, Shift_c, Shift_c, DiffFmt_c, PsiFixTrunc, PsiFixWrap); 				
			end if;
		end if;	
		
		-- *** Stage Diff 1 ***
		-- First differentiator
		if r.VldDiff(0) = '1' then	
			-- Differentiate
			v.DiffVal(1)	:= PsiFixSub(	r.DiffIn_0,	DiffFmt_c,
											DiffDel(0), DiffFmt_c,
											DiffFmt_c);		
		end if;

		
		-- *** Diff Stages ***
		-- Differentiators
		for stage in 1 to Order_g-1 loop
			if r.VldDiff(stage) = '1' then
				-- Differentiate			
				v.DiffVal(stage+1)	:= PsiFixSub(	r.DiffVal(stage),	DiffFmt_c,
													DiffDel(stage), DiffFmt_c,
													DiffFmt_c);		
			end if;		
		end loop;
		
		if AutoGainCorr_g then
			-- *** Gain Correction Stage 0 ***
			v.GcVld(0)	:= r.VldDiff(Order_g);
			v.GcIn_0	:= PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, GcInFmt_c, PsiFixRound, PsiFixSat);
			
			-- *** Gain Correction Stage 1 ***
			v.GcMult_1	:= PsiFixMult(	r.GcIn_0, GcInFmt_c,
										Gc_c, GcCoefFmt_c,
										GcMultFmt_c, PsiFixTrunc, PsiFixWrap);	-- Round/Truncation in next stage
			v.GcOut_2	:= PsiFixResize(r.GcMult_1, GcMultFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
		end if;
		
		-- *** Output Assignment ***
		if AutoGainCorr_g then
			v.Outp := r.GcOut_2;
			v.OutVld := r.GcVld(2);
		else
			v.Outp := PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
			v.OutVld := r.VldDiff(Order_g);
		end if;
		
		-- Apply to record
		r_next <= v;
		
	end process;
	
	--------------------------------------------------------------------------
	-- Output Assignment
	--------------------------------------------------------------------------		
	OutVld 	<= r.OutVld;
	OutData <= r.Outp;
	
	--------------------------------------------------------------------------
	-- Sequential Process
	--------------------------------------------------------------------------	
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then
			assert Channels_g >= 2 report "###ERROR###: psi_fix_cic_dec_fix_nch_tdm_tdm: Channels_g must be >= 2" severity error;
			r <= r_next;
			if Rst = '1' then
				r.VldAccu	<= (others => '0');	
				r.Accu		<= (others => (others => '0'));
				r.Rcnt		<= 0;
				r.Chcnt		<= Channels_g-1;
				r.VldDiff	<= (others => '0');
				r.GcVld		<= (others => '0');
				r.OutVld	<= '0';
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	-- Component Instantiations
	--------------------------------------------------------------------------
		
	-- *** Diff-delays ***
	g_diffdel : for stage in 0 to Order_g-1 generate
		signal DiffDelIn	:	std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);
		signal DiffVldIn	: 	std_logic;
	begin
		DiffDelIn <= r.DiffIn_0 when stage = 0 else r.DiffVal(max(stage,1));
		DiffVldIn <= r.VldDiff(0) when stage = 0 else r.VldDiff(max(stage,1));
	
		i_del : entity work.psi_common_delay
			generic map (
				Width_g			=> PsiFixSize(DiffFmt_c),
				Delay_g			=> Channels_g*DiffDelay_g,
				RstState_g		=> true
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				
				-- Data
				InData		=> DiffDelIn,
				InVld		=> DiffVldIn,
				OutData		=> DiffDel(stage)
			);
	end generate;
	
	-- *** Int-delays ***
	g_intdel : for stage in 0 to Order_g-1 generate
	begin	
		i_del : entity work.psi_common_delay
			generic map (
				Width_g			=> PsiFixSize(AccuFmt_c),
				Delay_g			=> Channels_g-1,
				RstState_g		=> true
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				
				-- Data
				InData		=> r.Accu(stage+1),
				InVld		=> r.VldAccu(stage),
				OutData		=> IntDel(stage+1)
			);
	end generate;	
 
end rtl;
