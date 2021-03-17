------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This block allows generating trigger out of sevral input signals with fixed 
-- point format, parameter here are mapped in tdm fashion to reduce resources usage
-- and not parallelize comparator, care must be taken on strobe input number of channel 
-- and clock frequency

------------------------------------------------------------------------------
-- PKG HDL file for type definition
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_activity_pkg.all;
use work.psi_fix_pkg.all;
use work.psi_fix_nch_analog_trigger_tdm_pkg.all;

entity psi_fix_nch_analog_trigger_tdm_tb is
  generic(ch_nb_g : natural range 2 to 10 := 8); -- number of channel for tb if one want to increase this value the ratio between clock must be adapted
end entity;

architecture tb of psi_fix_nch_analog_trigger_tdm_tb is
  constant freq_clk_g  : real                                                              := 100.0E6; -- clock frequency arbitrary chosen
  constant ratio_g     : real                                                              := 10.0; -- ratio between clock and data strobe
  --internal signals
  constant bit_c       : integer                                                           := PsiFixSize(SIGNAL_FMT_c);
  constant period_c    : time                                                              := (1 sec) / freq_clk_g;
  signal clk_sti       : std_logic                                                         := '0';
  signal rst_sti       : std_logic                                                         := '1';
  signal str_s         : std_logic                                                         := '0';
  signal dat_sti       : std_logic_vector(PsiFixSize(SIGNAL_FMT_c) - 1 downto 0)           := (others => '0');
  signal str_sti       : std_logic                                                         := '0';
  signal param_sti     : param_t                                                           := param_rst_c;
  signal ext_sti       : std_logic                                                         := '0';
  signal counter_s     : unsigned(bit_c - 1 downto 0)                                      := (others => '0');
  signal str_pipe_obs  : std_logic;
  signal dat_pipe_obs  : std_logic_vector(bit_c - 1 downto 0);
  signal trig_obs      : std_logic;
  signal is_arm_obs    : std_logic;
  -- TB stop
  signal tb_run_s      : boolean                                                           := true;
  --helpers
  type usign_array_t is array (0 to ch_nb_g - 1) of unsigned(2 * bit_c - 1 downto 0);
  signal count_array_s : usign_array_t;
  type stimuli_array_t is array (0 to ch_nb_g - 1) of std_logic_vector(bit_c - 1 downto 0);
  signal data_array_s  : stimuli_array_t;
  signal check_array_s : stimuli_array_t;
  signal data_in_s     : std_logic_vector(ch_nb_g * PsiFixSize(SIGNAL_FMT_c) - 1 downto 0) := (others => '0');
  signal str_dff_s     : std_logic                                                         := '0';
  signal idx_s         : integer                                                           := 0;
  ------------------------------------------------------------------------------------------------------------
  --*** resolutiuon function array to TDM ***
  function array_2_slv(signal data_i      : in stimuli_array_t;
                       constant ch_number : natural) return std_logic_vector is
    constant width_c : natural := PsiFixSize(SIGNAL_FMT_c);
    variable data_v  : std_logic_vector(ch_number * width_c - 1 downto 0);
  begin
    for i in 0 to ch_number - 1 loop
      data_v((i + 1) * width_c - 1 downto i * width_c) := data_i(i);
    end loop;
    return data_v;
  end function;
  -------------------------------------------------------------------------------------------------------------
