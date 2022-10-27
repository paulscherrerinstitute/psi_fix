------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
--This basic block allows set min and max threshold in fixed point format fashion
--prior to deliver flag indications output - not that generic but convenient in some cases 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_fix_pkg.all;

entity psi_fix_comparator is
  generic(
      fmt_g     : psi_fix_fmt_t := (1, 0, 15);                         -- format fixed for all
      rst_pol_g : std_logic   := '1'                                   -- reset polarity active high ='1'
      );                              
  port(
      clk_i     : in  std_logic;                                       -- clk input
      rst_i     : in  std_logic;                                       -- rst input
      set_min_i : in  std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0);-- min threshold
      set_max_i : in  std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0);-- max threshold
      data_i    : in  std_logic_vector(psi_fix_size(fmt_g) - 1 downto 0);-- data input 
      vld_i     : in  std_logic;                                       -- valid input signal
      vld_o     : out std_logic;                                       -- valid signal output
      min_o     : out std_logic;                                       -- minimum flag output
      max_o     : out std_logic                                        -- maximum fag output
     );
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
         vld_o  <= '0';
         data_s <= (others => '0');
      end if;
      --*** gating input ***
      data_s    <= data_i;
      set_min_s <= set_min_i;
      set_max_s <= set_max_i;
      --*** sr manual ***
      str_s     <= vld_i;
      str1_s    <= str_s;
      vld_o     <= str1_s;

      if str_s = '1' then
        --*** comparison > ***
        if psi_fix_compare("a>b", data_s, fmt_g, set_max_s, fmt_g) then
          max_s <= '1';
        else
          max_s <= '0';
        end if;

        --*** comparison < ***
        if psi_fix_compare("a<b", data_s, fmt_g, set_min_s, fmt_g) then
          min_s <= '1';
        else
          min_s <= '0';
        end if;

       
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
  end process;

end architecture;
