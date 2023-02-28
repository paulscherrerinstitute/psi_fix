------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component calculateas an FIR filter with the following limitations:
-- - Filter is calculated serially (one tap after the other)
-- - The number of channels is configurable
-- - All channels are processed in parallel and their data must be synchronized
-- - Coefficients are configurable but the same for each channel
------------------------------------------------------------------------------
--
-- Required Memory depth per channel = max_taps_g + max_ratio_g

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

entity psi_fix_fir_dec_ser_nch_chtdm_conf is
  generic(
    in_fmt_g        : psi_fix_fmt_t := (1, 0, 17);      -- internal format
    out_fmt_g       : psi_fix_fmt_t := (1, 0, 17);      -- output format
    coef_fmt_g      : psi_fix_fmt_t := (1, 0, 17);      -- coefficient format
    channels_g      : natural     := 2;                 -- channels
    max_ratio_g     : natural     := 8;                 -- max decimation ratio
    max_taps_g      : natural     := 1024;              -- max number of taps
    rnd_g           : psi_fix_rnd_t := psi_fix_round;   -- rounding truncation
    sat_g           : psi_fix_sat_t := psi_fix_sat;     -- saturate or wrap
    use_fix_coefs_g : boolean     := false;             -- use fix coefficients or update them
    coefs_g         : t_areal     := (0.0, 0.0);        -- see doc
    ram_behavior_g  : string      := "RBW";             -- RBW = Read before write, WBR = Write before read
    rst_pol_g      : std_logic   := '1'                 -- reset polarity active high ='1'
  );
  port(
    clk_i            : in  std_logic;                                             -- system clock
    rst_i            : in  std_logic;                                             -- system reset
    dat_i            : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data input
    vld_i            : in  std_logic;                                             -- valid input Frequency sampling
    dat_o            : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);-- data output
    vld_o            : out std_logic;                                             -- valid output new frequency sampling
    -- Parallel Configuration Interface
    cfg_ratio_i      : in  std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0)  := std_logic_vector(to_unsigned(max_ratio_g - 1, log2ceil(max_ratio_g))); -- Ratio - 1 (0 => Ratio 1, 4 => Ratio 5)
    cfg_taps_i       : in  std_logic_vector(log2ceil(max_taps_g) - 1 downto 0)   := std_logic_vector(to_unsigned(max_taps_g - 1, log2ceil(max_taps_g)));   -- Number of taps - 1
    -- Coefficient interface
    coef_if_clk_i    : in  std_logic                                            := '0';                 -- clock for coef intereface
    coef_if_wr_i     : in  std_logic                                            := '0';                 -- write enable
    coef_if_addr_i   : in  std_logic_vector(log2ceil(max_taps_g) - 1 downto 0)   := (others => '0');    -- address of coef access
    coef_if_wr_dat_i : in  std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0) := (others => '0');  -- coef to write
    coef_if_rd_dat_o : out std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);                     -- coef read
    -- Status Output
    busy_o           : out std_logic                                                                    -- calculation on going active high
  );
end entity;

