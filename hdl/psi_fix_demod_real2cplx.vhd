------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity is a simple demodulator with real input and complex output. It
-- demodulates the signal and filters the results with a comb-filter of length
-- 1/Fcarrier (zeros at Fcarrier where DC ends up and Fcarrier*2 where the
-- demodulation alias occurs).
-- The demodulator only works well for very narrowband signals with very little
-- out of band noise. The signal frequency must be an integer multiple of the 
-- sample frequency.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

-- $$ processes=stim,check $$
entity psi_fix_demod_real2cplx is
  generic(
    RstPol_g   : std_logic := '1';      -- $$ constant = '1' $$
    InFmt_g    : PsiFixFmt_t;           -- $$ constant=(1,0,15) $$
    OutFmt_g   : PsiFixFmt_t;           -- $$ constant=(1,0,16) $$
    CoefBits_g : positive  := 18;       -- $$ constant=25 $$
    Channels_g : natural   := 1;        -- $$ constant=2 $$
    Ratio_g    : natural   := 5         -- $$ constant=5 $$
  );
  port(
    clk_i        : in  std_logic;       -- $$ type=clk; freq=100e6 $$
    rst_i        : in  std_logic;       -- $$ type=rst; clk=clk_i $$
    str_i        : in  std_logic;
    data_i       : in  std_logic_vector(PsiFixSize(InFmt_g)*Channels_g - 1 downto 0);
    phi_offset_i : in  std_logic_vector(log2ceil(Ratio_g)-1 downto 0);
    --
    data_I_o     : out std_logic_vector(PsiFixSize(OutFmt_g) * Channels_g - 1 downto 0);
    data_Q_o     : out std_logic_vector(PsiFixSize(OutFmt_g) * Channels_g - 1 downto 0);
    str_o        : out std_logic
  );
end entity;

architecture RTL of psi_fix_demod_real2cplx is

  constant coefUnusedBits_c : integer     := log2(Ratio_g);
  constant CoefFmt_c        : PsiFixFmt_t := (1, 0-coefUnusedBits_c, CoefBits_g + coefUnusedBits_c-1);
  constant MultFmt_c        : PsiFixFmt_t := (1, InFmt_g.I + CoefFmt_c.I, OutFmt_g.F+log2ceil(Ratio_g)+2); -- truncation error does only lead to 1/4 LSB error on output
  constant coef_scale_c     : real        := (1.0-2.0**(-real(CoefFmt_c.F)))/real(Ratio_g); -- prevent +/- 1.0 and pre-compensate for gain of moving average

  type coef_array_t is array (0 to Ratio_g - 1) of std_logic_vector(PsiFixSize(CoefFmt_c) - 1 downto 0);

  --SIN coef function <=> Q coef n = (sin(nx2pi/Ratio)(2/Ratio))
  function coef_sin_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to Ratio_g - 1 loop
      array_v(i) := PsiFixFromReal(sin(2.0 * MATH_PI * real(i) / real(Ratio_g)) * coef_scale_c, CoefFmt_c);
    end loop;
    return array_v;
  end function;

  --COS coef function <=> Q coef n = (cos(nx2pi/Ratio)(2/Ratio))
  function coef_cos_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to Ratio_g - 1 loop
      array_v(i) := PsiFixFromReal(cos(2.0 * MATH_PI * real(i) / real(Ratio_g)) * coef_scale_c, CoefFmt_c);
    end loop;
    return array_v;
  end function;

  -- I coef n = (sin(nx2pi/5)(2/5))
  constant nonIQ_table_sin : coef_array_t := coef_sin_array_func;
  -- Q coef n = (cos(nx2pi/5)(2/5))
  constant nonIQ_table_cos : coef_array_t := coef_cos_array_func;
  --xilinx constraint
  attribute rom_style      : string;
  attribute rom_style of nonIQ_table_sin, nonIQ_table_cos : constant is "distributed";

  type MultArray_t is array (0 to Channels_g - 1) of std_logic_vector(PsiFixSize(MultFmt_c) - 1 downto 0);
  type InArray_t is array (0 to Channels_g - 1) of std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
  type OutArray_t is array (0 to Channels_g - 1) of std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
  --
  signal cptInt        : integer range 0 to Ratio_g - 1 := 0;
  signal cpt_s         : integer range 0 to Ratio_g - 1 := 0;
  signal mult_i_s      : MultArray_t;
  signal mult_q_s      : MultArray_t;
  --
  signal mult_i_dff_s  : MultArray_t;
  signal mult_q_dff_s  : MultArray_t;
  signal mult_i_dff2_s : MultArray_t;
  signal mult_q_dff2_s : MultArray_t;
  signal coef_i_s      : std_logic_vector(PsiFixSize(CoefFmt_c) - 1 downto 0);
  signal coef_q_s      : std_logic_vector(PsiFixSize(CoefFmt_c) - 1 downto 0);
  signal data_s        : InArray_t;
  signal data_dff_s    : InArray_t;
  signal out_q_s       : OutArray_t;
  signal out_i_s       : OutArray_t;
  signal strIn         : std_logic_vector(0 to 4);
  signal RstPos        : std_logic;
  signal out_str_s     : std_logic_vector(0 to Channels_g - 1);

