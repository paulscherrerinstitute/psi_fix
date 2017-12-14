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
		Clk			: in 	std_logic;
		Rst			: in 	std_logic;
		-- Input
		InVld		: in	std_logic;
		InData		: in	std_logic_vector(<IN_WIDTH>-1 downto 0);		-- Format <IN_FMT>
		-- Output
		OutVld		: out	std_logic;
		OutData		: out	std_logic_vector(<OUT_WIDTH>-1 downto 0)		-- Format <OUT_FMT>
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of <ENTITY_NAME> is

	-- Constants
	constant InFmt_c		: PsiFixFmt_t		:= <IN_FMT>;
	constant OutFmt_c		: PsiFixFmt_t		:= <OUT_FMT>;
	constant OffsFmt_c		: PsiFixFmt_t		:= <OFFS_FMT>;
	constant GradFmt_c		: PsiFixFmt_t		:= <GRAD_FMT>;
	constant TableSize_c	: integer			:= <TABLE_SIZE>;
	constant TableWidth_c	: integer			:= <TABLE_WIDTH>;
	
	-- Table
	
	type Table_t is array(0 to TableSize_c-1) of std_logic_vector(TableWidth_c-1 downto 0);
	constant Table_c : Table_t := (
<TABLE_CONTENT>
	);
	
	-- Signals
	signal TableAddr	: std_logic_vector(log2ceil(TableSize_c)-1 downto 0);
	signal TableData	: std_logic_vector(TableWidth_c-1 downto 0);
	
begin

	-- *** Calculation Unit ***
	i_calc : entity work.psi_fix_lin_approx_calc
		generic map (
			InFmt_g			=> InFmt_c,
			OutFmt_g		=> OutFmt_c,
			OffsFmt_g		=> OffsFmt_c,
			GradFmt_g		=> GradFmt_c,
			TableSize_g		=> TableSize_c
		)
		port map (
			-- Control Signals
			Clk			=> Clk,
			Rst			=> Rst,
			-- Input
			InVld		=> InVld,
			InData		=> InData,
			-- Output
			OutVld		=> OutVld,
			OutData		=> OutData,
			-- Table Interface
			TblAddr		=> TableAddr,
			TblData		=> TableData
		);
		
	-- *** Table ***
	p_table : process(Clk)
	begin
		if rising_edge(Clk) then
			TableData <= Table_c(to_integer(unsigned(TableAddr)));
		end if;
	end process;
	

end rtl;