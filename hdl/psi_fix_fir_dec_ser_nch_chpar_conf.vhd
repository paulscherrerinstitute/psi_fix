------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

-- @ formatter:off
entity psi_fix_fir_dec_ser_nch_chpar_conf is
  generic(in_fmt_g       : psi_fix_fmt_t := (1, 0, 17);    -- internal format
          out_fmt_g      : psi_fix_fmt_t := (1, 0, 17);    -- output format
          coef_fmt_g     : psi_fix_fmt_t := (1, 0, 17);    -- coefficient format
          channels_g    : natural     := 2;               -- channels
          max_ratio_g    : natural     := 8;               -- max decimation ratio
          max_taps_g     : natural     := 1024;            -- max number of taps
          rnd_g         : psi_fix_rnd_t := psi_fix_round;   -- rounding truncation
          sat_g         : psi_fix_sat_t := psi_fix_sat;     -- saturate or wrap
          use_fix_coefs_g : boolean     := false;           -- use fix coefficients or update them
          coefs_g       : t_areal     := (0.0, 0.0);      -- see doc
          ram_behavior_g : string      := "RBW";           -- RBW = Read before write, WBR = Write before read
          rst_pol_g     : std_logic   := '1'              -- reset polarity active high ='1'
          );
  port(clk_i            : in  std_logic;                                                                -- system clock
       rst_i            : in  std_logic;                                                                -- system reset
       dat_i            : in  std_logic_vector(psi_fix_size(in_fmt_g) * channels_g - 1 downto 0);          -- data input
       vld_i            : in  std_logic;                                                                -- valid input Frequency sampling
       dat_o            : out std_logic_vector(psi_fix_size(out_fmt_g) * channels_g - 1 downto 0);         -- data output
       vld_o            : out std_logic;                                                                -- valid output new frequency sampling
       -- Parallel Configuration Interface
       cfg_ratio_i      : in  std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0)  := std_logic_vector(to_unsigned(max_ratio_g - 1, log2ceil(max_ratio_g))); -- Ratio - 1 (0 => Ratio 1, 4 => Ratio 5)
       cfg_taps_i       : in  std_logic_vector(log2ceil(max_taps_g) - 1 downto 0)   := std_logic_vector(to_unsigned(max_taps_g - 1, log2ceil(max_taps_g)));   -- Number of taps - 1
       -- Coefficient interface
       coef_if_clk_i    : in  std_logic                                            := '0';             -- clock for coef intereface
       coef_if_wr_i     : in  std_logic                                            := '0';             -- write enable
       coef_if_addr_i   : in  std_logic_vector(log2ceil(max_taps_g) - 1 downto 0)   := (others => '0'); -- address of coef access
       coef_if_wr_dat_i : in  std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0) := (others => '0'); -- coef to write
       coef_if_rd_dat_o : out std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);                    -- coef read
       -- Status Output
       busy_o           : out std_logic);                                                              -- calculation on going active high
end entity;
-- @ formatter:on

architecture rtl of psi_fix_fir_dec_ser_nch_chpar_conf is

  constant DataMemDepthApplied_c : natural := 2**log2ceil(max_taps_g);
  constant CoefMemDepthApplied_c : natural := 2**log2ceil(max_taps_g);

  -- Constants
  constant MultFmt_c : psi_fix_fmt_t := (max(in_fmt_g.S, coef_fmt_g.S), in_fmt_g.I + coef_fmt_g.I, in_fmt_g.F + coef_fmt_g.F);
  constant AccuFmt_c : psi_fix_fmt_t := (1, out_fmt_g.I + 1, in_fmt_g.F + coef_fmt_g.F);
  constant RndFmt_c  : psi_fix_fmt_t := (1, out_fmt_g.I + 1, out_fmt_g.F);

  -- types
  type InData_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  type InData_a is array (natural range <>) of InData_t;
  type Mult_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  type Accu_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(AccuFmt_c) - 1 downto 0);
  type Rnd_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(RndFmt_c) - 1 downto 0);
  type Out_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);

  -- Two process method
  type two_process_r is record
    Vld            : std_logic_vector(0 to 1);
    InSig          : InData_a(0 to 1);
    TapWrAddr_1    : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    Tap0Addr_1     : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    DecCnt_1       : std_logic_vector(log2ceil(max_ratio_g) - 1 downto 0);
    TapCnt_1       : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    TapRdAddr_2    : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    CoefRdAddr_2   : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    CalcOn         : std_logic_vector(1 to 6);
    Last           : std_logic_vector(1 to 6);
    First          : std_logic_vector(1 to 5);
    MultInTap_4    : InData_t;
    MultInCoef_4   : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
    MultOut_5      : Mult_t;
    Accu_6         : Accu_t;
    Rnd_7          : Rnd_t;
    RndVld_7       : std_logic;
    Output_8       : Out_t;
    OutVld_8       : std_logic;
    FirstTapLoop_3 : std_logic;
    TapRdAddr_3    : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
    ReplaceZero_4  : std_logic;
    -- Status
    CalcOngoing    : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- Component Interface Signals
  signal DataRamDin_1  : std_logic_vector(psi_fix_size(in_fmt_g)*channels_g - 1 downto 0);
  signal DataRamDout_3 : std_logic_vector(psi_fix_size(in_fmt_g)*channels_g - 1 downto 0);
  signal CoefRamDout_3 : std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);

  -- coef ROM
  type CoefRom_t is array (coefs_g'low to coefs_g'high) of std_logic_vector(psi_fix_size(coef_fmt_g) - 1 downto 0);
  signal CoefRom : CoefRom_t;

