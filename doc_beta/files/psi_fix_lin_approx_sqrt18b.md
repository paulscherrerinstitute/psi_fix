<img align="right" src="../../doc/psi_logo.png">
***

# psi_fix_lin_approx_sqrt18b
 - VHDL source: [psi_fix_lin_approx_sqrt18b](../../hdl/psi_fix_lin_approx_sqrt18b.vhd)
 - Testbench source: [psi_fix_lin_approx_sqrt18b_tb.vhd](../../testbench/psi_fix_lin_approx_sqrt18b_tb/psi_fix_lin_approx_sqrt18b_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name   | type   | Description   |
|--------|--------|---------------|

### Interfaces
| Name   | In/Out   | Length   | Description                   |
|:-------|:---------|:---------|:------------------------------|
| clk_i  | i        | 1        | system clock                  |
| rst_i  | i        | 1        | system reset                  |
| dat_i  | i        | 0,       | data in format (0, 0, 20)     |
| vld_i  | i        | 1        | valid input                   |
| dat_o  | o        | 0,       | data output format (0, 0, 17) |
| vld_o  | o        | 1        | valid output                  |