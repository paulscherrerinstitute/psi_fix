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
    InAFmt_g    : PsiFixFmt_t := (1, 0, 17);
    InBFmt_g    : PsiFixFmt_t := (1, 0, 17);
    AddFmt_g    : PsiFixFmt_t := (1, 0, 17);
    InBIsCoef_g : boolean     := false;
    rst_pol_g   : std_logic   := '1'
  );
  port(
    -- Control Signals
    clk_i          : in  std_logic;     -- $$ type=clk; freq=100e6 $$
    rst_i          : in  std_logic;     -- $$ type=rst; clk=clk_i $$
    -- Input	
    vld_a_i        : in  std_logic;                                           -- vld a
    dat_a_i        : in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- data in put a
    del2_a_o       : out std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0); -- registred data a
    vld_b_i        : in  std_logic;                                           -- vld b
    dat_b_i        : in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- data input b
    del2_b_o       : out std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0); -- registered data b
    -- Output	
    chain_add_i     : in  std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0); -- adder chain input data
    chain_add_o     : out std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0); -- adder chain output data
    chain_add_vld_o : out std_logic                                            -- adder chain output valid
  );
end entity;

architecture rtl of psi_fix_mult_add_stage is

  constant MultFmt_c : PsiFixFmt_t := (max(InAFmt_g.S, InBFmt_g.S), InAFmt_g.I + InBFmt_g.I + 1, InAFmt_g.F + InBFmt_g.F);
  signal InAReg0     : std_logic_vector(dat_a_i'range);
  signal InAReg1     : std_logic_vector(dat_a_i'range);
  signal InBReg0     : std_logic_vector(dat_b_i'range);
  signal InBReg1     : std_logic_vector(dat_b_i'range);
  signal MultReg     : std_logic_vector(PsiFixSize(MultFmt_c) - 1 downto 0);
  signal AddReg      : std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0);
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
      if not InBIsCoef_g then
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
        MultReg <= PsiFixMult(InAReg1, InAFmt_g, InBReg1, InBFmt_g, MultFmt_c);
      end if;
      Vld2 <= Vld1;
      -- *** Stage 3 ***
      if Vld2 = '1' then
        AddReg <= PsiFixAdd(chain_add_i, AddFmt_g, MultReg, MultFmt_c, AddFmt_g);
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
  chain_add_o    <= AddReg;
  del2_a_o       <= InAReg1;
  del2_b_o       <= InBReg1;
  chain_add_vld_o <= Vld3;

end architecture;
