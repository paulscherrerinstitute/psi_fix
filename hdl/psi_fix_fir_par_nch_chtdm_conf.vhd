------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculateas an FIR filter with the following limitations:
-- - Filter is calculated in parallel (one multiplier per tap)
-- - The number of channels is configurable
-- - All channels are processed time-division-multiplexed
-- - Coefficients are configurable but the same for each channel

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_fix_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim, resp $$
entity psi_fix_fir_par_nch_chtdm_conf is
	generic (
		InFmt_g					: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,0,15) $$
		OutFmt_g				: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,2,13) $$
		CoefFmt_g				: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,0,17) $$
		Channels_g				: natural		:= 1;					-- $$ export=true $$
		Taps_g					: natural		:= 13;					-- $$ export=true $$
		Rnd_g					: PsiFixRnd_t	:= PsiFixRound;
		Sat_g					: PsiFixSat_t	:= PsiFixSat;
		UseFixCoefs_g			: boolean		:= true;
		FixCoefs_g				: t_areal		:= (0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.11, 0.12, 0.13)	
	);
	port (
		-- Control Signals
		Clk			: in 	std_logic;									-- $$ type=clk; freq=100e6 $$
		Rst			: in 	std_logic;									-- $$ type=rst; clk=Clk $$
		-- Input
		InVld		: in	std_logic;
		InData		: in	std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
		-- Output
		OutVld		: out	std_logic;
		OutData		: out	std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		-- Coefficient interface										:= '0';
		CoefWr		: in	std_logic											:= '0';
		CoefAddr	: in	std_logic_vector(log2ceil(Taps_g)-1 downto 0)		:= (others => '0');
		CoefWrData	: in	std_logic_vector(PsiFixSize(CoefFmt_g)-1 downto 0)	:= (others => '0')
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_fir_par_nch_chtdm_conf is
	
	-- DSP Slice Chain
	constant AccuFmt_c	: PsiFixFmt_t	:= (1, OutFmt_g.I+1, InFmt_g.F + CoefFmt_g.F);
	constant RoundFmt_c	: PsiFixFmt_t	:= (1, AccuFmt_c.I+1, OutFmt_g.F);	
	type AccuChain_a is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
	type InData_a is array (natural range <>) of std_logic_vector(PsiFixSize(InFmt_g)-1 downto 0);
	signal DspDataChainI	: InData_a(0 to Taps_g-1);	
	signal DspDataChainO	: InData_a(0 to Taps_g-1);	
	signal DspAccuChain : AccuChain_a(0 to Taps_g-1) := (others => (others => '0'));
	signal DspVldChain	: std_logic_vector(1 to Taps_g);
	signal OutVldChain	: std_logic_vector(0 to Taps_g);
	signal OutRound		: std_logic_vector(PsiFixSize(RoundFmt_c)-1 downto 0);
	signal OutRoundVld	: std_logic;
	type Coef_a is array (natural range <>) of std_logic_vector(PsiFixSize(CoefFmt_g)-1 downto 0);
	signal CoefReg		: Coef_a(0 to Taps_g-1);
	signal CoefWe		: std_logic_vector(0 to Taps_g-1);
	
begin
	--------------------------------------------------------------------------
	-- General Control Logic
	--------------------------------------------------------------------------
	p_logic : process(Clk)
	begin
		if rising_edge(Clk) then
			-- Valid chain
			DspVldChain(1 to DspVldChain'high) <= InVld & DspVldChain(1 to DspVldChain'high-1);
			-- Coefficient handling (writable or fixed)
			if UseFixCoefs_g then
				CoefWe <= (others => '1');
				for i in 0 to Taps_g-1 loop
					CoefReg(i) <= PsiFixFromReal(FixCoefs_g(i), CoefFmt_g);
				end loop;
			else
				CoefWe <= (others => '0');
				CoefReg <= (others => CoefWrData);
				if CoefWr = '1' and unsigned(CoefAddr) < Taps_g then
					CoefWe(to_integer(unsigned(CoefAddr))) <= '1';
				end if;
			end if;
			-- Reset
			if Rst = '1' then
				DspVldChain<= (others => '0');
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------
	-- DSP Slice Chain
	--------------------------------------------------------------------------
	-- First DSP slice (connected differently)
	i_slice0 : entity work.psi_fix_mult_add_stage
		generic map (
			InAFmt_g	=> InFmt_g,
			InBFmt_g	=> CoefFmt_g,
			AddFmt_g	=> AccuFmt_c,
			InBIsCoef_g => true
		)
		port map (
			Clk			=> Clk,
			Rst			=> Rst,
			InAVld		=> InVld,
			InA			=> InData,
			InADel2		=> DspDataChainI(0),
			InBVld		=> CoefWe(0),
			InB			=> CoefReg(0),
			AddChainIn	=> (others => '0'),
			AddChainOut	=> DspAccuChain(0),
			AddChainOutVld => OutVldChain(0)
		);
	
	-- Delays (the same for all taps)
	g_delay : for i in 0 to Taps_g-1 generate
		-- No delay is required for the signle channel implementation
		g_1ch : if Channels_g = 1 generate
			DspDataChainO(i) <= DspDataChainI(i);
		end generate;
			
		-- For the multi-channel implementation, adda shift-register based delay
		g_nch : if Channels_g /= 1 generate
			i_delay : entity work.psi_common_delay
				generic map (
					Width_g		=> PsiFixSize(InFmt_g),
					Delay_g		=> Channels_g-1
				)
				port map (
					Clk			=> Clk,
					Rst			=> Rst,
					InData		=> DspDataChainI(i),
					InVld		=> DspVldChain(i+1),
					OutData		=> DspDataChainO(i)
				);
		end generate;
	end generate;
		
	-- All DSP slices except the first one
	g_slices : for i in 1 to Taps_g-1 generate
		i_slice : entity work.psi_fix_mult_add_stage
			generic map (
				InAFmt_g	=> InFmt_g,
				InBFmt_g	=> CoefFmt_g,
				AddFmt_g	=> AccuFmt_c,
				InBIsCoef_g => true
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				InAVld		=> DspVldChain(i),
				InA			=> DspDataChainO(i-1),
				InADel2		=> DspDataChainI(i),
				InB			=> CoefReg(i),
				InBVld		=> CoefWe(i),
				AddChainIn	=> DspAccuChain(i-1),
				AddChainOut	=> DspAccuChain(i),
				AddChainOutVld => OutVldChain(i)
			);
			

	end generate;
			
	--------------------------------------------------------------------------
	-- Output Rounding and Saturation
	--------------------------------------------------------------------------
	p_output : process(Clk) begin
		if rising_edge(Clk) then		
			-- Round
			OutRoundVld <= OutVldChain(Taps_g-1);
			OutRound <= PsiFixResize(DspAccuChain(Taps_g-1), AccuFmt_c, RoundFmt_c, Rnd_g, PsiFixWrap);
			
			-- Saturate
			OutVld <= OutRoundVld;
			OutData <= PsiFixResize(OutRound, RoundFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
		
			-- Reset
			if Rst = '1' then
				OutRoundVld <= '0';
				OutVld <= '0';
			end if;
		end if;
	end process;

	
		
		
end;	





