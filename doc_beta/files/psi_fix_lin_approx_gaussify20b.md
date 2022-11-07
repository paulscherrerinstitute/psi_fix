<img align="right" src="../../doc/psi_logo.png">
***

# psi_fix_lin_approx_gaussify20b
 - VHDL source: [psi_fix_lin_approx_gaussify20b](../../hdl/psi_fix_lin_approx_gaussify20b.vhd)
 - Testbench source: [psi_fix_lin_approx_gaussify20b_tb.vhd](../../testbench/psi_fix_lin_approx_gaussify20b_tb/psi_fix_lin_approx_gaussify20b_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type      | Description   |
|:----------|:----------|:--------------|
| rst_pol_g | std_logic | N.A           |

### Interfaces
| Name   | In/Out   | Length   | Description       |
|:-------|:---------|:---------|:------------------|
| clk_i  | i        | 1        | N.A               |
| rst_i  | i        | 1        | N.A               |
| dat_i  | i        | 1,       | format (1, 0, 19) |
| vld_i  | i        | 1        | N.A               |
| dat_o  | o        | 1,       | format (1, 0, 19) |
| vld_o  | o        | 1        | N.A               |