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

entity psi_fix_ss_solver_tb is
    generic (
        FileFolder_g    : string    := "../testbench/psi_fix_ss_solver_tb/data";
        DutyCycle_g     : integer   := 6
    );
end psi_fix_ss_solver_tb;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture sim of psi_fix_ss_solver_tb is


    -- CONSTANT
    ---------------

    constant RstPol_g   : std_logic     := '1';

    constant InFmt_g    : PsiFixFmt_t   := (1, 0, 15);
    constant OutFmt_g   : PsiFixFmt_t   := (1, 29, 2);

    constant IntFmt_g   : PsiFixFmt_t   := (1, 29, 2);
    constant CoefAFmt_g : PsiFixFmt_t   := (1, 0, 31);
    constant CoefBFmt_g : PsiFixFmt_t   := (1, 29, 2);

    constant Order_g    : positive      := 2;

    constant matA_N_c   : positive      := 2;
    constant matA_M_c   : positive      := 2;

    constant matB_N_c   : positive      := 1;
    constant matB_M_c   : positive      := 1;

    -- SIGNAL
    ---------------

    -- Testbench control signals
    signal running   :   boolean        := True;
    signal done      :   std_logic      := '0';

    -- Input signals
    signal clk_i     :  std_logic := '0';
    signal rst_i     :  std_logic := '1';
    signal strb_i    :  std_logic := '0';

    signal data_i    :  std_logic_vector( Order_g*PsiFixSize(InFmt_g)-1 downto 0 )         := (others => '0');

    signal coeff_A_i :  std_logic_vector( (Order_g**2)*PsiFixSize(CoefAFmt_g)-1 downto 0 ) := (others => '0');
    signal coeff_B_i :  std_logic_vector( PsiFixSize(CoefBFmt_g)-1 downto 0 )              := (others => '0');

    signal strb_s    :  std_logic;
    signal data_s    :  std_logic_vector( Order_g*PsiFixSize(OutFmt_g)-1 downto 0 );

    signal sig_in    :  TextfileData_t(0 to 6) := (others => 0);

    -- Check porpose signals

    signal sig_out   :  TextfileData_t(0 to 1) := (others => 0);

begin

    ------------------------------------------------------------
    -- Testbench Control !DO NOT EDIT!
    ------------------------------------------------------------
    p_tb_ctrl : process
    begin
        wait until rst_i = '0';
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

    g_datI : for i in 0 to (Order_g-1) generate
        data_i((i+1)*PsiFixSize(InFmt_g)-1 downto i*PsiFixSize(InFmt_g)) <= std_logic_vector(to_signed(sig_in(i), PsiFixSize(InFmt_g)));        
    end generate;

    g_datA : for i in 0 to ((matA_N_c*matA_M_c)-1) generate
        coeff_A_i((i+1)*PsiFixSize(CoefAFmt_g)-1 downto i*PsiFixSize(CoefAFmt_g)) <= std_logic_vector(to_signed(sig_in(i+Order_g), PsiFixSize(CoefAFmt_g)));        
    end generate;


    g_datB : for i in 0 to ((matB_N_c*matB_M_c)-1) generate
        coeff_B_i((i+1)*PsiFixSize(CoefBFmt_g)-1 downto i*PsiFixSize(CoefBFmt_g)) <= std_logic_vector(to_signed(sig_in((matA_N_c*matA_M_c)+i+Order_g), PsiFixSize(CoefBFmt_g)));        
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
                                Filepath    => FileFolder_g & "/input.txt", 
                                ClkPerSpl   => DutyCycle_g,
                                IgnoreLines => 1);
        wait;
    end process;

    ------------------------------------------------------------
    -- Check processes
    ------------------------------------------------------------

    g_datO : for i in 0 to (Order_g-1) generate
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
                                Filepath    => FileFolder_g & "/output.txt",
                                ClkPerSpl   => DutyCycle_g,
                                IgnoreLines => 1);
        
        -- end of process !DO NOT EDIT!
        done <= '1';
        wait;
    end process;

    ------------------------------------------------------------
    -- Design under test
    ------------------------------------------------------------

    u_dut : entity work.psi_fix_ss_solver
    generic map(
        RstPol_g   => RstPol_g,
        InFmt_g    => InFmt_g,

        CoefAFmt_g => CoefAFmt_g,
        CoefBFmt_g => CoefBFmt_g,

        OutFmt_g   => OutFmt_g,
        IntFmt_g   => IntFmt_g,
        Order_g    => Order_g

    )
    port map(
        rst_i     => rst_i,
        clk_i     => clk_i,
        strb_i    => strb_i,

        data_i    => data_i,

        coeff_A_i => coeff_A_i,
        coeff_B_i => coeff_B_i,

        strb_o    => strb_s,
        data_o    => data_s
    );

end sim;