architecture rtl of psi_fix_fir_dec_ser_nch_chtdm_conf is

  -- Data Memory needs twice the depth since a almost a full set of data can arrive until the last channel is fully processed
  constant DataMemDepthRequired_c : natural := max_taps_g + max_ratio_g; -- max_ratio_g is the maximum samples to arrive before a calculation starts
  constant DataMemAddBits_c       : natural := log2ceil(DataMemDepthRequired_c);
  constant DataMemDepthApplied_c  : natural := 2**DataMemAddBits_c;
  constant CoefMemDepthApplied_c  : natural := 2**log2ceil(max_taps_g);

  -- Constants
  constant MultFmt_c : psi_fix_fmt_t := (max(in_fmt_g.S, coef_fmt_g.S), in_fmt_g.I + coef_fmt_g.I, in_fmt_g.F + coef_fmt_g.F);
  constant AccuFmt_c : psi_fix_fmt_t := (1, out_fmt_g.I + 1, in_fmt_g.F + coef_fmt_g.F);
  constant RndFmt_c  : psi_fix_fmt_t := (1, out_fmt_g.I + 1, out_fmt_g.F);

  -- types
  subtype InData_t is std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  type InData_a is array (natural range <>) of InData_t;
  subtype Mult_t is std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  subtype Accu_t is std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  subtype Rnd_t is std_logic_vector(psi_fix_size(RndFmt_c) - 1 downto 0);
  subtype Out_t is std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  type ChNr_a is array (natural range <>) of std_logic_vector(log2ceil(channels_g) - 1 downto 0);

  -- Two process method
  type two_process_r is record
    FirstAfterRst  : std_logic;
    Vld            : std_logic_vector(0 to 1);
    InSig          : InData_a(0 to 1);
    ChannelNr      : ChNr_a(0 to 3);
    TapWrAddr_1    : std_logic_vector(DataMemAddBits_c - 1 downto 0);
    Tap0Addr_1     : std_logic_vector(DataMemAddBits_c - 1 downto 0);
    DecCnt_1       : std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0);
    TapCnt_1       : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    CalcChnl_1     : std_logic_vector(log2ceil(channels_g) - 1 downto 0);
    CalcChnl_2     : std_logic_vector(log2ceil(channels_g) - 1 downto 0);
    TapRdAddr_2    : std_logic_vector(DataMemAddBits_c - 1 downto 0);
    CoefRdAddr_2   : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    CalcOn         : std_logic_vector(1 to 7);
    Last           : std_logic_vector(1 to 7);
    First          : std_logic_vector(1 to 6);
    MultInTap_4    : InData_t;
    MultInCoef_4   : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    MultInTap_5    : InData_t;
    MultInCoef_5   : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    MultOut_6      : Mult_t;
    Accu_7         : Accu_t;
    Rnd_8          : Rnd_t;
    RndVld_8       : std_logic;
    Output_9       : Out_t;
    OutVld_9       : std_logic;
    FirstTapLoop_3 : std_logic;
    TapRdAddr_3    : std_logic_vector(DataMemAddBits_c - 1 downto 0);
    ReplaceZero_4  : std_logic;
    -- Status
    CalcOngoing    : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- Component Interface Signals
  signal DataRamWrAddr_1 : std_logic_vector(DataMemAddBits_c + log2ceil(channels_g) - 1 downto 0);
  signal DataRamRdAddr_2 : std_logic_vector(DataMemAddBits_c + log2ceil(channels_g) - 1 downto 0);
  signal DataRamDout_3   : std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  signal CoefRamDout_3   : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);

  -- coef ROM
  type CoefRom_t is array (0 to 2**log2ceil(max_taps_g) - 1) of std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0); -- full power of two to ensure index is always valid
  signal CoefRom : CoefRom_t := (others => (others => '0'));

