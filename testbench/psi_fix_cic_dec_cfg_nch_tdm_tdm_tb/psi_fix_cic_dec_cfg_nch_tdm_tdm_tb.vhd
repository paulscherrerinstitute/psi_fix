------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;

library std;
use std.textio.all;

entity psi_fix_cic_dec_cfg_nch_tdm_tdm_tb is
  generic(
    data_dir_g      : string               := "../testbench/psi_fix_cic_dec_cfg_nch_tdm_tdm_tb/Data";
    in_file_g       : string               := "input_o4_r9_dd2_gcTrue.txt";
    out_file_g      : string               := "output_o4_r9_dd2_gcTrue.txt";
    idle_cycles_g   : integer              := 2;
    order_g        : integer              := 4;
    ratio_g        : integer              := 9;
    diff_delay_g    : natural range 1 to 2 := 2;
    auto_gain_corr_g : boolean              := True
  );
end entity psi_fix_cic_dec_cfg_nch_tdm_tdm_tb;

architecture sim of psi_fix_cic_dec_cfg_nch_tdm_tdm_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant InFmt_c        : psi_fix_fmt_t                                         := (1, 0, 16);
  constant OutFmt_c       : psi_fix_fmt_t                                         := (1, 0, 17);
  constant Channels_c     : integer                                             := 3;
  constant InChWidth_c    : integer                                             := psi_fix_size(InFmt_c);
  constant MaxRatio_c     : integer                                             := 10000;
  constant Ratio_c        : std_logic_vector(log2ceil(MaxRatio_c) - 1 downto 0) := to_uslv(ratio_g - 1, log2ceil(MaxRatio_c));
  constant CicGain_c      : real                                                := (real(ratio_g) * real(diff_delay_g))**real(order_g);
  constant CicGrowth_c    : integer                                             := log2ceil(CicGain_c - 0.1);
  constant Shift_c        : std_logic_vector(7 downto 0)                        := to_uslv(CicGrowth_c, 8);
  constant GainCorr_c     : real                                                := 2.0**real(CicGrowth_c) / CicGain_c;
  constant GainCorrCoef_c : std_logic_vector(16 downto 0)                       := psi_fix_from_real(GainCorr_c, (0, 1, 16));

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockFrequency_c : real    := 100.0e6;
  constant ClockPeriod_c    : time    := (1 sec) / ClockFrequency_c;
  signal TbRunning          : boolean := True;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal Clk     : std_logic                                           := '0';
  signal Rst     : std_logic                                           := '1';
  signal InVld   : std_logic                                           := '0';
  signal InData  : std_logic_vector(psi_fix_size(InFmt_c) - 1 downto 0)  := (others => '0');
  signal OutVld  : std_logic                                           := '0';
  signal OutData : std_logic_vector(psi_fix_size(OutFmt_c) - 1 downto 0) := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_fix_cic_dec_cfg_nch_tdm_tdm
    generic map(
      channels_g     => Channels_c,
      order_g        => order_g,
      max_ratio_g     => MaxRatio_c,
      diff_delay_g    => diff_delay_g,
      in_fmt_g        => InFmt_c,
      out_fmt_g       => OutFmt_c,
      auto_gain_corr_g => auto_gain_corr_g
    )
    port map(
      -- Control Signals
      clk_i           => Clk,
      rst_i           => Rst,
      -- Configuration
      cfg_ratio_i     => Ratio_c,
      cfg_shift_i     => Shift_c,
      cfg_gain_corr_i => GainCorrCoef_c,
      -- Data Ports
      dat_i           => InData,
      vld_i           => InVld,
      dat_o           => OutData,
      vld_o           => OutVld
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk : process
  begin
    Clk <= '0';
    while TbRunning loop
      wait for 0.5 * ClockPeriod_c;
      Clk <= '1';
      wait for 0.5 * ClockPeriod_c;
      Clk <= '0';
    end loop;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- Apply Input
  -------------------------------------------------------------------------
  p_input : process
    file fIn     : text;
    variable r   : line;
    variable val : integer;
  begin
    -- Reset
    Rst <= '1';
    wait for 1 us;
    Rst <= '0';
    wait for 1 us;

    -- Test file content (bittrueness)
    --print(data_dir_g & "/" & in_file_g);
    file_open(fIn, data_dir_g & "/" & in_file_g, read_mode);
    wait until rising_edge(Clk);
    while not endfile(fIn) loop
      readline(fIn, r);
      for ch in 0 to 2 loop
        InVld  <= '1';
        read(r, val);
        InData <= std_logic_vector(to_signed(val, InChWidth_c));
        wait until rising_edge(Clk);
        for c in 0 to idle_cycles_g - 1 loop
          InVld <= '0';
          wait until rising_edge(Clk);
        end loop;
      end loop;
    end loop;
    InVld <= '0';
    file_close(fIn);

    -- TB done
    TbRunning <= false;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- Check Output
  -------------------------------------------------------------------------
  p_output : process
    file fOut     : text;
    variable r    : line;
    variable resp : integer;
    variable idx  : integer := 0;
  begin
    wait until Rst = '0';

    -- Check initial state
    assert OutVld = '0' report "###ERROR###: Initial state of output valid is high" severity error;

    -- Test file content (bittrueness)
    file_open(fOut, data_dir_g & "/" & out_file_g, read_mode);
    while not endfile(fOut) loop
      readline(fOut, r);
      for ch in 0 to 2 loop
        read(r, resp);
        wait until rising_edge(Clk) and OutVld = '1';
        StdlvCompareInt(resp, OutData, "WrongValue [" & integer'image(idx) & "] channel " & integer'image(ch));
      end loop;
      idx := idx + 1;
    end loop;
    file_close(fOut);
    wait;
  end process;

end sim;
