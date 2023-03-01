------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler/ Benoît Stef / Radoslaw Rybaniec
------------------------------------------------------------------------------
-- see Library/Python/TbGenerator

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_tb_textfile_pkg.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_fix_mod_cplx2real_tb is
  generic(file_folder_g : string               := "../testbench/psi_fix_mod_cplx2real_tb/Data";
          freq_clock_g  : real                 := 100.0e6;
          pl_stages_g   : integer range 5 to 6 := 5;
          rst_pol_g     : std_logic            := '1';
          clk_per_spl_g : integer              := 1;
          ratio_num_g   : integer              := 10;
          ratio_den_g   : integer              := 1);
end entity;

architecture tb of psi_fix_mod_cplx2real_tb is
  -- Format definition
  constant InFixFmt_c         : psi_fix_fmt_t              := (1, 1, 15); --same as python model
  constant CoefFixFmt_c       : psi_fix_fmt_t              := (1, 1, 23); --same as python model
  constant OutFixFmt_c        : psi_fix_fmt_t              := (1, 1, 15); --same as python model
  constant InternalFmt_c      : psi_fix_fmt_t              := (1, 1, 23); --same as python model
  --smthg
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_check_c   : integer                  := 1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  --timedef
  constant period_c           : time                     := (1 sec) / freq_clock_g;

  --internal signals definition
  signal clk_sti    : std_logic                                              := '0';
  signal rst_sti    : std_logic                                              := rst_pol_g;
  signal str_sti    : std_logic                                              := '0';
  signal data_I_sti : std_logic_vector(psi_fix_size(InFixFmt_c) - 1 downto 0)  := (others => '0');
  signal data_Q_sti : std_logic_vector(psi_fix_size(InFixFmt_c) - 1 downto 0)  := (others => '0');
  signal data_obs   : std_logic_vector(psi_fix_size(OutFixFmt_c) - 1 downto 0) := (others => '0');
  signal str_obs    : std_logic                                              := '0';
  signal Vld_s      : std_logic;

  signal TbRunning : boolean                := true;
  signal SigIn     : TextfileData_t(0 to 1) := (others => 0);
  signal SigOut    : TextfileData_t(0 to 0) := (others => 0);
begin

  DUT : entity work.psi_fix_mod_cplx2real
    generic map(
      rst_pol_g     => rst_pol_g,
      pl_stages_g   => pl_stages_g,
      inp_fmt_g     => InFixFmt_c,
      coef_fmt_g    => CoefFixFmt_c,
      int_fmt_g     => InternalFmt_c,
      out_fmt_g     => OutFixFmt_c,
      ratio_num_g   => ratio_num_g,
      ratio_den_g => ratio_den_g)
    port map(
      clk_i => clk_sti,
      rst_i => rst_sti,
      dat_inp_i => data_I_sti,
      dat_qua_i => data_Q_sti,
      vld_i => str_sti,
      dat_o => data_obs,
      vld_o => str_obs);

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until rst_sti = '0';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_clk_i : process
    constant Frequency_c : real := real(freq_clock_g);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_rst_i : process
  begin
    wait for 1 us;
    -- Wait for two clk edges to ensure reset is active for at least one edge
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** stim ***
  data_I_sti <= std_logic_vector(to_signed(SigIn(0), data_I_sti'length));
  data_Q_sti <= std_logic_vector(to_signed(SigIn(1), data_Q_sti'length));
  p_stim : process
  begin
    -- start of process !DO NOT EDIT
    wait until rst_sti = '0';

    -- Apply Stimuli
    ApplyTextfileContent(Clk         => clk_sti,
                         Rdy         => PsiTextfile_SigOne,
                         Vld         => str_sti,
                         Data        => SigIn,
                         Filepath    => file_folder_g & "/input_" & integer'image(ratio_num_g) & "_" & integer'image(ratio_den_g) & ".txt",
                         ClkPerSpl   => clk_per_spl_g,
                         IgnoreLines => 1);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** check ***
  SigOut(0) <= to_integer(signed(data_obs));
  p_check : process
  begin
    -- start of process !DO NOT EDIT
    wait until rst_sti = '0';

    -- Check
    CheckTextfileContent(Clk         => clk_sti,
                         Rdy         => PsiTextfile_SigUnused,
                         Vld         => str_obs,
                         Data        => SigOut,
                         Filepath    => file_folder_g & "/output_" & integer'image(ratio_num_g) & "_" & integer'image(ratio_den_g) & ".txt",
                         IgnoreLines => 0,
                         Tolerance   => 1); -- compatibility with GHDL
    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_check_c) <= '1';
    wait;
  end process;

end architecture;
