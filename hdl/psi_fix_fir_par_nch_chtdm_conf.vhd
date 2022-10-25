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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

-- $$ processes=stim, resp $$
entity psi_fix_fir_par_nch_chtdm_conf is
  generic(
    InFmt_g       : psi_fix_fmt_t := (1, 0, 17);  -- input format FP      $$ constant=(1,0,15) $$
    OutFmt_g      : psi_fix_fmt_t := (1, 0, 17);  -- output format FP     $$ constant=(1,2,13) $$
    CoefFmt_g     : psi_fix_fmt_t := (1, 0, 17);  -- coeffcient format FP $$ constant=(1,0,17) $$
    Channels_g    : natural     := 1;             -- number of channel    $$ export=true $$
    Taps_g        : natural     := 48;            -- Taps number          $$ export=true $$
    Rnd_g         : psi_fix_rnd_t := PsiFixRound; -- round or trunc
    Sat_g         : psi_fix_sat_t := PsiFixSat;   -- sat or wrap
    UseFixCoefs_g : boolean     := true;          -- use fixed coef or updated from table
    Coefs_g       : t_areal     := (0.0, 0.0)     -- see doc
  );
  port(
    clk_i             : in  std_logic;                                                                -- system clock $$ type=clk; freq=100e6 $$
    rst_i             : in  std_logic;                                                                -- system reset $$ type=rst; clk=Clk $$
    dat_i             : in  std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);                       -- data input FP
    vld_i             : in  std_logic;                                                                -- valid input frequency sampling 
    dat_o             : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);                      -- data output 
    vld_o             : out std_logic;                                                                -- valid output frequency sampling
    -- Coefficient interface
    coef_if_wr_i      : in  std_logic                                            := '0';              -- write enable
    coef_if_wr_addr_i : in  std_logic_vector(log2ceil(Taps_g) - 1 downto 0)      := (others => '0');  -- write address
    coef_if_wr_dat_i  : in  std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0) := (others => '0')   -- coef to write
  );
end entity;

architecture rtl of psi_fix_fir_par_nch_chtdm_conf is

  -- DSP Slice Chain
  constant AccuFmt_c   : psi_fix_fmt_t                  := (1, OutFmt_g.I + 1, InFmt_g.F + CoefFmt_g.F);
  constant RoundFmt_c  : psi_fix_fmt_t                  := (1, AccuFmt_c.I + 1, OutFmt_g.F);
  type AccuChain_a is array (natural range <>) of std_logic_vector(PsiFixSize(AccuFmt_c) - 1 downto 0);
  type InData_a is array (natural range <>) of std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
  signal DspDataChainI : InData_a(0 to Taps_g - 1);
  signal DspDataChainO : InData_a(0 to Taps_g - 1);
  signal DspAccuChain  : AccuChain_a(0 to Taps_g - 1) := (others => (others => '0'));
  signal DspVldChain   : std_logic_vector(1 to Taps_g);
  signal OutVldChain   : std_logic_vector(0 to Taps_g);
  signal OutRound      : std_logic_vector(PsiFixSize(RoundFmt_c) - 1 downto 0);
  signal OutRoundVld   : std_logic;
  type Coef_a is array (natural range <>) of std_logic_vector(PsiFixSize(CoefFmt_g) - 1 downto 0);
  signal CoefReg       : Coef_a(0 to Taps_g - 1);
  signal CoefWe        : std_logic_vector(0 to Taps_g - 1);
  signal CoefRstDone   : std_logic                    := '0';

