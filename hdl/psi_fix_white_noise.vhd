------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
-- a PRBS is also present in the psi common library and LFSR weight can be selected
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
entity psi_fix_white_noise is
  generic(
    OutFmt_g : PsiFixFmt_t           := (0, 0, 31);
    Seed_g   : unsigned(31 downto 0) := X"A38E3C1D"
  );
  port(
    -- Control Signals
    Clk     : in  std_logic;
    Rst     : in  std_logic;
    -- Input
    InVld   : in  std_logic := '1';
    -- Output
    OutVld  : out std_logic;
    OutData : out std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_white_noise is
  -- Constants
  constant OutBits_c : integer := PsiFixSize(OutFmt_g);

  -- Two Process Method
  type two_process_r is record
    Lfsr    : t_aslv32(0 to OutBits_c - 1);
    OutData : std_logic_vector(PsiFixSize(OutFmt_g) - 1 downto 0);
    OutVld  : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  p_assert : process(Clk)
  begin
    if rising_edge(Clk) then
      if Rst = '0' then
        assert PsiFixSize(OutFmt_g) <= 32 report "###ERROR###: psi_fix_white_noise: Output width cannot be larger than 32 bits" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, InVld)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Generate Output ***
    v.OutVld := InVld;
    for i in 0 to OutBits_c - 1 loop
      v.OutData(i) := r.Lfsr(i)(0);
    end loop;

    -- *** Update LFSRs ***
    if InVld = '1' then
      for i in 0 to OutBits_c - 1 loop
        v.Lfsr(i)    := ShiftLeft(r.Lfsr(i), 1);
        v.Lfsr(i)(0) := r.Lfsr(i)(31) xor r.Lfsr(i)(20) xor r.Lfsr(i)(26) xor r.Lfsr(i)(25);
      end loop;
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  OutData <= r.OutData;
  OutVld  <= r.OutVld;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        for i in 0 to OutBits_c - 1 loop
          r.Lfsr(i) <= std_logic_vector(Seed_g + shift_left(to_unsigned(1, 32), i));
        end loop;
        r.OutVld <= '0';
      end if;
    end if;
  end process;

end rtl;
