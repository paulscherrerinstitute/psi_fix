------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--	Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_fix_pkg.all;

entity psi_fix_param_ram is
  generic(
    depth_g    : positive    := 1024;         -- memory depth
    fmt_g      : psi_fix_fmt_t := (1, 0, 15); -- fixed format
    behavior_g : string      := "RBW";        -- "RBW" = read-before-write, "WBR" = write-before-read
    init_g     : t_areal     := (0.0, 0.0)    -- First N parameters are initialized, others are zero
  );
  port(
    -- Port A
    ClkA  : in  std_logic                                        := '0';            -- clock port A
    AddrA : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');-- address port A
    WrA   : in  std_logic                                        := '0';            -- write enable A
    DinA  : in  std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0) := (others => '0');-- data input A
    DoutA : out std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0);                   -- data output A
    -- Port B
    ClkB  : in  std_logic                                        := '0';            -- clock port B
    AddrB : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');-- address port B
    WrB   : in  std_logic                                        := '0';            -- write enable B 
    DinB  : in  std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0) := (others => '0');-- data input B
    DoutB : out std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0)                    -- data output B
  );
end entity;

architecture rtl of psi_fix_param_ram is

  -- memory array
  type mem_t is array (depth_g - 1 downto 0) of std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0);

  function GetInit return mem_t is
    variable mem_v : mem_t := (others => (others => '0'));
  begin
    for i in 0 to init_g'length - 1 loop
      mem_v(i) := psi_fix_from_real(init_g(i), fmt_g);
    end loop;
    return mem_v;
  end function;

  shared variable mem : mem_t := GetInit;

begin

  assert behavior_g = "RBW" or behavior_g = "WBR" report "psi_fix_param_ram: behavior_g must be RBW or WBR" severity error;

  -- Port A
  porta_p : process(ClkA)
  begin
    if rising_edge(ClkA) then
      if behavior_g = "RBW" then
        DoutA <= mem(to_integer(unsigned(AddrA)));
      end if;
      if WrA = '1' then
        mem(to_integer(unsigned(AddrA))) := DinA;
      end if;
      if behavior_g = "WBR" then
        DoutA <= mem(to_integer(unsigned(AddrA)));
      end if;
    end if;
  end process;

  -- Port B
  portb_p : process(ClkB)
  begin
    if rising_edge(ClkB) then
      if behavior_g = "RBW" then
        DoutB <= mem(to_integer(unsigned(AddrB)));
      end if;
      if WrB = '1' then
        mem(to_integer(unsigned(AddrB))) := DinB;
      end if;
      if behavior_g = "WBR" then
        DoutB <= mem(to_integer(unsigned(AddrB)));
      end if;
    end if;
  end process;
  
end architecture;

