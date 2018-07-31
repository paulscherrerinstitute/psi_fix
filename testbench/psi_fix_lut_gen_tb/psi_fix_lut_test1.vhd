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
entity psi_fix_lut_test1 is
	generic(
		rst_pol_g : std_logic   := '1';		-- CFG 1
		size_g    : natural     := 61; 			-- Format 61;
		out_fmt_g : PsiFixFmt_t := (1, 0, 15) 		-- Format (1, 0, 15)
	);
	port(
		-- Control Signals
		clk_i  : in  std_logic;
		rst_i  : in  std_logic;
		-- Input
		radd_i : in  std_logic_vector(log2ceil(size_g) - 1 downto 0);
		rena_i : in  std_logic;
		-- Output
		data_o : out std_logic_vector(PsiFixSize(out_fmt_g) - 1 downto 0)
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_fix_lut_test1 is
	-- Constants
	constant out_fmt_c   : integer := PsiFixSize(out_fmt_g);
	-- Table
	type table_t is array (0 to size_g - 1) of std_logic_vector(out_fmt_c - 1 downto 0);
	constant table_c     : table_t := (
		std_logic_vector(to_signed(0,16)),
		std_logic_vector(to_signed(24,16)),
		std_logic_vector(to_signed(32,16)),
		std_logic_vector(to_signed(12,16)),
		std_logic_vector(to_signed(-28,16)),
		std_logic_vector(to_signed(-59,16)),
		std_logic_vector(to_signed(-43,16)),
		std_logic_vector(to_signed(28,16)),
		std_logic_vector(to_signed(105,16)),
		std_logic_vector(to_signed(108,16)),
		std_logic_vector(to_signed(0,16)),
		std_logic_vector(to_signed(-156,16)),
		std_logic_vector(to_signed(-219,16)),
		std_logic_vector(to_signed(-84,16)),
		std_logic_vector(to_signed(188,16)),
		std_logic_vector(to_signed(375,16)),
		std_logic_vector(to_signed(257,16)),
		std_logic_vector(to_signed(-157,16)),
		std_logic_vector(to_signed(-563,16)),
		std_logic_vector(to_signed(-557,16)),
		std_logic_vector(to_signed(0,16)),
		std_logic_vector(to_signed(759,16)),
		std_logic_vector(to_signed(1050,16)),
		std_logic_vector(to_signed(405,16)),
		std_logic_vector(to_signed(-931,16)),
		std_logic_vector(to_signed(-1955,16)),
		std_logic_vector(to_signed(-1469,16)),
		std_logic_vector(to_signed(1049,16)),
		std_logic_vector(to_signed(4903,16)),
		std_logic_vector(to_signed(8404,16)),
		std_logic_vector(to_signed(9815,16)),
		std_logic_vector(to_signed(8404,16)),
		std_logic_vector(to_signed(4903,16)),
		std_logic_vector(to_signed(1049,16)),
		std_logic_vector(to_signed(-1469,16)),
		std_logic_vector(to_signed(-1955,16)),
		std_logic_vector(to_signed(-931,16)),
		std_logic_vector(to_signed(405,16)),
		std_logic_vector(to_signed(1050,16)),
		std_logic_vector(to_signed(759,16)),
		std_logic_vector(to_signed(0,16)),
		std_logic_vector(to_signed(-557,16)),
		std_logic_vector(to_signed(-563,16)),
		std_logic_vector(to_signed(-157,16)),
		std_logic_vector(to_signed(257,16)),
		std_logic_vector(to_signed(375,16)),
		std_logic_vector(to_signed(188,16)),
		std_logic_vector(to_signed(-84,16)),
		std_logic_vector(to_signed(-219,16)),
		std_logic_vector(to_signed(-156,16)),
		std_logic_vector(to_signed(0,16)),
		std_logic_vector(to_signed(108,16)),
		std_logic_vector(to_signed(105,16)),
		std_logic_vector(to_signed(28,16)),
		std_logic_vector(to_signed(-43,16)),
		std_logic_vector(to_signed(-59,16)),
		std_logic_vector(to_signed(-28,16)),
		std_logic_vector(to_signed(12,16)),
		std_logic_vector(to_signed(32,16)),
		std_logic_vector(to_signed(24,16)),
		std_logic_vector(to_signed(0,16)));
	signal  temp_s       : std_logic_vector(out_fmt_c - 1 downto 0);
	--
	attribute rom_style : string;
	attribute rom_style of temp_s : signal is "block";
begin

	temp_s <= table_c(to_integer(unsigned(radd_i)));

	-- *** Table ***
	p_table : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = rst_pol_g then
				data_o <= (others => '0');
			else
				if rena_i = '1' then
					data_o <= temp_s;
				end if;
			end if;
		end if;
	end process;

end architecture;
