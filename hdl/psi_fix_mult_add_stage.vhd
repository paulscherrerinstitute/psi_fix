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

library work;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_fix_mult_add_stage is
  generic(
    InAFmt_g    : PsiFixFmt_t := (1, 0, 17);
    InBFmt_g    : PsiFixFmt_t := (1, 0, 17);
    AddFmt_g    : PsiFixFmt_t := (1, 0, 17);
    InBIsCoef_g : boolean     := false
  );
  port(
    -- Control Signals
    Clk            : in  std_logic;     -- $$ type=clk; freq=100e6 $$
    Rst            : in  std_logic;     -- $$ type=rst; clk=Clk $$
    -- Input	
    InAVld         : in  std_logic;
    InA            : in  std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
    InADel2        : out std_logic_vector(PsiFixSize(InAFmt_g) - 1 downto 0);
    InBVld         : in  std_logic;
    InB            : in  std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
    InBDel2        : out std_logic_vector(PsiFixSize(InBFmt_g) - 1 downto 0);
    -- Output	
    AddChainIn     : in  std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0);
    AddChainOut    : out std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0);
    AddChainOutVld : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_mult_add_stage is

  constant MultFmt_c : PsiFixFmt_t := (max(InAFmt_g.S, InBFmt_g.S), InAFmt_g.I + InBFmt_g.I + 1, InAFmt_g.F + InBFmt_g.F);
  signal InAReg0     : std_logic_vector(InA'range);
  signal InAReg1     : std_logic_vector(InA'range);
  signal InBReg0     : std_logic_vector(InB'range);
  signal InBReg1     : std_logic_vector(InB'range);
  signal MultReg     : std_logic_vector(PsiFixSize(MultFmt_c) - 1 downto 0);
  signal AddReg      : std_logic_vector(PsiFixSize(AddFmt_g) - 1 downto 0);
  signal Vld0        : std_logic;
  signal Vld1        : std_logic;
  signal Vld2        : std_logic;
  signal Vld3        : std_logic;

begin
  -- DSP Slice description
  p_dsp : process(Clk)
  begin
    if rising_edge(Clk) then
      -- *** Stage 0 ***
      if InAVld = '1' then
        InAReg0 <= InA;
      end if;
      if InBVld = '1' then
        InBReg0 <= InB;
      end if;
      -- If B is used as data port, calculations must be updated on new B values
      if not InBIsCoef_g then
        Vld0 <= InAVld or InBVld;
      -- If B is used as asynchronously updated coefficient, a change to the coefficient does not lead to an output sample
      else
        Vld0 <= InAVld;
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
        AddReg <= PsiFixAdd(AddChainIn, AddFmt_g, MultReg, MultFmt_c, AddFmt_g);
      end if;
      if Rst = '1' then
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
  AddChainOut    <= AddReg;
  InADel2        <= InAReg1;
  InBDel2        <= InBReg1;
  AddChainOutVld <= Vld3;

end architecture;