begin
  --------------------------------------------------------------------------
  -- General Control Logic
  --------------------------------------------------------------------------
  p_logic : process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- Valid chain
      DspVldChain(1 to DspVldChain'high) <= vld_i & DspVldChain(1 to DspVldChain'high - 1);
      -- Coefficient handling (writable or fixed)
      CoefWe                             <= (others => '0');
      if not UseFixCoefs_g then
        CoefReg <= (others => coef_if_wr_dat_i);
        if coef_if_wr_i = '1' and unsigned(coef_if_wr_addr_i) < Taps_g then
          CoefWe(to_integer(unsigned(coef_if_wr_addr_i))) <= '1';
        end if;
      end if;
      -- Reset
      if rst_i = '1' then
        -- Make sure coefficients are initialized
        if CoefRstDone = '0' then
          CoefWe <= (others => '1');
          for i in 0 to Taps_g - 1 loop
            CoefReg(i) <= PsiFixFromReal(Coefs_g(i), CoefFmt_g);
          end loop;
        end if;

        -- Reset values
        DspVldChain <= (others => '0');
      else
        CoefRstDone <= '1';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- DSP Slice Chain
  --------------------------------------------------------------------------
  -- First DSP slice (connected differently)
  i_slice0 : entity work.psi_fix_mult_add_stage
    generic map(
      InAFmt_g    => InFmt_g,
      InBFmt_g    => CoefFmt_g,
      AddFmt_g    => AccuFmt_c,
      InBIsCoef_g => true
    )
    port map(
      clk_i            => clk_i,
      rst_i            => rst_i,
      vld_a_i         => vld_i,
      dat_a_i            => dat_i,
      del2_a_o        => DspDataChainI(0),
      vld_b_i         => CoefWe(0),
      dat_b_i            => CoefReg(0),
      chain_add_i     => (others => '0'),
      chain_add_o    => DspAccuChain(0),
      chain_add_vld_o => OutVldChain(0)
    );

  -- Delays (the same for all taps)
  g_delay : for i in 0 to Taps_g - 1 generate
    -- No delay is required for the signle channel implementation
    g_1ch : if Channels_g = 1 generate
      DspDataChainO(i) <= DspDataChainI(i);
    end generate;

    -- For the multi-channel implementation, adda shift-register based delay
    g_nch : if Channels_g /= 1 generate
      i_delay : entity work.psi_common_delay
        generic map(
          Width_g => PsiFixSize(InFmt_g),
          Delay_g => Channels_g - 1
        )
        port map(
          Clk     => clk_i,
          Rst     => rst_i,
          InData  => DspDataChainI(i),
          InVld   => DspVldChain(i + 1),
          OutData => DspDataChainO(i)
        );
    end generate;
  end generate;

  -- All DSP slices except the first one
  g_slices : for i in 1 to Taps_g - 1 generate
    i_slice : entity work.psi_fix_mult_add_stage
      generic map(
        InAFmt_g    => InFmt_g,
        InBFmt_g    => CoefFmt_g,
        AddFmt_g    => AccuFmt_c,
        InBIsCoef_g => true
      )
      port map(
        clk_i            => clk_i,
        rst_i            => rst_i,
        vld_a_i         => DspVldChain(i),
        dat_a_i            => DspDataChainO(i - 1),
        del2_a_o        => DspDataChainI(i),
        dat_b_i            => CoefReg(i),
        vld_b_i         => CoefWe(i),
        chain_add_i     => DspAccuChain(i - 1),
        chain_add_o    => DspAccuChain(i),
        chain_add_vld_o => OutVldChain(i)
      );

  end generate;

  --------------------------------------------------------------------------
  -- Output Rounding and Saturation
  --------------------------------------------------------------------------
  p_output : process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- Round
      OutRoundVld <= OutVldChain(Taps_g - 1);
      OutRound    <= PsiFixResize(DspAccuChain(Taps_g - 1), AccuFmt_c, RoundFmt_c, Rnd_g, PsiFixWrap);

      -- Saturate
      vld_o <= OutRoundVld;
      dat_o <= PsiFixResize(OutRound, RoundFmt_c, OutFmt_g, PsiFixTrunc, Sat_g);

      -- Reset
      if rst_i = '1' then
        OutRoundVld <= '0';
        vld_o       <= '0';
      end if;
    end if;
  end process;

end architecture;

