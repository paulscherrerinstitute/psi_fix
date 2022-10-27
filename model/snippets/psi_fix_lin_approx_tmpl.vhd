------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
library work;
use work.psi_fix_pkg.all;
use work.psi_common_math_pkg.all;
  
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity <ENTITY_NAME> is
  port (
    -- Control Signals
    clk_i      : in   std_logic;
    rst_i      : in   std_logic;
    -- Input
    vld_i    : in  std_logic;
    dat_i   : in  std_logic_vector(<IN_WIDTH>-1 downto 0);    -- Format <IN_FMT>
    -- Output
    vld_o   : out  std_logic;
    dat_o  : out  std_logic_vector(<OUT_WIDTH>-1 downto 0)    -- Format <OUT_FMT>
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of <ENTITY_NAME> is

  -- Constants
  constant InFmt_c    : psi_fix_fmt_t    := <IN_FMT>;
  constant OutFmt_c    : psi_fix_fmt_t    := <OUT_FMT>;
  constant OffsFmt_c    : psi_fix_fmt_t    := <OFFS_FMT>;
  constant GradFmt_c    : psi_fix_fmt_t    := <GRAD_FMT>;
  constant TableSize_c  : integer      := <TABLE_SIZE>;
  constant TableWidth_c  : integer      := <TABLE_WIDTH>;
  
  -- Table
  
  type Table_t is array(0 to TableSize_c-1) of std_logic_vector(TableWidth_c-1 downto 0);
  constant Table_c : Table_t := (
<TABLE_CONTENT>
  );
  
  -- Signals
  signal TableAddr  : std_logic_vector(log2ceil(TableSize_c)-1 downto 0);
  signal TableData  : std_logic_vector(TableWidth_c-1 downto 0);
  
begin

  -- *** Calculation Unit ***
  i_calc : entity work.psi_fix_lin_approx_calc
    generic map (
      in_fmt_g      => InFmt_c,
      out_fmt_g    => OutFmt_c,
      offs_fmt_g    => OffsFmt_c,
      grad_fmt_g    => GradFmt_c,
      table_size_g    => TableSize_c
    )
    port map (
      -- Control Signals
      clk_i      => clk_i,
      rst_i      => rst_i,
      -- Input
      vld_i    => vld_i,
      dat_i    => dat_i,
      -- Output
      vld_o    => vld_o,
      dat_o    => dat_o,
      -- Table Interface
      addr_table_o    => TableAddr,
      data_table_i    => TableData
    );
    
  -- *** Table ***
  p_table : process(clk_i)
  begin
    if rising_edge(clk_i) then
      TableData <= Table_c(to_integer(unsigned(TableAddr)));
    end if;
  end process;
  

end rtl;
