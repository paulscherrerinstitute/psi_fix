------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Radoslaw Rybaniec
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
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

-- $$ processes=stim,check $$
-- @formatter:off
entity psi_fix_demod_real2cplx is
  generic(
    rst_pol_g   : std_logic := '1';                                                  -- reset polarity active high ='1'    $$ constant = '1' $$
    in_fmt_g    : psi_fix_fmt_t;                                                     -- input format FP                    $$ constant=(1,0,15) $$
    out_fmt_g   : psi_fix_fmt_t;                                                     -- output format FP                   $$ constant=(1,0,16) $$
    coef_bits_g : positive  := 18;                                                   -- internal coefficent number of bits $$ constant=25 $$
    channels_g  : natural   := 1;                                                    -- number of channels TDM             $$ constant=2 $$
    ratio_num_g     : natural   := 5;                                                    -- ratio numerator between clock and IF/RF      $$ constant=5 $$
    ratio_denum_g    : natural   := 1                                                     -- ratio denumerator between clock and IF/RF    $$ constant=1 $$
  );
  port(
    clk_i        : in  std_logic;                                                       -- clk system $$ type=clk; freq=100e6 $$
    rst_i        : in  std_logic;                                                       -- rst system $$ type=rst; clk=clk_i $$
    dat_i        : in  std_logic_vector(psi_fix_size(in_fmt_g)*channels_g - 1 downto 0);-- data input IF/RF
    vld_i        : in  std_logic;                                                       -- valid input freqeuncy sampling
    phi_offset_i : in  std_logic_vector(log2ceil(ratio_num_g)-1 downto 0);                  -- phase offset for demod LUT
    dat_inp_o    : out std_logic_vector(psi_fix_size(out_fmt_g)*channels_g- 1 downto 0);-- inphase data output
    dat_qua_o    : out std_logic_vector(psi_fix_size(out_fmt_g)*channels_g- 1 downto 0);-- quadrature data output
    vld_o        : out std_logic                                                        -- valid output
  );
end entity;
-- @formatter:on
architecture RTL of psi_fix_demod_real2cplx is

  constant coefUnusedBits_c : integer     := log2(ratio_num_g);
  constant CoefFmt_c        : psi_fix_fmt_t := (1, 0-coefUnusedBits_c, coef_bits_g + coefUnusedBits_c-1);
  constant MultFmt_c        : psi_fix_fmt_t := (1, in_fmt_g.I + CoefFmt_c.I, out_fmt_g.F+log2ceil(ratio_num_g)+2); -- truncation error does only lead to 1/4 LSB error on output
  constant coef_scale_c     : real        := (1.0-2.0**(-real(CoefFmt_c.F)))/real(ratio_num_g); -- prevent +/- 1.0 and pre-compensate for gain of moving average

  type coef_array_t is array (0 to ratio_num_g - 1) of std_logic_vector(psi_fix_size(CoefFmt_c) - 1 downto 0);

  --SIN coef function <=> Q coef n = (sin(nx2pi/Ratio)(2/Ratio))
  function coef_sin_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to ratio_num_g - 1 loop
      array_v(i) := psi_fix_from_real(sin(2.0 * MATH_PI * real(i) / real(ratio_num_g)) * coef_scale_c, CoefFmt_c);
    end loop;
    return array_v;
  end function;

  --COS coef function <=> Q coef n = (cos(nx2pi/Ratio)(2/Ratio))
  function coef_cos_array_func return coef_array_t is
    variable array_v : coef_array_t;
  begin
    for i in 0 to ratio_num_g - 1 loop
      array_v(i) := psi_fix_from_real(cos(2.0 * MATH_PI * real(i) / real(ratio_num_g)) * coef_scale_c, CoefFmt_c);
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

  type MultArray_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  type InArray_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  type OutArray_t is array (0 to channels_g - 1) of std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
  --
  signal cptInt        : integer range 0 to ratio_denum_g*ratio_num_g - 1 := 0;
  signal cpt_s         : integer range 0 to ratio_num_g - 1 := 0;
  signal mult_i_s      : MultArray_t;
  signal mult_q_s      : MultArray_t;
  --
  signal mult_i_dff_s  : MultArray_t;
  signal mult_q_dff_s  : MultArray_t;
  signal mult_i_dff2_s : MultArray_t;
  signal mult_q_dff2_s : MultArray_t;
  signal coef_i_s      : std_logic_vector(psi_fix_size(CoefFmt_c) - 1 downto 0);
  signal coef_q_s      : std_logic_vector(psi_fix_size(CoefFmt_c) - 1 downto 0);
  signal data_s        : InArray_t;
  signal data_dff_s    : InArray_t;
  signal out_q_s       : OutArray_t;
  signal out_i_s       : OutArray_t;
  signal strIn         : std_logic_vector(0 to 4);
  signal RstPos        : std_logic;
  signal out_str_s     : std_logic_vector(0 to channels_g - 1);

