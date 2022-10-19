------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--	Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_fix_pkg.all;

entity psi_fix_param_ram is
  generic(
    Depth_g    : positive    := 1024;
    Fmt_g      : PsiFixFmt_t := (1, 0, 15);
    Behavior_g : string      := "RBW";  -- "RBW" = read-before-write, "WBR" = write-before-read
    Init_g     : t_areal     := (0.0, 0.0) -- First N parameters are initialized, others are zero
  );
  port(
    -- Port A
    ClkA  : in  std_logic                                        := '0';
    AddrA : in  std_logic_vector(log2ceil(Depth_g) - 1 downto 0) := (others => '0');
    WrA   : in  std_logic                                        := '0';
    DinA  : in  std_logic_vector(PsiFixSize(Fmt_g) - 1 downto 0) := (others => '0');
    DoutA : out std_logic_vector(PsiFixSize(Fmt_g) - 1 downto 0);
    -- Port B
    ClkB  : in  std_logic                                        := '0';
    AddrB : in  std_logic_vector(log2ceil(Depth_g) - 1 downto 0) := (others => '0');
    WrB   : in  std_logic                                        := '0';
    DinB  : in  std_logic_vector(PsiFixSize(Fmt_g) - 1 downto 0) := (others => '0');
    DoutB : out std_logic_vector(PsiFixSize(Fmt_g) - 1 downto 0)
  );
end entity;

architecture rtl of psi_fix_param_ram is

  -- memory array
  type mem_t is array (Depth_g - 1 downto 0) of std_logic_vector(PsiFixSize(Fmt_g) - 1 downto 0);

  function GetInit return mem_t is
    variable mem_v : mem_t := (others => (others => '0'));
  begin
    for i in 0 to Init_g'length - 1 loop
      mem_v(i) := PsiFixFromReal(Init_g(i), Fmt_g);
    end loop;
    return mem_v;
  end function;

  shared variable mem : mem_t := GetInit;

begin

  assert Behavior_g = "RBW" or Behavior_g = "WBR" report "psi_fix_param_ram: Behavior_g must be RBW or WBR" severity error;

  -- Port A
  porta_p : process(ClkA)
  begin
    if rising_edge(ClkA) then
      if Behavior_g = "RBW" then
        DoutA <= mem(to_integer(unsigned(AddrA)));
      end if;
      if WrA = '1' then
        mem(to_integer(unsigned(AddrA))) := DinA;
      end if;
      if Behavior_g = "WBR" then
        DoutA <= mem(to_integer(unsigned(AddrA)));
      end if;
    end if;
  end process;

  -- Port B
  portb_p : process(ClkB)
  begin
    if rising_edge(ClkB) then
      if Behavior_g = "RBW" then
        DoutB <= mem(to_integer(unsigned(AddrB)));
      end if;
      if WrB = '1' then
        mem(to_integer(unsigned(AddrB))) := DinB;
      end if;
      if Behavior_g = "WBR" then
        DoutB <= mem(to_integer(unsigned(AddrB)));
      end if;
    end if;
  end process;
  
end architecture;

