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
	generic(rst_pol_g 	: std_logic   := '1';
			rom_stlye_g : string := "block"	);
	port(
		-- Control Signals
		InClk   : in  std_logic;
		InRst   : in  std_logic;
		-- Input
		InRdAdd : in  std_logic_vector(log2ceil(<SIZE>) - 1 downto 0);
		InRdEna : in  std_logic;
		-- Output
		OutDat  : out std_logic_vector(PsiFixSize(<OUT_FMT>) - 1 downto 0)
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of <ENTITY_NAME> is       
	-- Constants
	constant out_fmt_c   : integer := PsiFixSize(<OUT_FMT>);
	-- Table
	type table_t is array (0 to <SIZE> - 1) of std_logic_vector(out_fmt_c - 1 downto 0);
	constant table_c     : table_t := (
		<TABLE_CONTENT>); 
	signal  temp_s       : std_logic_vector(out_fmt_c - 1 downto 0); 
	--
	attribute rom_style : string;
	attribute rom_style of temp_s : signal is rom_stlye_g;
begin
	
	temp_s <= table_c(to_integer(unsigned(InRdAdd)));
	
	-- *** Table ***
	p_table : process(InClk)
	begin
		if rising_edge(InClk) then
			if InRst = rst_pol_g then
				OutDat <= (others => '0');
			else
				if InRdEna = '1' then
					OutDat <= temp_s;
				end if;
			end if;
		end if;
	end process;

end architecture;
