------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

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
entity psi_fix_cic_int_fix_1ch is
	generic (
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
		InRdy						: out	std_logic;
		OutData						: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutVld						: out	std_logic;
		OutRdy						: in	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_cic_int_fix_1ch is 
	-- Constants
	constant CicGain_c				: real				:= ((real(Ratio_g)*real(DiffDelay_g))**real(Order_g))/real(Ratio_g);
	constant CicAddBits_c			: integer			:= log2ceil(CicGain_c-0.1); -- WORKAROUND: Vivado does real calculations imprecisely. With the -0.1, wrong results are avoided.
	constant Shift_c				: integer			:= CicAddBits_c;	
	constant DiffFmt_c				: PsiFixFmt_t		:= (InFmt_g.S, InFmt_g.I+Order_g+1, InFmt_g.F);
	constant AccuFmt_c				: PsiFixFmt_t		:= (InFmt_g.S, InFmt_g.I+CicAddBits_c, InFmt_g.F);
	constant ShiftInFmt_c			: PsiFixFmt_t		:= (InFmt_g.S, InFmt_g.I, InFmt_g.F+CicAddBits_c);
	constant GcInFmt_c				: PsiFixFmt_t		:= (1, OutFmt_g.I, work.psi_common_math_pkg.min(24-OutFmt_g.I, ShiftInFmt_c.F));
	constant ShiftOutFmt_c			: PsiFixFmt_t		:= (InFmt_g.S, InFmt_g.I, choose(AutoGainCorr_g, GcInFmt_c.F, OutFmt_g.F)+1);
	constant GcCoefFmt_c			: PsiFixFmt_t		:= (0, 1, 16);
	constant GcMultFmt_c			: PsiFixFmt_t		:= (1, GcInFmt_c.I+GcCoefFmt_c.I, GcInFmt_c.F+GcCoefFmt_c.F);
	constant Gc_c					: std_logic_vector(PsiFixSize(GcCoefFmt_c)-1 downto 0) := PsiFixFromReal(2.0**real(CicAddBits_c)/real(CicGain_c), GcCoefFmt_c);

	-- Types
	type Accus_t is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
	type Diff_t is array (natural range <>) of std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);
	
	-- Two Process Method
	type two_process_r is record
		-- Diff Section
		Input_0		: std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		Rdy_0		: std_logic;
		VldDiff		: std_logic_vector(0 to Order_g);	
		DiffVal		: Diff_t(1 to Order_g);
		DiffLast	: Diff_t(1 to Order_g);
		DiffLast2	: Diff_t(1 to Order_g);
		-- Interplation
		Rcnt		: integer range 0 to Ratio_g;
		VldAccu		: std_logic_vector(0 to Order_g);	
		AccuIn_0	: std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
		-- Accu section
		Accu		: Accus_t(1 to Order_g);		
		-- GC Stages
		GcVld		: std_logic_vector(0 to 4);
		GcIn_0		: std_logic_vector(PsiFixSize(GcInFmt_c)-1 downto 0);
		GcIn_1		: std_logic_vector(PsiFixSize(GcInFmt_c)-1 downto 0);
		GcIn_2		: std_logic_vector(PsiFixSize(GcInFmt_c)-1 downto 0);
		GcMult_3	: std_logic_vector(PsiFixSize(GcMultFmt_c)-1 downto 0);
		GcOut_4		: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		-- Output
		Outp		: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		OutVld		: std_logic;
	end record;	
	signal r, r_next : two_process_r;

