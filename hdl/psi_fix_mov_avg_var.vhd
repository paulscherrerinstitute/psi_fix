------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Waldemar Koprek
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- The sliding average can average signal with number of taps changed in runtime
-- from 0 to max_taps_g-1
--
-- The gain has to be provided before or together with number of taps 
-- in order to avoid inconsistent data.
-- 
-- The gain correction is always a positive
-- number 1/N scaled in user app to fix point of type (0,0,size_of(dat_i))
--
-- The averager works both for unsigned and signed data  
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

-- $$ processes=stim,check $$
entity psi_fix_mov_avg_var is
  generic(
    in_fmt_g   : psi_fix_fmt_t;         -- input format   $$ constant=(1,0,10) $$
    max_taps_g : positive               -- maximum number of Taps $$ constant=7 $$
  );
  port(
    -- Control Signals
    clk_i  : in  std_logic;             -- system clock $$ type=clk; freq=100e6 $$
    rst_i  : in  std_logic;             -- system reset $$ type=rst; clk=clk_i $$
    taps_i : in  std_logic_vector(log2ceil(max_taps_g) - 1 downto 0); -- N - number of actual taps
    gain_i : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- 1/N - gain correction
    dat_i  : in  std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data input
    vld_i  : in  std_logic;             -- valid input sampling frequency
    dat_o  : out std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data output
    vld_o  : out std_logic              -- valid output sampling frequency
  );
end entity;

architecture rtl of psi_fix_mov_avg_var is
  -- Constants
  constant AdditionalBits_c : integer       := log2ceil(max_taps_g);
  constant GainFmt_c        : psi_fix_fmt_t := (0, 0, psi_fix_size(in_fmt_g));
  constant AccFmt_c         : psi_fix_fmt_t := (in_fmt_g.s, in_fmt_g.i + AdditionalBits_c, in_fmt_g.f);
  constant MultFmt_c        : psi_fix_fmt_t := (in_fmt_g.s, AccFmt_c.i + GainFmt_c.I, AccFmt_c.f + GainFmt_c.f);
  -- Signals
  signal taps_s             : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
  signal aver_rst_pipe      : std_logic_vector(31 downto 0);
  signal aver_rst           : std_logic;
  signal fifo_wr            : std_logic;
  signal fifo_rd            : std_logic;
  signal aver_ena           : std_logic;
  signal fifo_vld           : std_logic;
  signal vld_s              : std_logic_vector(4 downto 0);
  signal taps_cnt           : std_logic_vector(log2ceil(max_taps_g) - 1 downto 0);
  signal aver_acc           : std_logic_vector(psi_fix_size(AccFmt_c) - 1 downto 0);
  signal fifo_out           : std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0);
  signal aver_mult          : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  signal gain_s             : std_logic_vector(psi_fix_size(GainFmt_c) - 1 downto 0);
  signal dat_s              : std_logic_vector(psi_fix_size(in_fmt_g) - 1 downto 0); -- data input

begin

  -- The process monitors changed parameter taps_i
  -- If the value has changed the averager is reset
  -- The parameter gain_i has to be updated not later than taps_i
  p_aver_control : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        aver_rst_pipe <= (others => '1');
        taps_s        <= (others => '0');
        aver_ena      <= '0';
        gain_s        <= gain_i;
        taps_cnt      <= (others => '0');
      else
        if taps_s /= taps_i then        -- new taps size
          taps_s        <= taps_i;
          gain_s        <= gain_i;
          aver_rst_pipe <= (others => '1');
          aver_ena      <= '0';
          taps_cnt      <= std_logic_vector(to_unsigned(0, taps_cnt'length));
        else
          aver_rst_pipe <= aver_rst_pipe(aver_rst_pipe'left - 1 downto 0) & '0';
          if aver_rst = '0' and vld_i = '1' then
            if taps_cnt = taps_s then
              aver_ena <= '1';
            else
              taps_cnt <= std_logic_vector(unsigned(taps_cnt) + X"1");
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  aver_rst <= aver_rst_pipe(aver_rst_pipe'left);

  -- 
  p_average : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if aver_rst = '1' then
        aver_acc  <= (others => '0');
        aver_mult <= (others => '0');
        vld_s     <= (others => '0');
        dat_s     <= (others => '0');
        dat_o     <= (others => '0');
        vld_o     <= '0';
      else
        if vld_i = '1' then
          dat_s <= dat_i;
        end if;
        -- strobe shift
        vld_s <= vld_s(vld_s'left - 1 downto 0) & vld_i;
        -- substract the oldest sample
        if vld_i = '1' and aver_ena = '1' then
          if fifo_vld = '1' then
            aver_acc <= psi_fix_sub(aver_acc, AccFmt_c, fifo_out, in_fmt_g, AccFmt_c, psi_fix_trunc, psi_fix_wrap);
            fifo_rd  <= '1';
          end if;
        else
          fifo_rd <= '0';
        end if;
        -- add new sample
        if vld_s(2) = '1' then
          aver_acc <= psi_fix_add(aver_acc, AccFmt_c, dat_s, in_fmt_g, AccFmt_c, psi_fix_trunc, psi_fix_wrap);
        end if;
        -- gain correction
        if vld_s(3) = '1' and aver_ena = '1' then
          aver_mult <= psi_fix_mult(aver_acc, AccFmt_c, gain_s, GainFmt_c, MultFmt_c, psi_fix_trunc, psi_fix_wrap);
        end if;
        -- output assigment
        dat_o <= psi_fix_resize(aver_mult, MultFmt_c, in_fmt_g, psi_fix_round, psi_fix_sat);
        vld_o <= vld_s(vld_s'left);
      end if;
    end if;
  end process;

  -- FIFO for sample buffering
  fifo_wr <= vld_i and not aver_rst;

  inst_sample_buffer : entity work.psi_common_sync_fifo
    generic map(
      width_g     => psi_fix_size(in_fmt_g),
      depth_g     => max_taps_g,
      ram_style_g => "block"
    )
    port map(
      clk_i => clk_i,
      rst_i => aver_rst,
      dat_i => dat_i,
      vld_i => fifo_wr,
      dat_o => fifo_out,
      vld_o => fifo_vld,
      rdy_i => fifo_rd
    );

end architecture;
