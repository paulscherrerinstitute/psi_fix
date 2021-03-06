------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
--This basic block allows set min and max threshold in fixed point format fashion
--prior to deliver flag indications output

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;

entity psi_fix_comparator is
  generic(fmt_g     : PsiFixFmt_t := (1, 0, 15);
          rst_pol_g : std_logic   := '1');
  port(clk_i     : in  std_logic;
       rst_i     : in  std_logic;
       set_min_i : in  std_logic_vector(PsiFixSize(fmt_g) - 1 downto 0);
       set_max_i : in  std_logic_vector(PsiFixSize(fmt_g) - 1 downto 0);
       data_i    : in  std_logic_vector(PsiFixSize(fmt_g) - 1 downto 0);
       str_i     : in  std_logic;
       str_o     : out std_logic;
       min_o     : out std_logic;
       max_o     : out std_logic);
end entity;

architecture rtl of psi_fix_comparator is
  --internal signals
  signal data_s, set_min_s, set_max_s : std_logic_vector(data_i'range);
  signal str_s, str1_s                : std_logic;
  signal min_s, max_s                 : std_logic;
begin

  proc_comp : process(clk_i)
  begin
    if rising_edge(clk_i) then
     --*** rst ***
      if rst_i = rst_pol_g then
         str_s  <= '0';
         str_o  <= '0';
         data_s <= (others => '0');
      end if;
      --*** gating input ***
      data_s    <= data_i;
      set_min_s <= set_min_i;
      set_max_s <= set_max_i;
      --*** sr manual ***
      str_s     <= str_i;
      str1_s    <= str_s;
      str_o     <= str1_s;

      if str_s = '1' then
        --*** comparison > ***
        if PsiFixCompare("a>b", data_s, fmt_g, set_max_s, fmt_g) then
          max_s <= '1';
        else
          max_s <= '0';
        end if;

        --*** comparison < ***
        if PsiFixCompare("a<b", data_s, fmt_g, set_min_s, fmt_g) then
          min_s <= '1';
        else
          min_s <= '0';
        end if;

        --***align output strobe to comparison values **
        if str1_s = '1' then
          min_o <= min_s;
          max_o <= max_s;
        else
          min_o <= '0';
          max_o <= '0';
        end if;       
      end if;
    end if;
  end process;

end architecture;