begin

  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 10 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  --*** clock process ***
  proc_clk : process
    variable tStop_v : time;
  begin
    while tb_run_s or (now < tStop_v + 1 us) loop
      if tb_run_s then
        tStop_v := now;
      end if;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  --*** DUT ***
  inst_dut : entity work.psi_fix_nch_analog_trigger_tdm
    generic map(latency_g => 10,        --obvisouly with the number channel this has to be modified
                ch_nb_g   => ch_nb_g,
                fix_fmt_g => SIGNAL_FMT_c)
    port map(clk_i      => clk_sti,
             rst_i      => rst_sti,
             dat_i      => dat_sti,
             str_i      => str_sti,
             ext_i      => ext_sti,
             param_i    => param_sti,
             dat_pipe_o => dat_pipe_obs,
             str_pipe_o => str_pipe_obs,
             trig_o     => trig_obs,
             is_arm_o   => is_arm_obs);

  --*** TAG emulation formatting input stimuli ***
  proc_strob : process
  begin
    while tb_run_s loop
      GenerateStrobe(freq_clk_g, freq_clk_g / ratio_g, '1', rst_sti, clk_sti, str_s);
    end loop;
    wait;
  end process;

  --*** TAG generate ramp with different delta ***
  proc_generate_stim : process(clk_sti, rst_sti)
  begin
    if rst_sti = '1' then
      counter_s <= (others => '0');
      str_dff_s <= '0';
    elsif rising_edge(clk_sti) then
      str_dff_s <= str_s;

      if str_s = '1' then
        for i in 0 to ch_nb_g - 1 loop
          counter_s        <= counter_s + 1;
          count_array_s(i) <= counter_s * (to_unsigned(10 * i + 1, 16));
          data_array_s(i)  <= std_logic_vector(count_array_s(i)(15 downto 0));
        end loop;
      end if;
      data_in_s <= array_2_slv(data_array_s, ch_nb_g);
    end if;
  end process;

  --*** TAG par 2 tdm block INP ***
  inst_par2tdm_inp : entity work.psi_common_par_tdm
    generic map(ChannelCount_g => ch_nb_g,
                ChannelWidth_g => PsiFixSize(SIGNAL_FMT_c))
    port map(Clk         => clk_sti,
             Rst         => rst_sti,
             Parallel    => data_in_s,
             ParallelVld => str_dff_s,
             Tdm         => dat_sti,
             TdmVld      => str_sti);

  proc_deserializer : process(clk_sti)
  begin
    if rising_edge(clk_sti) then
      if rst_sti = '1' then
        for i in 0 to ch_nb_g - 1 loop
          check_array_s(i) <= (others => '0');
        end loop;
      end if;

      if str_pipe_obs = '1' then
        if idx_s = ch_nb_g - 1 then
          idx_s <= 0;
        else
          idx_s <= idx_s + 1;
        end if;
        check_array_s(idx_s) <= dat_pipe_obs;
      else
        idx_s <= 0;
      end if;
      --check position of trigger within the TDM vector flow
      if trig_obs = '1' then
        --print(to_string(idx_s));
        assert idx_s = ch_nb_g - 1 report ("***ERROR***: delay set is no at the last sample of tdm vector");
      end if;
    end if;
  end process;

  --*** TAG stim process ***
  proc_stim : process
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **        Paul Scherrer Institut               **  ");
    print(" ** psi_fix_nch_analog_trigger_tdm_tb TestBench **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    wait for period_c;
    param_sti.trig.TrgMode(0) <= '1';
    param_sti.trig.TrgArm     <= '1';
    --*** init arrays ***
    for i in 0 to ch_nb_g - 1 loop
      param_sti.thld(i)(bit_c - 1 downto 0)         <= to_uslv(100, bit_c);
      param_sti.thld(i)(2 * bit_c - 1 downto bit_c) <= to_uslv(5000, bit_c);
    end loop;
    wait for 100 * period_c;
    param_sti.mask_min_ena(0) <= '1';   --only activ min for ch   
    wait until trig_obs = '1';
    print("[INFO]: Check channel 0 trigger Min");
    assert check_array_s(0) < to_uslv(100, bit_c) report "***ERROR***: Ch 0 has min Thld 100 trig occurs but data is above thld min" severity error;
    wait for 100 * period_c;
    print("[INFO]: Check if trigger is dearmed");
    assert is_arm_obs = '0' report "***ERROR***: trigger is not dearmed but raised" severity error;
    param_sti.trig.TrgArm     <= '0';
    param_sti.mask_min_ena(0) <= '0';   --dactiv min for ch
    wait for 10 * period_c;
    param_sti.trig.TrgArm     <= '1';   --rearm
    wait for 100 * period_c;
    param_sti.mask_max_ena(0) <= '1';   --activ max for ch 0
    wait until trig_obs = '1';
    print("[INFO]: Check channel 0 trigger Max");
    assert check_array_s(0) > to_uslv(5000, bit_c) report "***ERROR***: Ch 0 has max Thld 5000 trig occurs but data is under thld min" severity error;
    wait for 100 * period_c;
    param_sti.mask_min_ena(0) <= '0';   --deactiv min for ch 
    param_sti.mask_max_ena(0) <= '0';   --deactiv max for ch 0
    wait for 100 * period_c;
    param_sti.trig.TrgArm     <= '0';
    wait for 10 * period_c;
    param_sti.trig.TrgArm     <= '1';   --rearm trigger
    param_sti.mask_min_ena(3) <= '1';   --active min ch3
    wait until trig_obs = '1';
    print("[INFO]: Check channel 3 trigger Min");
    assert from_sslv(check_array_s(3)) < 100 report "***ERROR***: Ch 3 has min Thld 100 trig occurs but data is above thld min" severity error;
    wait for 100 * period_c;
    ------------------------------------------------------------
    print("[INFO]: Test externa signal align");
    param_sti.mask_min_ena    <= (others => '0'); --deactiv min for ch 
    param_sti.mask_max_ena    <= (others => '0'); --deactiv max for ch 0
    param_sti.trig.TrgArm     <= '0';
    wait for 10 * period_c;
    param_sti.trig.TrgArm     <= '1';
    wait until str_sti = '0';
    PulseSig(ext_sti, clk_sti);
    wait until trig_obs = '1';
    wait for 50 * period_c;
    param_sti.clr_ext_trig    <= '1';   -- clear external
    param_sti.trig.TrgArm     <= '0';   -- dearm
    wait for 20 * period_c;
    param_sti.trig.TrgArm     <= '1';
    wait until idx_s = 5;

    tb_run_s <= false;
    wait;
  end process;

end architecture;