begin

  RstPos <= '1' when rst_i = RstPol_g else '0';

  --===========================================================================
  -- 		LIMIT the phase offset to max value and check value change
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RstPol_g then
        data_s     <= (others => (others => '0'));
        data_dff_s <= (others => (others => '0'));
        strIn      <= (others => '0');
      else
        strIn(0)               <= str_i;
        strIn(1 to strIn'high) <= strIn(0 to strIn'high - 1);
        -- Channel Splitting
        for i in 0 to Channels_g - 1 loop
          data_s(i) <= data_i((i + 1) * PsiFixSize(InFmt_g) - 1 downto i * PsiFixSize(InFmt_g));
        end loop;
        -- Delay
        data_dff_s             <= data_s;
      end if;
    end if;
  end process;

  --===========================================================================
  -- 	 pointer ROM
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RstPol_g then
        cptInt <= 0;
      else
        if str_i = '1' then
          if cptInt = Ratio_g - 1 then
            cptInt <= 0;
          else
            cptInt <= cptInt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk_i)
    variable cptIntOffs : integer range 0 to 2 * Ratio_g - 1 := 0;
  begin
    if rising_edge(clk_i) then
      if rst_i = RstPol_g then
        cpt_s <= 0;
      else
        assert unsigned(phi_offset_i) <= Ratio_g - 1 report "###ERROR###: psi_fix_demod_real2cpls: phi_offset_i must be <= Ratio_g-1" severity error;
        cptIntOffs := cptInt + to_integer(unsigned(phi_offset_i));
        if unsigned(phi_offset_i) > Ratio_g - 1 then
          cpt_s <= cptInt + Ratio_g - 1;
        elsif cptIntOffs > Ratio_g - 1 then
          cpt_s <= cptIntOffs - Ratio_g;
        else
          cpt_s <= cptIntOffs;
        end if;
      end if;
    end if;
  end process;

  --===========================================================================
  -- I PATH
  --===========================================================================
  imult_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RstPol_g then
        mult_i_s      <= (others => (others => '0'));
        mult_i_dff_s  <= (others => (others => '0'));
        mult_i_dff2_s <= (others => (others => '0'));
        coef_i_s      <= (others => '0');
      else
        -- Coef shared for all channels
        coef_i_s <= nonIQ_table_sin(cpt_s);

        -- Processing per channel
        for i in 0 to Channels_g - 1 loop
          mult_i_s(i) <= PsiFixMult(data_dff_s(i), InFmt_g,
                                    coef_i_s, CoefFmt_c,
                                    MultFmt_c, PsiFixTrunc, PsiFixWrap);
        end loop;
        mult_i_dff_s  <= mult_i_s;
        mult_i_dff2_s <= mult_i_dff_s;
      end if;
    end if;
  end process;
  g_mov_avg_i : for i in 0 to Channels_g - 1 generate
    i_mov_avg : entity work.psi_fix_mov_avg
      generic map(
        InFmt_g    => MultFmt_c,
        OutFmt_g   => OutFmt_g,
        Taps_g     => Ratio_g,
        GainCorr_g => "NONE",
        Round_g    => PsiFixRound,
        Sat_g      => PsiFixSat,
        OutRegs_g  => 2
      )
      port map(
        clk_i     => clk_i,
        rst_i     => RstPos,
        vld_i   => strIn(4),
        dat_i  => mult_i_dff2_s(i),
        vld_o  => out_str_s(i),
        dat_o => out_i_s(i)
      );

    data_I_o((i + 1) * PsiFixSize(OutFmt_g) - 1 downto i * PsiFixSize(OutFmt_g)) <= out_i_s(i);
  end generate;
  str_o <= out_str_s(0);

  --===========================================================================
  -- Q PATH
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RstPol_g then
        mult_q_s      <= (others => (others => '0'));
        mult_q_dff_s  <= (others => (others => '0'));
        mult_q_dff2_s <= (others => (others => '0'));
        coef_q_s      <= (others => '0');
      else
        -- Coef shared for all channels
        coef_q_s <= nonIQ_table_cos(cpt_s);

        -- Processing per channel
        for i in 0 to Channels_g - 1 loop
          mult_q_s(i) <= PsiFixMult(data_dff_s(i), InFmt_g,
                                    coef_q_s, CoefFmt_c,
                                    MultFmt_c, PsiFixTrunc, PsiFixWrap);
        end loop;
        mult_q_dff_s  <= mult_q_s;
        mult_q_dff2_s <= mult_q_dff_s;
      end if;
    end if;
  end process;

  g_mov_avg_q : for i in 0 to Channels_g - 1 generate
    i_mov_avg : entity work.psi_fix_mov_avg
      generic map(
        InFmt_g    => MultFmt_c,
        OutFmt_g   => OutFmt_g,
        Taps_g     => Ratio_g,
        GainCorr_g => "NONE",
        Round_g    => PsiFixRound,
        Sat_g      => PsiFixSat,
        OutRegs_g  => 2
      )
      port map(
        clk_i     => clk_i,
        rst_i     => RstPos,
        vld_i   => strIn(4),
        dat_i  => mult_q_dff2_s(i),
        vld_o  => open,
        dat_o => out_q_s(i)
      );

    data_Q_o((i + 1) * PsiFixSize(OutFmt_g) - 1 downto i * PsiFixSize(OutFmt_g)) <= out_q_s(i);
  end generate;

end architecture;
