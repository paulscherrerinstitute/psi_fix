<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_lin_approx_calc
 - VHDL source: [psi_fix_lin_approx_calc](../hdl/psi_fix_lin_approx_calc.vhd)
 - Testbench source: [psi_fix_lin_approx_calc_tb.vhd](../testbench/psi_fix_lin_approx_calc_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name        | type          | Description                         |
|:------------|:--------------|:------------------------------------|
| infmt_g     | psi_fix_fmt_t | depending ont table so do not touch |
| outfmt_g    | psi_fix_fmt_t | depending ont table so do not touch |
| offsfmt_g   | psi_fix_fmt_t | depending ont table so do not touch |
| gradfmt_g   | psi_fix_fmt_t | depending ont table so do not touch |
| tablesize_g | natural       | depending ont table so do not touch |
| rst_pol_g   | std_logic     | reset polarity                      |

### Interfaces
| Name         | In/Out   | Length       | Description                     |
|:-------------|:---------|:-------------|:--------------------------------|
| clk_i        | i        | 1            | system clock                    |
| rst_i        | i        | 1            | system reset                    |
| dat_i        | i        | infmt_g)     | data input                      |
| vld_i        | i        | 1            | valid input freqeuncy sampling  |
| dat_o        | o        | outfmt_g)    | data output                     |
| vld_o        | o        | 1            | valid output frequency sampling |
| addr_table_o | o        | tablesize_g) |                                 |
| data_table_i | i        | gradfmt_g)   |                                 |