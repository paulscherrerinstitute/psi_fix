------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_textfile_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity <ENTITY_NAME>_tb is
  generic (
    stimuli_dir_g   : string    := "../testbench/psi_fix_lin_approx_tb/sin18b"
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture sim of <ENTITY_NAME>_tb is

  -- constants
  constant InFmt_c    : psi_fix_fmt_t   := <IN_FMT>;
  constant OutFmt_c   : psi_fix_fmt_t   := <OUT_FMT>;
  constant ClkPeriod_c  : time        := 10 ns;

  -- Signals
  signal Clk      : std_logic                       := '0';
  signal Rst      : std_logic                       := '1';
  signal InVld    : std_logic                       := '0';
  signal InData   : std_logic_vector(psi_fix_size(InFmt_c)-1 downto 0)    := (others => '0');
  signal OutVld   : std_logic                       := '0';
  signal OutData    : std_logic_vector(psi_fix_size(OutFmt_c)-1 downto 0)   := (others => '0');

  -- Tb Signals
  signal TbRunning  : boolean := true;
  signal SigIn    : TextfileData_t(0 to 0) := (others => 0);
  signal SigOut   : TextfileData_t(0 to 0) := (others => 0);


begin

  i_dut : entity work.<ENTITY_NAME>
    port map (
      -- Control Signals
      clk_i   => Clk,
      rst_i   => Rst,
      -- Input
      vld_i => InVld,
      dat_i => InData,
      -- Output
      vld_o => OutVld,
      dat_o => OutData
    );

  p_clk : process
  begin
    Clk <= '0';
    while TbRunning loop
      wait for ClkPeriod_c/2;
      Clk <= '1';
      wait for ClkPeriod_c/2;
      Clk <= '0';
    end loop;
    wait;
  end process;

  InData <= psi_fix_from_bits_as_int(SigIn(0), InFmt_c);
  p_stimuli : process
  begin
    Rst <= '1';
    -- Remove reset
    wait for 1 us;
    wait until rising_edge(Clk);
    Rst <= '0';
    wait for 1 us;

    -- Apply stimuli_dir_g
    ApplyTextfileContent( Clk     => Clk,
                Rdy     => PsiTextfile_SigOne,
                Vld     => InVld,
                Data    => SigIn,
                Filepath  => stimuli_dir_g & "/stimuli.txt",
                ClkPerSpl => 1);

    -- Finish
    wait for 1 us;
    Rst <= '1';
    TbRunning <= False;
    wait;
  end process;

  SigOut(0) <= psi_fix_get_bits_as_int(OutData, OutFmt_c);
  p_response : process
  begin

    -- Check
    CheckTextfileContent( Clk       => Clk,
                Rdy       => PsiTextfile_SigUnused,
                Vld       => OutVld,
                Data      => SigOut,
                Filepath    => stimuli_dir_g & "/response.txt");

    -- Finish
    wait;
  end process;


end sim;
