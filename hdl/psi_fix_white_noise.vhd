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

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_fix_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
entity psi_fix_white_noise is
  generic( out_fmt_g : psi_fix_fmt_t           := (0, 0, 31);
           seed_g   : unsigned(31 downto 0) := X"A38E3C1D";
           rst_pol_g: std_logic             :='1');
  port(    -- Control Signals
          clk_i     : in  std_logic;
          rst_i     : in  std_logic;
          vld_i     : in  std_logic := '1';
          vld_o     : out std_logic;
          dat_o     : out std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0));
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_fix_white_noise is
  -- Constants
  constant OutBits_c : integer := psi_fix_size(out_fmt_g);

  -- Two Process Method
  type two_process_r is record
    Lfsr    : t_aslv32(0 to OutBits_c - 1);
    OutData : std_logic_vector(psi_fix_size(out_fmt_g) - 1 downto 0);
    OutVld  : std_logic;
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  p_assert : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = not rst_pol_g then
        assert psi_fix_size(out_fmt_g) <= 32 report "###ERROR###: psi_fix_white_noise: Output width cannot be larger than 32 bits" severity error;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Generate Output ***
    v.OutVld := vld_i;
    for i in 0 to OutBits_c - 1 loop
      v.OutData(i) := r.Lfsr(i)(0);
    end loop;

    -- *** Update LFSRs ***
    if vld_i = '1' then
      for i in 0 to OutBits_c - 1 loop
        v.Lfsr(i)    := shift_left(r.Lfsr(i), 1);
        v.Lfsr(i)(0) := r.Lfsr(i)(31) xor r.Lfsr(i)(20) xor r.Lfsr(i)(26) xor r.Lfsr(i)(25);
      end loop;
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  dat_o <= r.OutData;
  vld_o  <= r.OutVld;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        for i in 0 to OutBits_c - 1 loop
          r.Lfsr(i) <= std_logic_vector(seed_g + shift_left(to_unsigned(1, 32), i));
        end loop;
        r.OutVld <= '0';
      end if;
    end if;
  end process;

end architecture;