begin

  RstPos <= '1' when rst_i = rst_pol_g else '0';

  --===========================================================================
  --    LIMIT the phase offset to max value and check value change
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        data_s     <= (others => (others => '0'));
        data_dff_s <= (others => (others => '0'));
        strIn      <= (others => '0');
      else
        strIn(0)               <= vld_i;
        strIn(1 to strIn'high) <= strIn(0 to strIn'high - 1);
        -- Channel Splitting
        for i in 0 to channels_g - 1 loop
          data_s(i) <= dat_i((i + 1) * psi_fix_size(in_fmt_g) - 1 downto i * psi_fix_size(in_fmt_g));
        end loop;
        -- Delay
        data_dff_s             <= data_s;
      end if;
    end if;
  end process;

  --===========================================================================
  --   pointer ROM
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        cptInt <= 0;
      else
        if vld_i = '1' then
          if cptInt < ratio_num_g - ratio_denum_g then
            cptInt <= cptInt + ratio_denum_g;
          else
            cptInt <= ratio_denum_g - (ratio_num_g - cptInt);
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk_i)
    variable cptIntOffs : integer range 0 to 2 * ratio_num_g - 1 := 0;
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        cpt_s <= 0;
      else
        assert unsigned(phi_offset_i) <= ratio_num_g - 1 report "###ERROR###: psi_fix_demod_real2cpls: phi_offset_i must be <= ratio_num_g-1" severity error;
        cptIntOffs := cptInt + to_integer(unsigned(phi_offset_i));
        if cptIntOffs > ratio_num_g - 1 then
          cpt_s <= cptIntOffs - ratio_num_g;
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
      if rst_i = rst_pol_g then
        mult_i_s      <= (others => (others => '0'));
        mult_i_dff_s  <= (others => (others => '0'));
        mult_i_dff2_s <= (others => (others => '0'));
        coef_i_s      <= (others => '0');
      else
        -- Coef shared for all channels
        coef_i_s <= nonIQ_table_sin(cpt_s);

        -- Processing per channel
        for i in 0 to channels_g - 1 loop
          mult_i_s(i) <= psi_fix_mult(data_dff_s(i), in_fmt_g,
                                    coef_i_s, CoefFmt_c,
                                    MultFmt_c, psi_fix_trunc, psi_fix_wrap);
        end loop;
        mult_i_dff_s  <= mult_i_s;
        mult_i_dff2_s <= mult_i_dff_s;
      end if;
    end if;
  end process;
  g_mov_avg_i : for i in 0 to channels_g - 1 generate
     i_mov_avg : entity work.psi_fix_mov_avg
       generic map(
         in_fmt_g    => MultFmt_c,
         out_fmt_g   => out_fmt_g,
         taps_g     => ratio_num_g,
         gain_corr_g => "NONE",
         round_g    => psi_fix_round,
         sat_g      => psi_fix_sat,
         out_regs_g  => 2
       )
       port map(
         clk_i     => clk_i,
         rst_i     => RstPos,
         vld_i   => strIn(4),
         dat_i  => mult_i_dff2_s(i),
         vld_o  => out_str_s(i),
         dat_o => out_i_s(i)
       );

    dat_inp_o((i + 1) * psi_fix_size(out_fmt_g) - 1 downto i * psi_fix_size(out_fmt_g)) <= out_i_s(i);
    -- dat_inp_o((i + 1) * psi_fix_size(out_fmt_g) - 1 downto i * psi_fix_size(out_fmt_g)) <= psi_fix_resize(mult_i_dff2_s(i), MultFmt_c, out_fmt_g);
end generate;
  vld_o <= out_str_s(0);
  --  vld_o <= strIn(4);

  --===========================================================================
  -- Q PATH
  --===========================================================================
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        mult_q_s      <= (others => (others => '0'));
        mult_q_dff_s  <= (others => (others => '0'));
        mult_q_dff2_s <= (others => (others => '0'));
        coef_q_s      <= (others => '0');
      else
        -- Coef shared for all channels
        coef_q_s <= nonIQ_table_cos(cpt_s);

        -- Processing per channel
        for i in 0 to channels_g - 1 loop
          mult_q_s(i) <= psi_fix_mult(data_dff_s(i), in_fmt_g,
                                    coef_q_s, CoefFmt_c,
                                    MultFmt_c, psi_fix_trunc, psi_fix_wrap);
        end loop;
        mult_q_dff_s  <= mult_q_s;
        mult_q_dff2_s <= mult_q_dff_s;
      end if;
    end if;
  end process;

  g_mov_avg_q : for i in 0 to channels_g - 1 generate
     i_mov_avg : entity work.psi_fix_mov_avg
       generic map(
         in_fmt_g    => MultFmt_c,
         out_fmt_g   => out_fmt_g,
         taps_g     => ratio_num_g,
         gain_corr_g => "NONE",
         round_g    => psi_fix_round,
         sat_g      => psi_fix_sat,
         out_regs_g  => 2
       )
       port map(
         clk_i     => clk_i,
         rst_i     => RstPos,
         vld_i   => strIn(4),
         dat_i  => mult_q_dff2_s(i),
         vld_o  => open,
         dat_o => out_q_s(i)
       );

     dat_qua_o((i + 1) * psi_fix_size(out_fmt_g) - 1 downto i * psi_fix_size(out_fmt_g)) <= out_q_s(i);
    --  dat_qua_o((i + 1) * psi_fix_size(out_fmt_g) - 1 downto i * psi_fix_size(out_fmt_g)) <= psi_fix_resize(mult_q_dff2_s(i), MultFmt_c, out_fmt_g);
  end generate;

end architecture;
