<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_white_noise
 - VHDL source: [psi_fix_white_noise](../hdl/psi_fix_white_noise.vhd)
 - Testbench source: [psi_fix_white_noise_tb.vhd](../testbench/psi_fix_white_noise_tb/psi_fix_white_noise_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name               | type          | Description   |
|:-------------------|:--------------|:--------------|
| generic( out_fmt_g | psi_fix_fmt_t | N.A           |
| seed_g             | unsigned(31   | N.A           |
| rst_pol_g          | std_logic     | N.A           |

### Interfaces
| Name   | In/Out   | Length     | Description   |
|:-------|:---------|:-----------|:--------------|
| clk_i  | i        | 1          | N.A           |
| rst_i  | i        | 1          | N.A           |
| vld_o  | o        | 1          | N.A           |
| dat_o  | o        | out_fmt_g) | N.A           |