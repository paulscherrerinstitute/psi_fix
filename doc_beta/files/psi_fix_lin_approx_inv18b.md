<img align="right" src="../../doc/psi_logo.png">
***

# psi_fix_lin_approx_inv18b
 - VHDL source: [psi_fix_lin_approx_inv18b](../../hdl/psi_fix_lin_approx_inv18b.vhd)
 - Testbench source: [psi_fix_lin_approx_inv18b_tb.vhd](../../testbench/psi_fix_lin_approx_inv18b_tb/psi_fix_lin_approx_inv18b_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name   | type   | Description   |
|--------|--------|---------------|

### Interfaces
| Name   | In/Out   | Length   | Description       |
|:-------|:---------|:---------|:------------------|
| clk_i  | i        | 1        | system clock      |
| rst_i  | i        | 1        | system reset      |
| dat_i  | i        | 0,       | format (0, 1, 18) |
| vld_i  | i        | 1        | valid input       |
| dat_o  | o        | 0,       | format (0, 0, 18) |
| vld_o  | o        | 1        | valid output      |