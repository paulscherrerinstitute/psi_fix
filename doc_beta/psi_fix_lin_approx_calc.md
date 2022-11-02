<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_lin_approx_calc
 - VHDL source: [psi_fix_lin_approx_calc](../hdl/psi_fix_lin_approx_calc.vhd)
 - Testbench source: [psi_fix_lin_approx_calc_tb.vhd](../testbench/psi_fix_lin_approx_calc_tb/psi_fix_lin_approx_calc_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name         | type          | Description                         |
|:-------------|:--------------|:------------------------------------|
| in_fmt_g     | psi_fix_fmt_t | depending ont table so do not touch |
| out_fmt_g    | psi_fix_fmt_t | depending ont table so do not touch |
| offs_fmt_g   | psi_fix_fmt_t | depending ont table so do not touch |
| grad_fmt_g   | psi_fix_fmt_t | depending ont table so do not touch |
| table_size_g | natural       | depending ont table so do not touch |
| rst_pol_g    | std_logic     | reset polarity                      |

### Interfaces
| Name         | In/Out   | Length        | Description                     |
|:-------------|:---------|:--------------|:--------------------------------|
| clk_i        | i        | 1             | system clock                    |
| rst_i        | i        | 1             | system reset                    |
| dat_i        | i        | in_fmt_g)     | data input                      |
| vld_i        | i        | 1             | valid input freqeuncy sampling  |
| dat_o        | o        | out_fmt_g)    | data output                     |
| vld_o        | o        | 1             | valid output frequency sampling |
| addr_table_o | o        | table_size_g) |                                 |
| data_table_i | i        | grad_fmt_g)   |                                 |