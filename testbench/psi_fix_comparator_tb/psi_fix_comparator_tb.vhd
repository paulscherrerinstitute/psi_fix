------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
--This basic block allows set min and max threshold in fixed point format fashion
--prior to deliver flag indications output - TESTBENCH

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_fix_pkg.all;

entity psi_fix_comparator_tb is
  generic(fmt_g : psi_fix_fmt_t := (1, 0, 15));
end entity;

architecture tb of psi_fix_comparator_tb is
  constant freq_clk_g  : real                                             := 100.0E6;
  constant period_c    : time                                             := (1 sec) / freq_clk_g;
  signal clk_sti       : std_logic                                        := '0';
  signal rst_sti       : std_logic                                        := '1';
  signal tb_run        : boolean                                          := true;
  signal set_min_sti   : std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0) := (others => '0');
  signal set_max_sti   : std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0) := (others => '0');
  signal data_sti      : std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0) := (others => '0');
  signal str_sti       : std_logic                                        := '0';
  signal str_obs       : std_logic;
  signal min_obs       : std_logic;
  signal max_obs       : std_logic;
  --helpers
  signal set_min_dly_s : std_logic_vector(set_min_sti'range)              := (others => '0');
  signal set_max_dly_s : std_logic_vector(set_max_sti'range)              := (others => '0');
  signal data_dly_s    : std_logic_vector(data_sti'range)                 := (others => '0');
begin
  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  --*** clock process ***
  proc_clk : process
    variable tStop_v : time;
  begin
    while tb_run or (now < tStop_v + 1 us) loop
      if tb_run then
        tStop_v := now;
      end if;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  --*** DUT***
  inst_dut : entity work.psi_fix_comparator
    generic map(fmt_g     => fmt_g,
                rst_pol_g => '1')
    port map(clk_i     => clk_sti,
             rst_i     => rst_sti,
             set_min_i => set_min_sti,
             set_max_i => set_max_sti,
             data_i    => data_sti,
             vld_i     => str_sti,
             vld_o     => str_obs,
             min_o     => min_obs,
             max_o     => max_obs
            );

  data_dly_s <= transport data_sti after 3 * period_c;

  process(clk_sti)
  begin
    if falling_edge(clk_sti) then
      if str_obs = '1' and max_obs = '1' then
        assert max_obs = '1' and psi_fix_compare("a<b", set_max_sti, fmt_g, data_dly_s, fmt_g) report "###ERROR### max didn't not rise but thld < data" severity error;
      end if;
      if str_obs = '1' and max_obs = '0' then
        assert max_obs = '0' and psi_fix_compare("a>b", set_max_sti, fmt_g, data_dly_s, fmt_g) report "###ERROR### max rose but thld < data" severity error;
      end if;
      if str_obs = '1' and min_obs = '1' then
        assert min_obs = '1' and psi_fix_compare("a>b", set_min_sti, fmt_g, data_dly_s, fmt_g) report "###ERROR### min didn't not rise but thld > data" severity error;
      end if;
      if str_obs = '1' and min_obs = '0' then
        assert min_obs = '0' and psi_fix_compare("a<b", set_min_sti, fmt_g, data_dly_s, fmt_g) report "###ERROR2### min rose but thld > data" severity error;
      end if;
    end if;
  end process;

  --*** stim process ***
  proc_stim : process
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **       Paul Scherrer Institut                **  ");
    print(" **    psi_fix_comparator_tb TestBench          **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    wait for period_c;
    data_sti    <= (others => '0');
    str_sti     <= '1';
    set_min_sti <= psi_fix_from_real(-0.5, fmt_g);
    set_max_sti <= psi_fix_from_real(0.5, fmt_g);
    wait until rising_edge(clk_sti);
    for i in 0 to 99 loop
      data_sti <= psi_fix_add(data_sti, fmt_g, psi_fix_from_real(0.01, fmt_g), fmt_g, fmt_g, psi_fix_trunc, psi_fix_sat);
      wait until rising_edge(clk_sti);
    end loop;

    wait until rising_edge(clk_sti);
    for i in 0 to 9999 loop
      data_sti <= psi_fix_sub(data_sti, fmt_g, psi_fix_from_real(0.0002, fmt_g), fmt_g, fmt_g, psi_fix_trunc, psi_fix_sat);
      wait until rising_edge(clk_sti);
    end loop;

    tb_run <= false;
    wait;

  end process;

end architecture;
