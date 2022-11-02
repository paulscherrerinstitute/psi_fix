<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_noise_awgn
 - VHDL source: [psi_fix_noise_awgn](../hdl/psi_fix_noise_awgn.vhd)
 - Testbench source: [psi_fix_noise_awgn_tb.vhd](../testbench/psi_fix_noise_awgn_tb/psi_fix_noise_awgn_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type          | Description      |
|:----------|:--------------|:-----------------|
| out_fmt_g | psi_fix_fmt_t | output format fp |
| seed_g    | unsigned(31   | seed 32 bits     |
| rst_pol_g | std_logic     | reset polarity   |

### Interfaces
| Name   | In/Out   | Length     | Description   |
|:-------|:---------|:-----------|:--------------|
| clk_i  | i        | 1          | system clock  |
| rst_i  | i        | 1          | system reset  |
| dat_o  | o        | out_fmt_g) | output data   |
| vld_o  | o        | 1          | valid output  |