begin

  assert channels_g >= 2 report "###ERROR###: psi_fix_fir_dec_ser_nch_chtdm_conf only works for channels_g >= 2, use psi_fix_fir_dec_ser_nch_chtpar_conf for single channel implementation" severity error;

  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(r, vld_i, dat_i, cfg_ratio_i, cfg_taps_i, DataRamDout_3, CoefRamDout_3)
    variable v        : two_process_r;
    variable AccuIn_v : std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high)                   := r.Vld(r.Vld'low to r.Vld'high - 1);
    v.InSig(v.InSig'low + 1 to v.InSig'high)             := r.InSig(r.InSig'low to r.InSig'high - 1);
    v.CalcOn(v.CalcOn'low + 1 to v.CalcOn'high)          := r.CalcOn(r.CalcOn'low to r.CalcOn'high - 1);
    v.Last(v.Last'low + 1 to v.Last'high)                := r.Last(r.Last'low to r.Last'high - 1);
    v.First(v.First'low + 1 to v.First'high)             := r.First(r.First'low to r.First'high - 1);
    v.ChannelNr(v.ChannelNr'low + 1 to v.ChannelNr'high) := r.ChannelNr(r.ChannelNr'low to r.ChannelNr'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.Vld(0)   := vld_i;
    v.InSig(0) := dat_i;

    -- Calculate channel number
    if vld_i = '1' then
      if unsigned(r.ChannelNr(0)) = channels_g - 1 or r.FirstAfterRst = '1' then
        v.ChannelNr(0)  := (others => '0');
        v.FirstAfterRst := '0';
      else
        v.ChannelNr(0) := std_logic_vector(unsigned(r.ChannelNr(0)) + 1);
      end if;
    end if;

    -- *** Stage 1 ***
    -- Increment tap address after data was written for last channel
    if (r.Vld(1) = '1') and (unsigned(r.ChannelNr(1)) = channels_g - 1) then
      v.TapWrAddr_1 := std_logic_vector(unsigned(r.TapWrAddr_1) + 1);
    end if;

    -- Decimation & Calculation Control
    -- Initial value
    v.First(1) := '0';
    v.Last(1)  := '0';

    -- normal update
    v.TapCnt_1 := std_logic_vector(unsigned(r.TapCnt_1) - 1);
    -- last tap of a channel
    if unsigned(r.TapCnt_1) = 1 or unsigned(cfg_taps_i) = 0 then
      v.Last(1) := '1';
    end if;
    -- goto next channel or finish calculation
    if unsigned(r.TapCnt_1) = 0 then
      -- last channel
      if unsigned(r.CalcChnl_1) = channels_g - 1 then
        v.CalcOn(1) := '0';
      -- goto next channel
      else
        v.First(1)   := '1';
        v.CalcChnl_1 := std_logic_vector(unsigned(r.CalcChnl_1) + 1);
        v.TapCnt_1   := cfg_taps_i;
      end if;
    end if;

    -- start of calculation and decimation
    if r.Vld(0) = '1' then
      -- Start calculation (data from all channels available)
      if unsigned(r.ChannelNr(0)) = channels_g - 1 then
        if (unsigned(r.DecCnt_1) = 0) or (max_ratio_g = 0) then
          v.Tap0Addr_1 := r.TapWrAddr_1;
          v.TapCnt_1   := cfg_taps_i;
          v.CalcOn(1)  := '1';
          v.First(1)   := '1';
          v.CalcChnl_1 := (others => '0');
          v.DecCnt_1   := cfg_ratio_i;
        else
          v.DecCnt_1 := std_logic_vector(unsigned(r.DecCnt_1) - 1);
        end if;
      end if;
    end if;

    -- *** Stage 2 ***
    -- pipelining
    v.CalcChnl_2 := r.CalcChnl_1;

    -- Tap read address
    v.TapRdAddr_2  := std_logic_vector(unsigned(r.Tap0Addr_1) - unsigned(r.TapCnt_1));
    v.CoefRdAddr_2 := r.TapCnt_1;

    -- *** Stage 3 ***
    -- Pipelining
    v.TapRdAddr_3 := r.TapRdAddr_2;

    -- *** Stage 4 ***
    -- Multiplier input registering
    -- Replace taps that are not yet written with zeros for bittrueness
    if r.ReplaceZero_4 = '0' or unsigned(r.TapRdAddr_3) <= unsigned(cfg_ratio_i) then
      v.MultInTap_4 := DataRamDout_3;
    else
      v.MultInTap_4 := (others => '0');
    end if;
    -- Detect when the Zero-replacement can be stopped since the taps are already filled with correct data
    if r.FirstTapLoop_3 = '0' then
      v.ReplaceZero_4 := '0';
    elsif r.CalcOn(3) = '1' then
      if r.First(3) = '1' and unsigned(r.TapRdAddr_3) <= unsigned(cfg_ratio_i) then
        v.ReplaceZero_4 := '0';
        if unsigned(r.ChannelNr(3)) = channels_g - 1 then
          v.FirstTapLoop_3 := '0';
        end if;
      elsif r.Last(3) = '1' then
        v.ReplaceZero_4 := '1';
      elsif unsigned(r.TapRdAddr_3) = 0 then
        v.ReplaceZero_4 := '0';
      end if;
    end if;
    v.MultInCoef_4 := CoefRamDout_3;

    -- *** Stage 5 ***
    -- Multiplier input registers
    v.MultInTap_5 := r.MultInTap_4;
    v.MultInCoef_5 := r.MultInCoef_4;
    
    -- *** Stage 6 *** 
    -- Multiplication
    v.MultOut_6 := psi_fix_mult(r.MultInTap_5, in_fmt_g,
                                r.MultInCoef_5, coef_fmt_g,
                                MultFmt_c); -- Full precision, no rounding or saturation required

    -- *** Stage 7 ***
    -- Accumulator
    if r.First(6) = '1' then
      AccuIn_v := (others => '0');
    else
      AccuIn_v := r.Accu_7;
    end if;
    v.Accu_7 := psi_fix_add(r.MultOut_6, MultFmt_c,
                          AccuIn_v, AccuFmt_c,
                          AccuFmt_c);   -- Overflows compensate at the end of the calculation and rounding not required

    -- *** Stage 8 ***
    -- Rounding
    v.RndVld_8 := '0';
    if r.Last(7) = '1' then
      v.Rnd_8    := psi_fix_resize(r.Accu_7, AccuFmt_c, RndFmt_c, rnd_g, psi_fix_wrap);
      v.RndVld_8 := r.CalcOn(7);
    end if;

    -- *** Stage 9 ***
    -- Output Handling and saturation
    v.OutVld_9 := r.RndVld_8;
    v.Output_9 := psi_fix_resize(r.Rnd_8, RndFmt_c, out_fmt_g, psi_fix_trunc, sat_g);

    -- *** Status Output ***
    if (unsigned(r.Vld) /= 0) or (unsigned(r.CalcOn) /= 0) or (r.RndVld_8 = '1') then
      v.CalcOngoing := '1';
    else
      v.CalcOngoing := '0';
    end if;

    -- *** Outputs ***
    vld_o  <= r.OutVld_9;
    dat_o  <= r.Output_9;
    busy_o <= r.CalcOngoing or r.Vld(0);

    -- *** Assign to signal ***
    r_next <= v;
  end process;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.Vld            <= (others => '0');
        r.ChannelNr(0)   <= (others => '0');
        r.CalcChnl_1     <= (others => '0');
        r.TapWrAddr_1    <= (others => '0');
        r.DecCnt_1       <= (others => '0');
        r.CalcOn         <= (others => '0');
        r.RndVld_8       <= '0';
        r.OutVld_9       <= '0';
        r.Last           <= (others => '0');
        r.ReplaceZero_4  <= '1';
        r.CalcOngoing    <= '0';
        r.FirstAfterRst  <= '1';
        r.FirstTapLoop_3 <= '1';
        r.TapCnt_1       <= cfg_taps_i;
      end if;
    end if;
  end process;

  --------------------------------------------
  -- Component Instantiations
  --------------------------------------------
  -- Coefficient RAM for configurable coefficients
  g_nFixCoef : if not use_fix_coefs_g generate
    i_coef_ram : entity work.psi_fix_param_ram
      generic map(
        depth_g    => CoefMemDepthApplied_c,
        fmt_g      => coef_fmt_g,
        behavior_g => ram_behavior_g,
        init_g     => coefs_g
      )
      port map(
        ClkA  => coef_if_clk_i,
        AddrA => coef_if_addr_i,
        WrA   => coef_if_wr_i,
        DinA  => coef_if_wr_dat_i,
        DoutA => coef_if_rd_dat_o,
        ClkB  => clk_i,
        AddrB => r.CoefRdAddr_2,
        WrB   => '0',
        DinB  => (others => '0'),
        DoutB => CoefRamDout_3
      );
  end generate;

  -- Coefficient ROM for non-configurable coefficients
  g_FixCoef : if use_fix_coefs_g generate
    -- Table must be generated outside of the ROM process to make code synthesizable
    g_CoefTable : for i in coefs_g'low to coefs_g'high generate
      CoefRom(i) <= psi_fix_from_real(coefs_g(i), coef_fmt_g);
    end generate;

    -- Assign unused outputs
    coef_if_rd_dat_o <= (others => '0');
    -- Coefficient ROM
    p_coef_rom : process(clk_i)
    begin
      if rising_edge(clk_i) then
        CoefRamDout_3 <= CoefRom(to_integer(unsigned(r.CoefRdAddr_2)));
      end if;
    end process;

  end generate;

  DataRamWrAddr_1 <= r.ChannelNr(1) & r.TapWrAddr_1;
  DataRamRdAddr_2 <= r.CalcChnl_2 & r.TapRdAddr_2;

  i_data_ram : entity work.psi_common_tdp_ram
    generic map(
      depth_g    => DataMemDepthApplied_c * channels_g,
      width_g    => psi_fix_size(in_fmt_g),
      behavior_g => ram_behavior_g
    )
    port map(
      ClkA  => clk_i,
      AddrA => DataRamWrAddr_1,
      WrA   => r.Vld(1),
      DinA  => r.InSig(1),
      DoutA => open,
      ClkB  => clk_i,
      AddrB => DataRamRdAddr_2,
      WrB   => '0',
      DinB  => (others => '0'),
      DoutB => DataRamDout_3
    );

end architecture;