begin
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
    v.Vld(v.Vld'low + 1 to v.Vld'high)          := r.Vld(r.Vld'low to r.Vld'high - 1);
    v.InSig(v.InSig'low + 1 to v.InSig'high)    := r.InSig(r.InSig'low to r.InSig'high - 1);
    v.CalcOn(v.CalcOn'low + 1 to v.CalcOn'high) := r.CalcOn(r.CalcOn'low to r.CalcOn'high - 1);
    v.Last(v.Last'low + 1 to v.Last'high)       := r.Last(r.Last'low to r.Last'high - 1);
    v.First(v.First'low + 1 to v.First'high)    := r.First(r.First'low to r.First'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.Vld(0) := vld_i;
    for i in 0 to channels_g - 1 loop
      v.InSig(0)(i) := dat_i(psi_fix_size(in_fmt_g) * (i + 1) - 1 downto psi_fix_size(in_fmt_g) * i);
    end loop;

    -- *** Stage 1 ***
    -- Increment tap address after data was written
    if r.Vld(1) = '1' then
      v.TapWrAddr_1 := std_logic_vector(unsigned(r.TapWrAddr_1) + 1);
    end if;

    -- Decimation & Calculation Control
    if unsigned(r.TapCnt_1) /= 0 then
      v.TapCnt_1 := std_logic_vector(unsigned(r.TapCnt_1) - 1);
    else
      v.CalcOn(1) := '0';
    end if;

    if unsigned(r.TapCnt_1) = 1 or unsigned(cfg_taps_i) = 0 then
      v.Last(1) := '1';
    else
      v.Last(1) := '0';
    end if;

    v.First(1) := '0';
    if r.Vld(0) = '1' then
      if (unsigned(r.DecCnt_1) = 0) or (max_ratio_g = 1) then
        v.DecCnt_1   := cfg_ratio_i;
        v.TapCnt_1   := cfg_taps_i;
        v.CalcOn(1)  := '1';
        v.First(1)   := '1';
        v.Tap0Addr_1 := r.TapWrAddr_1;
      else
        v.DecCnt_1 := std_logic_vector(unsigned(r.DecCnt_1) - 1);
      end if;
    end if;

    -- *** Stage 2 ***
    -- Tap read address
    v.TapRdAddr_2  := std_logic_vector(unsigned(r.Tap0Addr_1) - unsigned(r.TapCnt_1));
    v.CoefRdAddr_2 := r.TapCnt_1;

    -- *** Stage 3 ***
    -- Pipelining
    v.TapRdAddr_3 := r.TapRdAddr_2;

    -- *** Stage 4 ***
    -- Multiplier input registering
    for i in 0 to channels_g - 1 loop
      -- Replace taps that are not yet written with zeros for bittrueness
      if r.ReplaceZero_4 = '0' or unsigned(r.TapRdAddr_3) <= unsigned(cfg_ratio_i) then
        v.MultInTap_4(i) := DataRamDout_3(psi_fix_size(in_fmt_g) * (i + 1) - 1 downto psi_fix_size(in_fmt_g) * i);
      else
        v.MultInTap_4(i) := (others => '0');
      end if;
    end loop;
    -- Detect when the Zero-replacement can be stopped since the taps are already filled with correct data
    if r.FirstTapLoop_3 = '0' then
      v.ReplaceZero_4 := '0';
    elsif r.CalcOn(3) = '1' then
      if r.First(3) = '1' and unsigned(r.TapRdAddr_3) <= unsigned(cfg_ratio_i) then
        v.ReplaceZero_4  := '0';
        v.FirstTapLoop_3 := '0';
      elsif r.Last(3) = '1' then
        v.ReplaceZero_4 := '1';
      elsif unsigned(r.TapRdAddr_3) = 0 then
        v.ReplaceZero_4 := '0';
      end if;
    end if;
    v.MultInCoef_4 := CoefRamDout_3;

    -- *** Stage 5 ***
    -- Multiplication
    for i in 0 to channels_g - 1 loop
      v.MultOut_5(i) := psi_fix_mult(r.MultInTap_4(i), in_fmt_g,
                                   r.MultInCoef_4, coef_fmt_g,
                                   MultFmt_c); -- Full precision, no rounding or saturation required
    end loop;

    -- *** Stage 6 ***
    -- Accumulator
    AccuIn_v := (others => '0');
    for i in 0 to channels_g - 1 loop
      if r.First(5) = '1' then
        AccuIn_v := (others => '0');
      else
        AccuIn_v := r.Accu_6(i);
      end if;
      v.Accu_6(i) := psi_fix_add(r.MultOut_5(i), MultFmt_c,
                               AccuIn_v, AccuFmt_c,
                               AccuFmt_c); -- Overflows compensate at the end of the calculation and rounding not required

    end loop;

    -- *** Stage 7 ***
    -- Rounding
    v.RndVld_7 := '0';
    if r.Last(6) = '1' then
      for i in 0 to channels_g - 1 loop
        v.Rnd_7(i) := psi_fix_resize(r.Accu_6(i), AccuFmt_c, RndFmt_c, rnd_g, psi_fix_wrap);
      end loop;
      v.RndVld_7 := r.CalcOn(6);
    end if;

    -- *** Stage 8 ***
    -- Output Handling and saturation
    v.OutVld_8 := r.RndVld_7;
    for i in 0 to channels_g - 1 loop
      v.Output_8(i) := psi_fix_resize(r.Rnd_7(i), RndFmt_c, out_fmt_g, psi_fix_trunc, sat_g);
    end loop;

    -- *** Status Output ***
    if (unsigned(r.Vld) /= 0) or (unsigned(r.CalcOn) /= 0) or (r.RndVld_7 = '1') then
      v.CalcOngoing := '1';
    else
      v.CalcOngoing := '0';
    end if;

    -- *** Outputs ***
    vld_o  <= r.OutVld_8;
    for i in 0 to channels_g - 1 loop
      dat_o(psi_fix_size(out_fmt_g) * (i + 1) - 1 downto psi_fix_size(out_fmt_g) * i) <= r.Output_8(i);
    end loop;
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
        r.TapWrAddr_1    <= (others => '0');
        r.DecCnt_1       <= (others => '0');
        r.CalcOn         <= (others => '0');
        r.RndVld_7       <= '0';
        r.OutVld_8       <= '0';
        r.Last           <= (others => '0');
        r.ReplaceZero_4  <= '1';
        r.CalcOngoing    <= '0';
        r.FirstTapLoop_3 <= '1';
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
    g_CoefTable : for i in CoefRom'low to CoefRom'high generate
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

  g_data_in : for i in 0 to channels_g - 1 generate
    DataRamDin_1(psi_fix_size(in_fmt_g) * (i + 1) - 1 downto psi_fix_size(in_fmt_g) * i) <= r.InSig(1)(i);
  end generate;

  i_data_ram : entity work.psi_common_tdp_ram
    generic map(
      depth_g    => DataMemDepthApplied_c,
      width_g    => psi_fix_size(in_fmt_g) * channels_g,
      behavior_g => ram_behavior_g
    )
    port map(
      ClkA  => clk_i,
      AddrA => r.TapWrAddr_1,
      WrA   => r.Vld(1),
      DinA  => DataRamDin_1,
      DoutA => open,
      ClkB  => clk_i,
      AddrB => r.TapRdAddr_2,
      WrB   => '0',
      DinB  => (others => '0'),
      DoutB => DataRamDout_3
    );

end architecture;
