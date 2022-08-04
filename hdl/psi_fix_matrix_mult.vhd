----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Description: 
----------------------------------------------------------------------------------
-- A generic matrices multiplier, pipeline based. Receives as input two matrices 
-- A and B and gives the output of the following multiplicatgion A * B = C.
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

entity psi_fix_matrix_mult is
    generic( RstPol_g   : std_logic     := '1';         -- Reset polarity

             InFmt_g    : PsiFixFmt_t   := (1, 0, 15);  -- Input data format
             OutFmt_g   : PsiFixFmt_t   := (1, 0, 16);  -- Output data format
             IntFmt_g   : PsiFixFmt_t   := (1, 1, 30);  -- Internal data format

             matA_N_g   : positive      := 2;           -- Number of rows on matrix A 
             matA_M_g   : positive      := 2;           -- Number of columns on matrix A

             matB_N_g   : positive      := 2;           -- Number of rows on matrix B
             matB_M_g   : positive      := 2            -- Number of columns on matrix B
    );

    port( rst_i     : in    std_logic;                                                                  -- Input reset
          clk_i     : in    std_logic;                                                                  -- Input clock
          strb_i    : in    std_logic;                                                                  -- Input strobe

          data_A_i  : in    std_logic_vector( (matA_N_g*matA_M_g*PsiFixSize(InFmt_g)) - 1 downto 0 );   -- Input data matrix A 
          data_B_i  : in    std_logic_vector( (matB_N_g*matB_M_g*PsiFixSize(InFmt_g)) - 1 downto 0 );   -- Input data matrix B

          strb_o    : out   std_logic;                                                                  -- Output strobe
          data_o    : out   std_logic_vector( (matA_N_g*matB_M_g*PsiFixSize(OutFmt_g)) - 1 downto 0 )   -- Output data [A * B] matrix
    );
end psi_fix_matrix_mult;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture behavioral of psi_fix_matrix_mult is

    -- TYPE
    ---------------

    type data_matrix_t is array(natural range<>, natural range<>) of std_logic_vector;

    type arry_matrix_t is array(natural range<>) of data_matrix_t;

    type two_process_r is record
        -- Registers always present
        strb     :   std_logic_vector(4 downto 0);

        matA_s   :   data_matrix_t(0 to (matA_N_g-1), 0 to (matA_M_g-1)) (PsiFixSize(InFmt_g) - 1 downto 0);
        matB_s   :   data_matrix_t(0 to (matB_N_g-1), 0 to (matB_M_g-1)) (PsiFixSize(InFmt_g) - 1 downto 0);

        mult_s   :   arry_matrix_t(0 to (matB_M_g-1))(0 to (matA_N_g-1), 0 to (matA_M_g-1)) (PsiFixSize(IntFmt_g) - 1 downto 0);

        add_s    :   data_matrix_t(0 to (matB_N_g-1), 0 to (matB_M_g-1)) (PsiFixSize(IntFmt_g) - 1 downto 0);

        data_s   :   std_logic_vector( (matA_N_g*matB_M_g*PsiFixSize(OutFmt_g)) - 1 downto 0 );

    end record;

    -- SIGNAL
    ---------------

    signal r, r_next    : two_process_r;

begin

    assert (matA_M_g = matB_N_g) report "###ERROR###: psi_fix_matrix_mult: Matrices have incompatible dimensions" severity error;

    --------------------------------------------------------------------------
    -- Combinatorial Process
    --------------------------------------------------------------------------

    p_comb : process(r, strb_i, data_A_i, data_B_i)
        variable tmp : std_logic_vector(PsiFixSize(IntFmt_g) - 1 downto 0);
    begin

        r_next.strb(0) <= strb_i;

        -- stage 0
        -- Hold signals stable
        ------------------------------------------------------------
        for i in 0 to (matA_N_g - 1) loop
            for j in 0 to (matA_M_g - 1) loop
                r_next.matA_s(i, j) <= data_A_i( (((i*matA_M_g)+j+1)*PsiFixSize(InFmt_g))-1 downto (((i*matA_M_g)+j)*PsiFixSize(InFmt_g)) );
            end loop;
        end loop;

        for i in 0 to (matB_N_g - 1) loop
            for j in 0 to (matB_M_g - 1) loop
                r_next.matB_s(i, j) <= data_B_i( (((i*matB_M_g)+j+1)*PsiFixSize(InFmt_g))-1 downto (((i*matB_M_g)+j)*PsiFixSize(InFmt_g)) );
            end loop;
        end loop;

        -- stage 1
        -- Multiplication
        ------------------------------------------------------------
        for i in 0 to (matB_M_g - 1) loop
            for j in 0 to (matA_N_g - 1) loop
                for k in 0 to (matA_M_g - 1) loop
                        r_next.mult_s(i)(j, k) <= PsiFixMult(r.matA_s(j, k), InFmt_g, r.matB_s(k, i), InFmt_g, IntFmt_g, PsiFixTrunc, PsiFixWrap);
                end loop;    
            end loop;
        end loop;


        -- stage 2
        -- Addition
        ------------------------------------------------------------

        for i in 0 to (matB_M_g - 1) loop
            for j in 0 to (matA_N_g - 1) loop
                tmp := (others => '0');
                for k in 0 to (matA_M_g - 1) loop
                        tmp := PsiFixAdd(tmp, IntFmt_g, r.mult_s(i)(j, k), IntFmt_g, IntFmt_g, PsiFixTrunc, PsiFixWrap);
                end loop;
                r_next.add_s(j, i) <= tmp;
            end loop;
        end loop;

        -- stage 3
        -- Hold output signal stable
        ------------------------------------------------------------

        for i in 0 to (matA_N_g - 1) loop
            for j in 0 to (matB_M_g - 1) loop
                    r_next.data_s( (((i*matB_M_g)+j+1)*PsiFixSize(OutFmt_g))-1 downto (((i*matB_M_g)+j)*PsiFixSize(OutFmt_g)) ) <= PsiFixResize(r.add_s(i, j), IntFmt_g, OutFmt_g, PsiFixTrunc, PsiFixWrap);
            end loop;
        end loop;

        r_next.strb(r_next.strb'high downto 1) <= r.strb(r.strb'high-1 downto 0);

    end process p_comb;

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------

    strb_o <= r.strb(r.strb'high-1);
    data_o <= r.data_s;

    --------------------------------------------------------------------------
    -- Sequential Process
    --------------------------------------------------------------------------

    p_seq : process(rst_i, clk_i)
    begin
        if(rising_edge(clk_i)) then
            if(rst_i = RstPol_g) then

                r.strb   <= (others => '0');
                r.matA_s <= (others => (others => (others => '0')));
                r.matB_s <= (others => (others => (others => '0')));
                r.mult_s <= (others => (others => (others => (others => '0'))));
                r.add_s  <= (others => (others => (others => '0')));
                r.data_s <= (others => '0');

                r.data_s <= (others => '0');
            else
                if(r_next.strb /= "00000") then
                    r <= r_next;
                end if;
            end if;
        end if;
    end process p_seq;  

end behavioral;