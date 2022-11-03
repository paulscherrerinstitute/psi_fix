<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_lin_approx_sin18b_dual
 - VHDL source: [psi_fix_lin_approx_sin18b_dual](../hdl/psi_fix_lin_approx_sin18b_dual.vhd)
 - Testbench source: [psi_fix_lin_approx_sin18b_dual_tb.vhd](../testbench/psi_fix_lin_approx_sin18b_dual_tb/psi_fix_lin_approx_sin18b_dual_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description   |
|:------------------|:----------|:--------------|
| generic(rst_pol_g | std_logic | N.A           |

### Interfaces
| Name    | In/Out   | Length   | Description                            |
|:--------|:---------|:---------|:---------------------------------------|
| clk_i   | i        | 1        | system clock                           |
| rst_i   | i        | 1        | system reset                           |
| dat_a_i | i        | 0,       | data a input a fixed format (0, 0, 20) |
| vld_a_i | i        | 1        | valid input data a                     |
| dat_b_i | i        | 0,       | data b input fixed format (0, 0, 20)   |
| vld_b_i | i        | 1        | data b valid input data b              |
| dat_a_o | o        | 1,       | data a out fixed format (1, 0, 17)     |
| vld_a_o | o        | 1        | valid output data a                    |
| dat_b_o | o        | 1,       | data b out fixed format (1, 0, 17)     |
| vld_b_o | o        | 1        | valid output data b                    |