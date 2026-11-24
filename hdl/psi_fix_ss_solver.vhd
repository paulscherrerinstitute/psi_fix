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
    use work.psi_fix_pkg.all;
    use work.psi_common_math_pkg.all;

----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------

entity psi_fix_ss_solver is
    generic( RstPol_g   : std_logic     := '1';         --  Reset polarity 

             InFmt_g    : PsiFixFmt_t   := (1, 0, 15);  --  Input fix point format 
             OutFmt_g   : PsiFixFmt_t   := (1, 29, 2);  --  Output fix point formar 
             IntFmt_g   : PsiFixFmt_t   := (1, 29, 2);  --  Internal fix point format 

             CoefAFmt_g : PsiFixFmt_t   := (1, 0, 31);  --  Coefficient matrix A fix point format 
             CoefBFmt_g : PsiFixFmt_t   := (1, 29, 2);  --  Coefficient matrix B fix point format 

             Order_g    : positive      := 2            --  State space system order 
    );

    port( rst_i     : in    std_logic;                                                              -- Input reset
          clk_i     : in    std_logic;                                                              -- Input clock
          strb_i    : in    std_logic;                                                              -- Inpput strobe

          data_i    : in    std_logic_vector( Order_g*PsiFixSize(InFmt_g) - 1 downto 0 );           -- Input data

          coeff_A_i : in    std_logic_vector( ((Order_g**2)*PsiFixSize(CoefAFmt_g)) - 1 downto 0 );  -- Input A matrix coefficients data (an array of [(Order_g^2) - 1] elements with the CoefAFmt_g size)
          coeff_B_i : in    std_logic_vector( PsiFixSize(CoefBFmt_g) - 1 downto 0 );                 -- Input B matrix coefficients data (an array of [(Order_g) - 1] elements with the CoefBFmt_g size)

          strb_o    : out   std_logic;                                                               -- Output strobe
          data_o    : out   std_logic_vector( Order_g*PsiFixSize(OutFmt_g) - 1 downto 0 )            -- Output data
    );
end psi_fix_ss_solver;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture behavioral of psi_fix_ss_solver is

    -- TYPE
    ---------------

    -- Two process method
    type two_process_r is record
        -- Registers always present
        strb_s       :   std_logic_vector(3 downto 0);

        data_Ax_s    :   std_logic_vector( Order_g*PsiFixSize(IntFmt_g)-1 downto 0);
        data_Bu_s    :   std_logic_vector( Order_g*PsiFixSize(IntFmt_g)-1 downto 0);

        data_prev_s  :   std_logic_vector( Order_g*PsiFixSize(IntFmt_g)-1 downto 0 );

        data_out_s   :   std_logic_vector( Order_g*PsiFixSize(OutFmt_g)-1 downto 0 );
    end record;

    -- CONSTANT
    ---------------

    constant width_c : positive := Order_g*PsiFixSize(InFmt_g);

    -- SIGNAL
    ---------------
    signal r, r_next :  two_process_r;

    signal strb_A_s  :  std_logic;
    signal strb_B_s  :  std_logic;

    signal data_Ax_s :  std_logic_vector( Order_g*PsiFixSize(IntFmt_g) - 1 downto 0);
    signal data_Bu_s :  std_logic_vector( Order_g*PsiFixSize(IntFmt_g) - 1 downto 0);

    signal data_s    :  std_logic_vector( Order_g*PsiFixSize(InFmt_g) downto 0);

begin

    --------------------------------------------------------------------------
    -- Combinatorial Process
    --------------------------------------------------------------------------

    p_comb : process(r, strb_i, strb_A_s, strb_B_s, data_i, data_Ax_s, data_Bu_s)
    begin

        -- stage 0
        ------------------------------------------------------------    
        r_next.strb_s(0) <= strb_A_s and strb_B_s;

        r_next.data_Ax_s <= data_Ax_s;
        r_next.data_Bu_s <= data_Bu_s;


        -- stage 1
        ------------------------------------------------------------
        for i in 0 to (Order_g-1) loop
            r_next.data_prev_s((i+1)*PsiFixSize(IntFmt_g)-1 downto i*PsiFixSize(IntFmt_g)) <= PsiFixAdd(r.data_Ax_s((i+1)*PsiFixSize(IntFmt_g)-1 downto i*PsiFixSize(IntFmt_g)), IntFmt_g, 
                                                                                                        r.data_Bu_s((i+1)*PsiFixSize(IntFmt_g)-1 downto i*PsiFixSize(IntFmt_g)), IntFmt_g, 
                                                                                                        IntFmt_g, PsiFixTrunc, PsiFixWrap);
        end loop;

        -- stage 2
        ------------------------------------------------------------
        for i in 0 to (Order_g-1) loop
            r_next.data_out_s((i+1)*PsiFixSize(OutFmt_g)-1 downto i*PsiFixSize(OutFmt_g)) <= PsiFixResize(r.data_prev_s((i+1)*PsiFixSize(IntFmt_g)-1 downto i*PsiFixSize(IntFmt_g)), IntFmt_g, OutFmt_g, PsiFixTrunc, PsiFixWrap);
        end loop;
        
        r_next.strb_s(r_next.strb_s'high downto 1) <= r.strb_s(r.strb_s'high-1 downto 0);

    end process;

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------

    strb_o <= r.strb_s(2);
    data_o <= r.data_out_s;

    --------------------------------------------------------------------------
    -- Sequential Process
    --------------------------------------------------------------------------

    p_seq : process(rst_i, clk_i)
    begin
        if(rising_edge(clk_i)) then
            if(rst_i = RstPol_g) then
                r.strb_s        <= (others => '0');

                r.data_Ax_s     <= (others => '0');
                r.data_Bu_s     <= (others => '0');

                r.data_prev_s   <= (others => '0');

                r.data_out_s    <= (others => '0');
            else    
                if(r_next.strb_s /= "0000") then
                    r <= r_next;
                end if;
            end if; 
        end if;
    end process;

    --------------------------------------------------------------------------
    -- A Matrix Multiplier instantiation
    --------------------------------------------------------------------------

    u_mulA : entity work.psi_fix_matrix_mult
    generic map(
        RstPol_g   => RstPol_g,

        InAFmt_g   => CoefAFmt_g,
        InBFmt_g   => IntFmt_g,

        OutFmt_g   => IntFmt_g,
        IntFmt_g   => IntFmt_g,

        matA_N_g   => Order_g,
        matA_M_g   => Order_g,

        matB_N_g   => Order_g,
        matB_M_g   => 1
    )
    port map(
        rst_i     => rst_i,
        clk_i     => clk_i,
        strb_i    => strb_i,

        data_A_i  => coeff_A_i,
        data_B_i  => r.data_prev_s,

        strb_o    => strb_A_s,
        data_o    => data_Ax_s
    );

    --------------------------------------------------------------------------
    -- B Matrix Multiplier instantiation
    --------------------------------------------------------------------------

    u_mulB : entity work.psi_fix_matrix_mult
    generic map(
        RstPol_g   => RstPol_g,

        InAFmt_g   => InFmt_g,
        InBFmt_g   => CoefBFmt_g,

        OutFmt_g   => IntFmt_g,
        IntFmt_g   => IntFmt_g,

        matA_N_g   => Order_g,
        matA_M_g   => 1,

        matB_N_g   => 1,
        matB_M_g   => 1
    )
    port map(
        rst_i     => rst_i,
        clk_i     => clk_i,
        strb_i    => strb_i,

        data_A_i  => data_i,
        data_B_i  => coeff_B_i,

        strb_o    => strb_B_s,
        data_o    => data_Bu_s
    );

end behavioral;