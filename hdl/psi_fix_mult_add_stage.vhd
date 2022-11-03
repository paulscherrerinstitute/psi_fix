------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Multiply-Add stage that also fits well into chained DSP slices as common
-- to many FPGA families.
-- It fits best to DSP slice columns(as for example present in Xilinx 7-Series,
-- Xilinx 6-series, Xilinx Spartan3ADSP, etc.) but can also be implemented using
-- registers and multipliers. As a result it is synthesizable for all FPGAs but
-- not optimal if there are no DSP columns.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

entity psi_fix_mult_add_stage is
  generic(
    in_a_fmt_g    : psi_fix_fmt_t := (1, 0, 17);                                -- data A input format FP
    in_b_fmt_g    : psi_fix_fmt_t := (1, 0, 17);                                -- data B input format FP
    add_fmt_g    : psi_fix_fmt_t := (1, 0, 17);                                -- output format FP
    in_b_is_coef_g : boolean       := false;                                     -- If True, InBVld is only used to write a cst coef to the input reg of the DSP slice
                                                                              -- If False, InBVld leads to a multiply-add operation and is propagated to AddChainOutVld
    rst_pol_g   : std_logic     := '1'                                        -- reset polarity
  );
  port(
    clk_i           : in  std_logic;                                           -- system clock $$ type=clk; freq=100e6 $$
    rst_i           : in  std_logic;                                           -- system reset $$ type=rst; clk=clk_i $$
    dat_a_i         : in  std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0); -- data in put a
    vld_a_i         : in  std_logic;                                           -- vld a
    del2_a_o        : out std_logic_vector(psi_fix_size(in_a_fmt_g) - 1 downto 0); -- registred data a by 2 clock cycles (efficient pipeline for FIR implementation)
    dat_b_i         : in  std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0); -- data input b
    vld_b_i         : in  std_logic;                                           -- vld b
    del2_b_o        : out std_logic_vector(psi_fix_size(in_b_fmt_g) - 1 downto 0); -- registered data b by 2 clock cycles (efficient pipeline for FIR implementation)
    chain_add_i     : in  std_logic_vector(psi_fix_size(add_fmt_g) - 1 downto 0); -- adder chain input data
    chain_add_o     : out std_logic_vector(psi_fix_size(add_fmt_g) - 1 downto 0); -- adder chain output data
    chain_add_vld_o : out std_logic                                            -- adder chain output valid
  );
end entity;

architecture rtl of psi_fix_mult_add_stage is

  constant MultFmt_c : psi_fix_fmt_t := (max(in_a_fmt_g.S, in_b_fmt_g.S), in_a_fmt_g.I + in_b_fmt_g.I + 1, in_a_fmt_g.F + in_b_fmt_g.F);
  signal InAReg0     : std_logic_vector(dat_a_i'range);
  signal InAReg1     : std_logic_vector(dat_a_i'range);
  signal InBReg0     : std_logic_vector(dat_b_i'range);
  signal InBReg1     : std_logic_vector(dat_b_i'range);
  signal MultReg     : std_logic_vector(psi_fix_size(MultFmt_c) - 1 downto 0);
  signal AddReg      : std_logic_vector(psi_fix_size(add_fmt_g) - 1 downto 0);
  signal Vld0        : std_logic;
  signal Vld1        : std_logic;
  signal Vld2        : std_logic;
  signal Vld3        : std_logic;

begin
  -- DSP Slice description
  p_dsp : process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- *** Stage 0 ***
      if vld_a_i = '1' then
        InAReg0 <= dat_a_i;
      end if;
      if vld_b_i = '1' then
        InBReg0 <= dat_b_i;
      end if;
      -- If B is used as data port, calculations must be updated on new B values
      if not in_b_is_coef_g then
        Vld0 <= vld_a_i or vld_b_i;
      -- If B is used as asynchronously updated coefficient, a change to the coefficient does not lead to an output sample
      else
        Vld0 <= vld_a_i;
      end if;
      -- *** Stage 1 ***
      if Vld0 = '1' then
        InAReg1 <= InAReg0;
        InBReg1 <= InBReg0;
      end if;
      Vld1 <= Vld0;
      -- *** Stage 2 ***
      if Vld1 = '1' then
        MultReg <= psi_fix_mult(InAReg1, in_a_fmt_g, InBReg1, in_b_fmt_g, MultFmt_c);
      end if;
      Vld2 <= Vld1;
      -- *** Stage 3 ***
      if Vld2 = '1' then
        AddReg <= psi_fix_add(chain_add_i, add_fmt_g, MultReg, MultFmt_c, add_fmt_g);
      end if;
      if rst_i = rst_pol_g then
        Vld0    <= '0';
        Vld1    <= '0';
        Vld2    <= '0';
        InAReg0 <= (others => '0');
        InAReg1 <= (others => '0');
        InBReg0 <= (others => '0');
        InBReg1 <= (others => '0');
      end if;
      Vld3 <= Vld2;
    end if;
  end process;

  -- Outputs
  chain_add_o     <= AddReg;
  del2_a_o        <= InAReg1;
  del2_b_o        <= InBReg1;
  chain_add_vld_o <= Vld3;

end architecture;