begin
	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, InData, InVld, OutRdy)	
		variable v : two_process_r;
		variable DiffDel_v	: std_logic_vector(PsiFixSize(DiffFmt_c)-1 downto 0);
		variable Sft_v		: std_logic_vector(PsiFixSize(ShiftOutFmt_c)-1 downto 0);
		variable InRdy_v	: std_logic;
		variable OutRdy_v	: std_logic;
	begin
		-- hold variables stable
		v := r;
		
		-- Variable default values
		DiffDel_v := (others => '0');
		Sft_v := (others => '0');
		
		-- *** Handshaking pipeline control signals ***
		-- Only stop output pipeline if a result is available at the output (AXI-S Spec says valid is not allowed to wait on ready!)
		if r.OutVld = '0' or OutRdy = '1' then	
			OutRdy_v := '1';
		else
			OutRdy_v := '0';
		end if;

		-- Input Rdy
		if r.Rcnt = 0 or (r.Rcnt = 1 and OutRdy_v = '1') then 
			InRdy_v := '1';
		else	
			InRdy_v := '0';
		end if;
		
		-- *** Pipe Handling ***
		if InRdy_v = '1' then
			v.VldDiff(v.VldDiff'low+1 to v.VldDiff'high) 	:= r.VldDiff(r.VldDiff'low to r.VldDiff'high-1);
		end if;
		if OutRdy_v = '1' then
			v.VldAccu(v.VldAccu'low+1 to v.VldAccu'high) 	:= r.VldAccu(r.VldAccu'low to r.VldAccu'high-1);
			v.GcVld(v.GcVld'low+1 to v.GcVld'high) 			:= r.GcVld(r.GcVld'low to r.GcVld'high-1);
		end if;
		
		-- *** Stage Diff 0 (Input registers) ***
		-- Input Registers and combinatorial rdy chain breaking (making RDY registered)
		if r.Rdy_0 = '1' and InVld = '1' then
			v.VldDiff(0) 	:= '1';
			v.Input_0		:= InData;
			v.Rdy_0			:= '0';
		elsif InRdy_v = '1' or r.VldDiff(1) = '0' then
			v.VldDiff(0) 	:= '0';
			v.Rdy_0			:= '1';
		end if;
		
		-- *** Stage Diff 1 ***
		-- First differentiator
		if r.VldDiff(0) = '1' and (InRdy_v = '1' or r.VldDiff(1) = '0') then
			v.VldDiff(1) := '1';
			v.VldDiff(0) := '0';
			if DiffDelay_g = 1 then
				DiffDel_v := r.DiffLast(1);
			else
				DiffDel_v := r.DiffLast2(1);
				v.DiffLast2(1)	:= r.DiffLast(1);
			end if;		
			-- Differentiate
			v.DiffVal(1)	:= PsiFixSub(	r.Input_0,	InFmt_g,
											DiffDel_v, DiffFmt_c,
											DiffFmt_c);
			v.DiffLast(1) 	:= PsiFixResize(r.Input_0, InFmt_g, DiffFmt_c);			
		end if;		
		
		-- *** Diff Stages ***
		-- Differentiators
		for stage in 1 to Order_g-1 loop
			if r.VldDiff(stage) = '1' and (InRdy_v = '1' or r.VldDiff(stage+1) = '0') then
				v.VldDiff(stage+1) := '1';
				v.VldDiff(stage) := r.VldDiff(stage-1);
				if DiffDelay_g = 1 then
					DiffDel_v := r.DiffLast(stage+1);
				else
					DiffDel_v := r.DiffLast2(stage+1);
					v.DiffLast2(stage+1) := r.DiffLast(stage+1);
				end if;
				-- Differentiate			
				v.DiffVal(stage+1)	:= PsiFixSub(	r.DiffVal(stage),	DiffFmt_c,
													DiffDel_v, DiffFmt_c,
													DiffFmt_c);
				v.DiffLast(stage+1) := r.DiffVal(stage);				
			end if;		
		end loop;

		-- *** Stage Accu 0 (interpolation) ***
		if (r.Rcnt = 0 and r.VldDiff(Order_g) = '1') or
		   (r.Rcnt = 1 and OutRdy_v = '1' and r.VldDiff(Order_g) = '1') then
			v.Rcnt			:= Ratio_g;
			v.AccuIn_0		:= PsiFixResize(r.DiffVal(Order_g), DiffFmt_c, AccuFmt_c);
			v.VldAccu(0)	:= '1';
		elsif r.Rcnt = 1 and OutRdy_v = '1' then
			v.VldAccu(0)	:= '0';
			v.Rcnt			:= r.Rcnt - 1;
		elsif OutRdy_v = '1' and r.Rcnt /= 0 then
			v.AccuIn_0 		:= (others => '0');
			v.Rcnt			:= r.Rcnt - 1;
		end if;
		
		-- *** Stage Accu 1 ***
		-- First accumulator
		if r.VldAccu(0) = '1' and OutRdy_v = '1' then
			v.Accu(1)	:= PsiFixAdd(	r.Accu(1), AccuFmt_c,
										r.AccuIn_0, AccuFmt_c,
										AccuFmt_c);
		end if;
		
		-- *** Accumuator Stages (2 to Order) ***
		for stage in 1 to Order_g-1 loop
			if r.VldAccu(stage) = '1' and OutRdy_v = '1' then
				v.Accu(stage+1)	:= PsiFixAdd(	r.Accu(stage+1), AccuFmt_c,
												r.Accu(stage), AccuFmt_c,
												AccuFmt_c);
			end if;			
		end loop;
		-- Shifter (pure wiring)
		Sft_v := PsiFixShiftRight(r.Accu(Order_g), AccuFmt_c, Shift_c, Shift_c, ShiftOutFmt_c);
		
		-- *** Gain Correction ***		
		if AutoGainCorr_g then
			-- *** Gain Correction Stage 0 ***
			if OutRdy_v = '1' then
				-- *** GC Stage 0 ***
				v.GcVld(0)	:= r.VldAccu(Order_g);
				v.GcIn_0	:= PsiFixResize(Sft_v, ShiftOutFmt_c, GcInFmt_c, PsiFixRound, PsiFixSat);
			
				-- *** GC Stage 1 ***
				v.GcIn_1	:= r.GcIn_0;
				
				-- *** GC Stage 2 ***
				v.GcIn_2	:= r.GcIn_1;
			
				-- *** Gain Correction Stage 3 ***
				v.GcMult_3	:= PsiFixMult(	r.GcIn_2, GcInFmt_c,
											Gc_c, GcCoefFmt_c,
											GcMultFmt_c, PsiFixTrunc, PsiFixWrap);	-- Round/Truncation in next stage
											
				-- *** Gain Correction Stage 4 ***
				v.GcOut_4	:= PsiFixResize(r.GcMult_3, GcMultFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
			end if;
		end if;
		
		-- *** Output Assignment ***
		if OutRdy_v = '1' then
			if AutoGainCorr_g then
				v.Outp := r.GcOut_4;
				v.OutVld := r.GcVld(4);
			else
				v.Outp := PsiFixResize(Sft_v, ShiftOutFmt_c, OutFmt_g, PsiFixRound, PsiFixSat);
				v.OutVld := r.VldAccu(Order_g);
			end if;
		end if;
		
		-- *** Output Signals ***
		OutVld 	<= r.OutVld;
		OutData <= r.Outp;
		InRdy 	<= r.Rdy_0;		
		
		-- Apply to record
		r_next <= v;
		
	end process;
	
	--------------------------------------------------------------------------
	-- Output Assignment
	--------------------------------------------------------------------------		

	
	--------------------------------------------------------------------------
	-- Sequential Process
	--------------------------------------------------------------------------	
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.VldDiff	<= (others => '0');
				r.DiffLast	<= (others => (others => '0'));
				r.DiffLast2	<= (others => (others => '0'));
				r.VldAccu	<= (others => '0');
				r.Accu		<= (others => (others => '0'));
				r.GcVld		<= (others => '0');
				r.OutVld	<= '0';
				r.Rdy_0		<= '1';
			end if;
		end if;
	end process;
 
end rtl;
