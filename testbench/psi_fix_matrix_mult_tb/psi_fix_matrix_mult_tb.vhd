----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Description: 
----------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library work;
    use work.psi_common_math_pkg.all;
    use work.psi_tb_textfile_pkg.all;
    use work.psi_fix_pkg.all;

----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------

entity psi_fix_matrix_mult_tb is
    generic (
        FileFolder_g    : string    := "../testbench/psi_fix_matrix_mult_tb/data/";
        FileIn_g        : string    := "input_2x2_2x2.txt";
        FileOut_g       : string    := "output_2x2_2x2.txt";
        DutyCycle_g     : integer   := 1;

        matA_N_g        : positive  := 2;           -- Number of rows on matrix A 
        matA_M_g        : positive  := 2;           -- Number of columns on matrix A

        matB_N_g        : positive  := 2;           -- Number of rows on matrix B
        matB_M_g        : positive  := 2            -- Number of columns on matrix B
    );
end psi_fix_matrix_mult_tb;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture sim of psi_fix_matrix_mult_tb is


    -- CONSTANT
    ---------------

    constant RstPol_g   : std_logic     := '1';

    constant InFmt_g    : PsiFixFmt_t   := (1,0,15);
    constant OutFmt_g   : PsiFixFmt_t   := (1,0,16);
    constant IntFmt_g   : PsiFixFmt_t   := (1, 1, 30);

    -- SIGNAL
    ---------------

    -- Testbench control signals
    signal running   :   boolean        := True;
    signal input_rd  :   std_logic      := '0';
    signal done      :   std_logic      := '0';

    -- Input signals
    signal clk_i     :  std_logic := '0';
    signal rst_i     :  std_logic := '1';
    signal strb_i    :  std_logic := '0';


    signal data_A_i  :  std_logic_vector( (matA_N_g*matA_M_g*PsiFixSize(InFmt_g)) - 1 downto 0 ) := (others => '0');
    signal data_B_i  :  std_logic_vector( (matB_N_g*matB_M_g*PsiFixSize(InFmt_g)) - 1 downto 0 ) := (others => '0');


    signal strb_s    :  std_logic;

    signal data_s    :  std_logic_vector( (matA_N_g*matB_M_g*PsiFixSize(OutFmt_g))-1 downto 0 ) := (others => '0');

    signal sig_in    :  TextfileData_t(0 to (matA_N_g*matA_M_g)+(matB_N_g*matB_M_g) - 1) := (others => 0);

    -- Check porpose signals
    signal sig_out   :   TextfileData_t(0 to (matA_N_g*matB_M_g) - 1) := (others => 0);

begin

    ------------------------------------------------------------
    -- Testbench Control !DO NOT EDIT!
    ------------------------------------------------------------
    p_tb_ctrl : process
    begin
        wait until rst_i = '0';
        wait until input_rd = '1';
        wait until done = '1';

        running <= false;

        wait;
    end process;
    
    ------------------------------------------------------------
    -- Clocks !DO NOT EDIT!
    ------------------------------------------------------------
    p_clk : process
        constant Frequency_c : real := real(100e6);
    begin
        while running loop
            wait for 0.5*(1 sec)/Frequency_c;
            clk_i <= not clk_i;
        end loop;
        wait;
    end process;

    ------------------------------------------------------------
    -- Resets
    ------------------------------------------------------------
    p_rst : process
    begin
        wait for 1 us;
        -- Wait for two clk edges to ensure reset is active for at least one edge
        wait until rising_edge(clk_i);
        wait until rising_edge(clk_i);
        rst_i <= '0';
        wait;
    end process;

    ------------------------------------------------------------
    -- Stimuli processes
    ------------------------------------------------------------

    g_datA : for i in 0 to ((matA_N_g*matA_M_g)-1) generate
        data_A_i((i+1)*PsiFixSize(InFmt_g)-1 downto i*PsiFixSize(InFmt_g)) <= std_logic_vector(to_signed(sig_in(i), PsiFixSize(InFmt_g)));        
    end generate;

    g_datB : for i in 0 to ((matB_N_g*matB_M_g)-1) generate
        data_B_i((i+1)*PsiFixSize(InFmt_g)-1 downto i*PsiFixSize(InFmt_g)) <= std_logic_vector(to_signed(sig_in((matA_N_g*matA_M_g)+i), PsiFixSize(InFmt_g)));        
    end generate;

    p_stim : process
    begin
        -- start of process !DO NOT EDIT
        wait until rst_i = '0';
        
        -- Apply Stimuli    
        ApplyTextfileContent(   Clk         => clk_i, 
                                Rdy         => PsiTextfile_SigOne,
                                Vld         => strb_i, 
                                Data        => sig_in, 
                                Filepath    => FileFolder_g & FileIn_g, 
                                ClkPerSpl   => DutyCycle_g,
                                IgnoreLines => 1);
        input_rd <= '1';
        wait;
    end process;

    ------------------------------------------------------------
    -- Check processes
    ------------------------------------------------------------

    g_datO : for i in 0 to ((matA_N_g*matB_M_g)-1) generate
        sig_out(i) <= to_integer( signed( data_s((i+1)*PsiFixSize(OutFmt_g)-1 downto i*PsiFixSize(OutFmt_g)) ));   
    end generate;

    p_chk : process
    begin
        -- start of process !DO NOT EDIT
        wait until rst_i = '0';

        -- Check DUT's output
        CheckTextfileContent(   Clk         => clk_i,
                                Rdy         => PsiTextfile_SigUnused,
                                Vld         => strb_s,
                                Data        => sig_out,
                                Filepath    => FileFolder_g & FileOut_g,
                                IgnoreLines => 1);
        
        -- end of process !DO NOT EDIT!
        done <= '1';
        wait;
    end process;

    ------------------------------------------------------------
    -- Design under test
    ------------------------------------------------------------

    u_dut : entity work.psi_fix_matrix_mult
    generic map(
        RstPol_g   => RstPol_g,
        InFmt_g    => InFmt_g,
        OutFmt_g   => OutFmt_g,
        IntFmt_g   => IntFmt_g,

        matA_N_g   => matA_N_g,
        matA_M_g   => matA_M_g,

        matB_N_g  => matB_N_g,
        matB_M_g  => matB_M_g
    )
    port map(
        rst_i     => rst_i,
        clk_i     => clk_i,
        strb_i    => strb_i,

        data_A_i  => data_A_i,
        data_B_i  => data_B_i,

        strb_o    => strb_s,
        data_o    => data_s
    );

end sim;