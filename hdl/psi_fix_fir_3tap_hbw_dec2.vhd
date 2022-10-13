------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Radoslaw Rybaniec
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component is half bandwidth decimation filter
-- - The number of channels is configurable
-- - All channels are processed in parallel and their data must be synchronized

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;

-- $$ PROCESSES=Input,Output $$

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_fix_fir_3tap_hbw_dec2 is
  generic(
    InFmt_g    : PsiFixFmt_t := (1, 0, 17);
    OutFmt_g   : PsiFixFmt_t := (1, 0, 17);
    Channels_g : natural     := 2;      -- $$ EXPORT=true $$
    Separate_g : boolean     := true;   -- $$ EXPORT=true $$
    Rnd_g      : PsiFixRnd_t := PsiFixRound;
    Sat_g      : PsiFixSat_t := PsiFixSat
  );
  port(
    -- Control Signals
    Clk     : in  std_logic;            -- $$ TYPE=CLK; FREQ=100e6; Proc=Input $$
    Rst     : in  std_logic;            -- $$ TYPE=RST; CLK=Clk $$
    -- Input
    InVld   : in  std_logic;            -- $$ PROC=Input $$
    InData  : in  std_logic_vector(PsiFixSize(InFmt_g) * 2 * Channels_g - 1 downto 0); -- $$ PROC=Input $$
    -- Output
    OutVld  : out std_logic;            -- $$ PROC=Output $$
    OutData : out std_logic_vector(PsiFixSize(OutFmt_g) * Channels_g - 1 downto 0) -- $$ PROC=Output $$
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_fir_3tap_hbw_dec2 is

  -- Constants
  constant Shifts_c : t_ainteger  := (2, 1, 2);
  constant IntFmt_c : PsiFixFmt_t := (InFmt_g.S, InFmt_g.I, InFmt_g.F + 2);

  -- types
  type InData_t is array (0 to 2 * Channels_g - 1) of std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
  type In3_t is array (0 to 3 * Channels_g - 1) of std_logic_vector(PsiFixSize(InFmt_g) - 1 downto 0);
  type Mult_t is array (0 to 3 * Channels_g - 1) of std_logic_vector(PsiFixSize(IntFmt_c) - 1 downto 0);
  type Add_t is array (0 to 2 * Channels_g - 1) of std_logic_vector(PsiFixSize(IntFmt_c) - 1 downto 0);
  type OutData_t is array (0 to Channels_g - 1) of std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);

  -- Two process method
  type two_process_r is record
    Vld     : std_logic_vector(0 to 3);
    InData  : InData_t;
    In3Sig  : In3_t;
    MultSig : Mult_t;
    AddSig  : Add_t;
    AddSigZ : Add_t;
    OutSig  : OutData_t;
  end record;
  signal r, r_next : two_process_r;

  signal InDataS : InData_t;

begin

  --------------------------------------------
  -- Input Transformation
  --------------------------------------------
  process(InData) is
  begin
    for i in 0 to 2 * Channels_g - 1 loop
      InDataS(i) <= InData(PsiFixSize(InFmt_g) * (i + 1) - 1 downto PsiFixSize(InFmt_g) * i);
    end loop;
  end process;

  --------------------------------------------
  -- Combinatorial Process
  --------------------------------------------
  p_comb : process(r, InVld, InDataS)
    variable v : two_process_r;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Pipe Handling ***
    v.Vld(v.Vld'low + 1 to v.Vld'high) := r.Vld(r.Vld'low to r.Vld'high - 1);

    -- *** Stage 0 ***
    -- Input Registers
    v.Vld(0) := InVld;

    if InVld = '1' then
      v.InData := InDataS;
      if Separate_g then
        for v_i in 0 to inDataS'high / 2 loop
          -- first input
          v.in3Sig(v_i)                  := r.InData(v_i * 2 + 1);
          -- second input
          v.in3Sig(v_i + 1 * Channels_g) := InDataS(v_i * 2);
          -- third input
          v.in3Sig(v_i + 2 * Channels_g) := InDataS(v_i * 2 + 1);
        end loop;
      else
        v.in3Sig(0) := r.InData(r.InData'high);
        for v_i in 1 to inDataS'high / 2 loop
          -- first input
          v.in3Sig(v_i) := InDataS(2 * v_i - 1);
        end loop;
        for v_i in 0 to inDataS'high / 2 loop
          -- second input
          v.in3Sig(v_i + 1 * Channels_g) := InDataS(2 * v_i);
          -- third input
          v.in3Sig(v_i + 2 * Channels_g) := InDataS(2 * v_i + 1);
        end loop;
      end if;
    end if;

    -- *** Stage 1 ***
    -- Multiply (shift)
    for v_i in r.MultSig'range loop
      v.MultSig(v_i) := PsiFixShiftRight(r.in3Sig(v_i), InFmt_g, Shifts_c(v_i / Channels_g), 2, IntFmt_c, Rnd_g, Sat_g);
    end loop;

    -- *** Stage 2 ***
    -- First Addition
    for v_i in 0 to Channels_g - 1 loop
      v.AddSig(v_i)  := PsiFixAdd(r.MultSig(v_i), IntFmt_c, r.MultSig(v_i + Channels_g), IntFmt_c, IntFmt_c, Rnd_g, Sat_g);
      v.AddSigZ(v_i) := r.MultSig(v_i + 2 * Channels_g);
    end loop;
    -- *** Stage 3 ***
    -- Second Addition
    for v_i in r.OutSig'range loop
      v.OutSig(v_i) := PsiFixAdd(r.AddSig(v_i), IntFmt_c, r.AddSigZ(v_i), IntFmt_c, OutFmt_g, Rnd_g, Sat_g);
    end loop;

    -- *** Output Assignment ***
    for i in 0 to Channels_g - 1 loop
      OutData(PsiFixSize(OutFmt_g) * (i + 1) - 1 downto PsiFixSize(OutFmt_g) * i) <= r.OutSig(i);
    end loop;

    OutVld <= r.Vld(r.Vld'high);

    -- *** Assign to signal ***
    r_next <= v;
  end process;

  --------------------------------------------
  -- Sequential Process
  --------------------------------------------
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end architecture;

