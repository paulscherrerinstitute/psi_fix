------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculateas an FIR filter with the following limitations:
-- - Filter is calculated semi-parallel
-- - The number of channels is configurable
-- - All channels are processed time-division-multiplexed
-- - Coefficients are configurable but the same for each channel
-- - After the reset, the delay lines are not flushed. So tranisents may occur for the first few samples after resetting the filter.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_fix_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim, resp $$
entity psi_fix_fir_dec_semi_nch_chtdm_conf is
	generic (
		InFmt_g					: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,0,15) $$
		OutFmt_g				: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,2,13) $$
		CoefFmt_g				: PsiFixFmt_t	:= (1, 0, 17);			-- $$ constant=(1,0,17) $$
		Channels_g				: natural		:= 4;					-- $$ export=true $$
		Multipliers_g			: natural		:= 4;
		Ratio_g					: natural		:= 8;
		Taps_g					: natural		:= 32;	
		Rnd_g					: PsiFixRnd_t	:= PsiFixRound;
		Sat_g					: PsiFixSat_t	:= PsiFixSat;
		UseFixCoefs_g			: boolean		:= false;
		FullInpRateSupport_g	: boolean		:= false;
		RamBehavior_g			: string		:= "RBW";		-- "RBW" = read-before-write, "WBR" = write-before-read
		Coefs_g					: t_areal		:= (0.1, 0.2);
		ImplFlushIf_g			: boolean		:= false
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
		-- Coefficient interface		
		CoefWr		: in	std_logic											:= '0';
		CoefAddr	: in	std_logic_vector(log2ceil(Taps_g)-1 downto 0)		:= (others => '0');
		CoefWrData	: in	std_logic_vector(PsiFixSize(CoefFmt_g)-1 downto 0)	:= (others => '0');
		-- Delay-line flushing interface
		FlushMem	: in	std_logic											:= '0';
		FlushDone	: out	std_logic;
		-- Status Output
		CalcOngoing	: out	std_logic
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_fir_dec_semi_nch_chtdm_conf is

	-- RAM Calculation
	constant TapsPerStage_c		: natural	:= integer(ceil(real(Taps_g)/real(Multipliers_g)));	
	constant RamPerChPerStage_c	: natural	:= 2**log2ceil(TapsPerStage_c+Ratio_g+1);
	constant TapSelBits_c		: natural	:= log2ceil(RamPerChPerStage_c);
	constant RamPerStage_c		: natural	:= 2**log2ceil(RamPerChPerStage_c*Channels_g);	
	constant RamAddrBits_c		: natural	:= log2ceil(RamPerStage_c);
	constant ChSelBits_c		: natural	:= log2ceil(Channels_g);
	
	-- Constants
	constant AccuFmt_c			: PsiFixFmt_t	:= (1, InFmt_g.I+CoefFmt_g.I+log2ceil(Multipliers_g), InFmt_g.F + CoefFmt_g.F);
	constant RoundFmt_c			: PsiFixFmt_t	:= (1, AccuFmt_c.I+1, OutFmt_g.F);
	constant CyclesPerCalc_c	: integer		:= integer(ceil(real(Taps_g)/real(Multipliers_g)));
	
	-- types
	type TapAddr_a is array (natural range <>) of unsigned(TapSelBits_c-1 downto 0);
	type Channel_a is array (natural range <>) of unsigned(ChSelBits_c-1 downto 0);
	type Data_a is array (natural range <>) of std_logic_vector(InData'range);
	type Addr_a is array (natural range <>) of std_logic_vector(RamAddrBits_c-1 downto 0);
	type Coef_a is array (natural range <>) of std_logic_vector(PsiFixSize(CoefFmt_g)-1 downto 0);
	type Accu_a is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
	type CoefAddr_a is array (natural range <>) of std_logic_vector(log2ceil(TapsPerStage_c)-1 downto 0);

	-- Two process method
	type two_process_r is record
		Vld				: std_logic_vector(0 to max(1, Multipliers_g));	
		Data_0			: std_logic_vector(InData'range);
		Data_1			: std_logic_vector(InData'range);
		DecCnt_0		: integer range 0 to Ratio_g-1;
		ChCnt			: Channel_a(0 to max(Multipliers_g,1));
		TapUpdWrAddr_0	: unsigned(TapSelBits_c-1 downto 0);
		TapUpdAddr		: TapAddr_a(1 to max(Multipliers_g,1));
		CalcStartLoop_1	: std_logic;
		CalcFirst		: std_logic_vector(2 to 7+Multipliers_g);
		CalcLast		: std_logic_vector(2 to 7+Multipliers_g);
		CalcCycLeft_2	: integer range 0 to CyclesPerCalc_c-1;
		CalcChannel_2	: unsigned(log2ceil(Channels_g)-1 downto 0);
		CalcFirstTap_2	: unsigned(TapSelBits_c-1 downto 0);
		CalcRunning		: std_logic_vector(2 to 7+Multipliers_g);
		TapRdAddr_2		: unsigned(TapSelBits_c-1 downto 0);
		CoefRdIdx_2		: unsigned(TapSelBits_c-1 downto 0);
		CoefRdAddr		: TapAddr_a(3 to 3+Multipliers_g);
		TapRdAddr		: Addr_a(3 to 3+Multipliers_g);
		Accu_8n			: std_logic_vector(PsiFixSize(AccuFmt_c)-1 downto 0);
		OutVld_n		: std_logic_vector(8 to 10);
		Rnd_9n			: std_logic_vector(PsiFixSize(RoundFmt_c)-1 downto 0);
		OutData_10n		: std_logic_vector(PsiFixSize(OutFmt_g)-1 downto 0);
		-- Coefficient write access (not in calculation pipeline)
		CoefWrStg		: std_logic_vector(0 to Multipliers_g-1);
		CoefWrDataStg	: std_logic_vector(CoefWrData'range);
		CoefAddrStg		: CoefAddr_a(0 to Multipliers_g-1);
		-- Memory Flusing
		FlushActive		: std_logic;
		FlushAddr		: std_logic_vector(RamAddrBits_c-1 downto 0);
		FlushDone		: std_logic;
		-- Status
		CalcOngoing		: std_logic;
	end record;
	signal r, r_next : two_process_r;
	
	-- Functions
	function GetCoefs(	stage : integer) return Coef_a is
		variable Coefs_v 	: Coef_a(0 to TapsPerStage_c-1) := (others => (others => '0'));
		variable Idx_v		: natural	:= stage*Multipliers_g;
	begin
		if UseFixCoefs_g then
			for i in 0 to TapsPerStage_c-1 loop
				if (stage*TapsPerStage_c+i < Taps_g) and (stage*TapsPerStage_c+i < Coefs_g'length) then
					Coefs_v(i)	:= PsiFixFromReal(Coefs_g(stage*TapsPerStage_c+i), CoefFmt_g);
				end if;
			end loop;
		end if;
		return Coefs_v;
	end function;
	
	function GetCoefsReal(	stage : integer) return t_areal is
		variable Coefs_v 	: t_areal(0 to TapsPerStage_c-1) := (others => 0.0);
		variable Idx_v		: natural	:= stage*Multipliers_g;
	begin
		for i in 0 to TapsPerStage_c-1 loop
			if (stage*TapsPerStage_c+i < Taps_g) and (stage*TapsPerStage_c+i < Coefs_g'length) then
				Coefs_v(i)	:= Coefs_g(stage*TapsPerStage_c+i);
			end if;
		end loop;
		return Coefs_v;
	end function;
	
	
	-- Component Instantiation Signals
	signal DataInChain 	: Data_a(1 to Multipliers_g+1);
	signal AccuChain	: Accu_a(7 to 7+Multipliers_g);
	signal AccuVld		: std_logic_vector(8 to 8+Multipliers_g-1);
	
begin

	--------------------------------------------
	-- Asserts
	--------------------------------------------
	p_assert : process(Clk)
	begin
		if rising_edge(Clk) then
			-- Check if input rate is correct
			if not FullInpRateSupport_g then
				assert (r.Vld(0) /= '1') or (r.Vld(1) /= '1')
					report "###ERROR###: psi_fix_fir_dec_semi_nch_chtdm_conf implemented with FullInpRateSupport_g=false but InVld asserted for two consecutive clock cycles!"
					severity error;
			end if;
			-- Check if processing power is sufficient and print errors otherwise so the problem is detected easily during simulations
			if r.CalcStartLoop_1 = '1' then
				assert (r.CalcRunning(2) = '0') or (((r.CalcChannel_2 = Channels_g-1) or (Channels_g = 1)) and (r.CalcLast(2) = '1'))
					report "###ERROR###: psi_fix_fir_dec_semi_nch_chtdm_conf insufficient processing power to handle data rate! (Multipliers_g is set too low!)"
					severity error;
			end if;
		end if;
	end process;
		
	--------------------------------------------
	-- Combinatorial Process
	--------------------------------------------
	p_comb : process(	r, InVld, InData, AccuChain, AccuVld,
						CoefWrData, CoefAddr, CoefWr, FlushMem)
		variable v : two_process_r;
		variable StartLoop_v	: boolean;
		
	begin
		-- *** Hold variables stable ***
		v := r;
		
		-- *** Pipe Handling ***
		v.Vld(v.Vld'low+1 to v.Vld'high)								:= r.Vld(r.Vld'low to r.Vld'high-1);
		v.TapUpdAddr(v.TapUpdAddr'low+1 to v.TapUpdAddr'high)				:= r.TapUpdAddr(r.TapUpdAddr'low to r.TapUpdAddr'high-1);
		v.CoefRdAddr(v.CoefRdAddr'low+1 to v.CoefRdAddr'high)			:= r.CoefRdAddr(r.CoefRdAddr'low to r.CoefRdAddr'high-1);
		v.TapRdAddr(v.TapRdAddr'low+1 to v.TapRdAddr'high)				:= r.TapRdAddr(r.TapRdAddr'low to r.TapRdAddr'high-1);
		v.CalcRunning(v.CalcRunning'low+1 to v.CalcRunning'high)		:= r.CalcRunning(r.CalcRunning'low to r.CalcRunning'high-1);
		v.CalcFirst(v.CalcFirst'low+1 to v.CalcFirst'high)				:= r.CalcFirst(r.CalcFirst'low to r.CalcFirst'high-1);
		v.CalcLast(v.CalcLast'low+1 to v.CalcLast'high)					:= r.CalcLast(r.CalcLast'low to r.CalcLast'high-1);
		v.OutVld_n(v.OutVld_n'low+1 to v.OutVld_n'high)					:= r.OutVld_n(r.OutVld_n'low to r.OutVld_n'high-1);
		v.ChCnt(v.ChCnt'low+1 to v.ChCnt'high)							:= r.ChCnt(r.ChCnt'low to r.ChCnt'high-1);
		
		-- *** Stage 0 ***
		v.Vld(0)	:= InVld;
		v.Data_0	:= InData;
		if r.Vld(0) = '1' then
			if (r.ChCnt(0) = Channels_g-1) or (Channels_g = 1) then
				v.ChCnt(0) := (others => '0');
				if r.DecCnt_0 = 0 then
					v.DecCnt_0 := Ratio_g-1;
				else	
					v.DecCnt_0 := r.DecCnt_0-1;
				end if;
				v.TapUpdWrAddr_0	:= r.TapUpdWrAddr_0+1;
			else
				v.ChCnt(0) := r.ChCnt(0) + 1;
			end if;
		end if;
		
		-- *** Stage 1 ***
		v.Data_1			:= r.Data_0;
		v.CalcStartLoop_1 	:= '0';
		if r.Vld(0) = '1' and r.DecCnt_0 = 0 and ((r.ChCnt(0) = Channels_g-1) or (Channels_g = 1)) then
			v.CalcStartLoop_1 := '1';
		end if;
		-- Write on the cycle a new sample is arriving
		if r.Vld(0) = '1' then
			v.TapUpdAddr(1) := r.TapUpdWrAddr_0;
		-- Read in between to execute Read-before-write literally 
		elsif not FullInpRateSupport_g then
			v.TapUpdAddr(1) := r.TapUpdWrAddr_0 - TapsPerStage_c;
		end if;
		
		
		-- *** Stage 2 ***
		-- Default values
		v.CalcFirst(2) 	:= '0';
		v.CalcLast(2) 	:= '0';
		StartLoop_v		:= false;		
		-- Start calculation loop
		if r.CalcStartLoop_1 = '1'then
			v.CalcChannel_2		:= (others => '0');
			v.CalcFirstTap_2	:= r.TapUpdAddr(1);
			v.TapRdAddr_2		:= r.TapUpdAddr(1);
			StartLoop_v			:= true;
			v.CalcRunning(2)	:= '1';
		elsif r.CalcRunning(2) = '1' then
			v.CoefRdIdx_2	:= r.CoefRdIdx_2-1;
			v.TapRdAddr_2 	:= r.TapRdAddr_2+1;
			if r.CalcCycLeft_2 <= 1 then
				v.CalcLast(2) := '1';
			end if;
			if r.CalcCycLeft_2 /= 0 then
				v.CalcCycLeft_2 := r.CalcCycLeft_2 - 1;
			end if;
		end if;
		-- After calculation is done ...
		if (r.CalcLast(2) = '1') and (r.CalcRunning(2) = '1') then
			v.CalcLast(2) := '0';
			-- ... start next channel if the current channe lwas not the last one
			if (r.CalcChannel_2 /= Channels_g-1) and (Channels_g /= 1)  then
				v.CalcChannel_2	:= r.CalcChannel_2 + 1;
				v.TapRdAddr_2	:= r.CalcFirstTap_2;
				StartLoop_v		:= true;
			-- ... finish calculation loop otherwise
			elsif r.CalcStartLoop_1 = '0' then
				v.CalcRunning(2)	:= '0';
			end if;
		end if;
		-- Handle start loop behavior (shared code in two places)
		if StartLoop_v then
			v.CalcFirst(2) 		:= '1';
			v.CalcCycLeft_2		:= CyclesPerCalc_c-1;
			v.CoefRdIdx_2		:= to_unsigned(TapsPerStage_c-1, v.CoefRdIdx_2'length);
			if Taps_g <= Multipliers_g then
				v.CalcLast(2) := '1';
			end if;
		end if;
		
		-- *** Stage 3 ***
		v.CoefRdAddr(3)	:= r.CoefRdIdx_2;
		v.TapRdAddr(3)	:= std_logic_vector(r.CalcChannel_2) & std_logic_vector(signed(r.TapRdAddr_2) - TapsPerStage_c + 1);
		
		-- *** Memory Flushing (happens outside of pipeline)
		v.FlushDone	:= '0';
		if ImplFlushIf_g then
			-- start flushing
			if FlushMem = '1' then
				v.FlushActive 	:= '1';
				v.FlushAddr		:= (others => '0');
			-- End flushing
			elsif signed(r.FlushAddr) = -1 then
				v.FlushActive	:= '0';
				v.FlushDone		:= '1';
				v.FlushAddr		:= (others => '0');
			-- Continue Flushing
			elsif r.FlushActive = '1' then
				v.FlushAddr		:= std_logic_vector(unsigned(r.FlushAddr) + 1);
			end if;
		end if;
		
		-- *** Output Summation ***
		v.OutVld_n(8)	:= '0';
		if r.CalcRunning(7+Multipliers_g) = '1' and AccuVld(7+Multipliers_g) = '1' then
			if r.CalcFirst(7+Multipliers_g) = '1' then
				v.Accu_8n	:= AccuChain(7+Multipliers_g);
			else
				v.Accu_8n 	:= PsiFixAdd(r.Accu_8n, AccuFmt_c, AccuChain(7+Multipliers_g), AccuFmt_c, AccuFmt_c);
			end if;
			if r.CalcLast(7+Multipliers_g) = '1' then
				v.OutVld_n(8)	:= '1';
			end if;
		end if;
		
		-- *** Output Rounding ***
		v.Rnd_9n	:= PsiFixResize(r.Accu_8n, AccuFmt_c, RoundFmt_c, Rnd_g, PsiFixWrap);
		
		-- *** Output Saturation ***
		v.OutData_10n	:= PsiFixResize(r.Rnd_9n, RoundFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);
		
		-- *** Coefficient Write Access (not in calculation pipeline) ***
		if not UseFixCoefs_g then
			v.CoefWrDataStg	:= CoefWrData;
			v.CoefWrStg		:= (others => '0');
			
			for m in 0 to Multipliers_g-1 loop
				if unsigned(CoefAddr) >= m*TapsPerStage_c and unsigned(CoefAddr) < (m+1)*TapsPerStage_c then
					v.CoefWrStg(m) := CoefWr;
				end if;
				v.CoefAddrStg(m)	:= std_logic_vector(resize(unsigned(CoefAddr) - m*TapsPerStage_c, v.CoefAddrStg(m)'length));
			end loop;
		end if;
		
		-- *** Status Output ***
		if (unsigned(r.Vld) /= 0) or (unsigned(r.CalcRunning) /= 0) or (unsigned(r.OutVld_n(r.OutVld_n'low to r.OutVld_n'high-1)) /= 0) then
			v.CalcOngoing := '1';
		else
			v.CalcOngoing := '0';
		end if;
		
		-- *** Outputs ***	
		OutData	<= r.OutData_10n;
		OutVld	<= r.OutVld_n(10);
		FlushDone <= r.FlushDone;
		CalcOngoing <= r.CalcOngoing or r.Vld(0);
		
		-- *** Assign to signal ***
		r_next <= v;
	end process;
	

	
	--------------------------------------------
	-- Sequential Process
	--------------------------------------------
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then	
			r <= r_next;
			if Rst = '1' then	
				r.Vld 				<= (others => '0');
				r.DecCnt_0			<= 0;
				r.ChCnt(0)			<= (others => '0');
				r.TapUpdWrAddr_0	<= (others => '0');
				r.CalcRunning		<= (others => '0');
				r.FlushActive		<= '0';
				r.FlushDone			<= '0';
				r.CalcOngoing		<= '0';
			end if;
		end if;
	end process;
	
	--------------------------------------------
	-- Component Instantiations
	--------------------------------------------
	DataInChain(1) 	<= r.Data_1;
	AccuChain(7)	<= (others => '0');
	g_mac : for i in 0 to Multipliers_g-1 generate
		signal DataWrAddr_1i 	: std_logic_vector(RamAddrBits_c-1 downto 0);
		signal DataWr			: std_logic;
		signal DataDin			: std_logic_vector(InData'range);
		signal RdData_4i		: std_logic_vector(InData'range);
		signal Coef_4i			: std_logic_vector(PsiFixSize(CoefFmt_g)-1 downto 0);
		constant StageCoefs_c	: Coef_a(0 to TapsPerStage_c-1)		:= GetCoefs(i);
		constant StageCoefsR_c	: t_areal(0 to TapsPerStage_c-1)	:= GetCoefsReal(i);
		signal RamRdData		: std_logic_vector(InData'range);
		signal FullRateDel		: std_logic_vector(InData'range);
	begin
	
		-- *** Tap Data RAM***
		g_noflush : if not ImplFlushIf_g generate
			DataWrAddr_1i 	<= std_logic_vector(r.ChCnt(i+1)) & std_logic_vector(r.TapUpdAddr(i+1));
			DataWr			<= r.Vld(i+1);
			DataDin			<= DataInChain(i+1);
		end generate;
		g_flush : if ImplFlushIf_g generate
			DataWrAddr_1i 	<= std_logic_vector(r.ChCnt(i+1)) & std_logic_vector(r.TapUpdAddr(i+1)) when r.FlushActive = '0' else r.FlushAddr;
			DataWr			<= r.Vld(i+1) when r.FlushActive = '0' else '1';
			DataDin			<= DataInChain(i+1) when r.FlushActive = '0' else (others => '0');
		end generate;

		i_data_ram : entity work.psi_common_tdp_ram
			generic map (
				Depth_g		=> RamPerStage_c,
				Width_g		=> PsiFixSize(InFmt_g),
				Behavior_g	=> RamBehavior_g
			)
			port map (
				ClkA		=> Clk,
				AddrA		=> DataWrAddr_1i,
				WrA			=> DataWr,
				DinA		=> DataDin,
				DoutA		=> RamRdData,
				ClkB		=> Clk,
				AddrB		=> r.TapRdAddr(3+i),
				WrB			=> '0',
				DinB		=> (others => '0'),
				DoutB		=> RdData_4i
			);
			
		-- *** Tap data delay  ***
		-- for full input rate support, a separate delay chain is used
		g_fullrate : if FullInpRateSupport_g generate
			i_tapdelay : entity work.psi_common_delay
				generic map (
					Width_g			=> PsiFixSize(InFmt_g),
					Delay_g			=> Channels_g*TapsPerStage_c,
					Resource_g		=> "AUTO",
					RstState_g		=> ImplFlushIf_g,	-- the tap delay only needs to be reset cleanly if the memory can be flushed too. Otherwise leftovers are in memory anyways.
					RamBehavior_g	=> RamBehavior_g
				)
				port map (
					Clk			=> Clk,
					Rst			=> Rst,
					InData		=> DataInChain(i+1),
					InVld		=> r.Vld(i+1),
					OutData		=> FullRateDel 
				);
		end generate;		
		-- Otherwise the RAM output is delayed
		p_ram_fw_del : process(Clk)
		begin
			if rising_edge(Clk) then
				if not FullInpRateSupport_g then
					DataInChain(i+2) <= RamRdData;
				else
					DataInChain(i+2) <= FullRateDel;
				end if;
			end if;
		end process;
			
		-- *** Coefficient ROM (fixed coefs) ***
		g_coefrom : if UseFixCoefs_g generate
			p_coef_rom : process(Clk)
			begin
				if rising_edge(Clk) then
					if r.CoefRdAddr(3+i) < TapsPerStage_c then
						Coef_4i <= StageCoefs_c(to_integer(r.CoefRdAddr(3+i)));
					else
						Coef_4i <= (others => '0');
					end if;
				end if;
			end process;
		end generate;
		
		-- *** Coefficient RAM (configurable coefs) ***
		g_coefram : if not UseFixCoefs_g generate
			signal RdAddr	: std_logic_vector(log2ceil(TapsPerStage_c)-1 downto 0);
		begin
			RdAddr <= std_logic_vector(r.CoefRdAddr(3+i)(RdAddr'range));
			i_coef_ram : entity work.psi_fix_param_ram
				generic map (
					Depth_g		=> 2**log2ceil(TapsPerStage_c),
					Fmt_g		=> CoefFmt_g,
					Behavior_g	=> RamBehavior_g,
					Init_g		=> StageCoefsR_c
				)
				port map (
					ClkA	=> Clk,
					AddrA	=> r.CoefAddrStg(i),
					WrA		=> r.CoefWrStg(i),
					DinA	=> r.CoefWrDataStg,
					DoutA	=> open,
					ClkB	=> Clk,
					AddrB	=> RdAddr,
					WrB		=> '0',
					DinB	=> (others => '0'),
					DoutB	=> Coef_4i
				);
			
			--i_coef_ram : entity work.psi_common_sdp_ram
			--	generic map (
			--		Depth_g		=> 2**log2ceil(TapsPerStage_c),
			--		Width_g		=> PsiFixSize(CoefFmt_g),
			--		IsAsync_g	=> false,
			--		Behavior_g	=> RamBehavior_g
			--	)
			--	port map (
			--		Clk		=> Clk,
			--		RdClk	=> Clk,
			--		WrAddr	=> r.CoefAddrStg(i),
			--		Wr		=> r.CoefWrStg(i),
			--		WrData	=> r.CoefWrDataStg,
			--		RdAddr	=> RdAddr,
			--		Rd		=> '1',
			--		RdData	=> Coef_4i
			--	);
		end generate;

		-- *** Multiply and Add ***
		i_multadd : entity work.psi_fix_mult_add_stage
			generic map (
				InAFmt_g		=> InFmt_g,
				InBFmt_g		=> CoefFmt_g,
				AddFmt_g		=> AccuFmt_c,
				InBIsCoef_g		=> false
			)
			port map (
				Clk				=> Clk,
				Rst				=> Rst,
				InAVld			=> r.CalcRunning(4+i),
				InA				=> RdData_4i,
				InADel2			=> open,
				InBVld			=> r.CalcRunning(4+i),
				InB				=> Coef_4i,
				InBDel2			=> open,
				AddChainIn		=> AccuChain(7+i),
				AddChainOut		=> AccuChain(8+i),
				AddChainOutVld	=> AccuVld(8+i)
			);
	
	end generate;
	
		
end;	





