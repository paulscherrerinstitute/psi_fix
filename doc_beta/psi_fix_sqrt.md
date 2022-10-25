<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_sqrt
 - VHDL source: [psi_fix_sqrt](../hdl/psi_fix_sqrt.vhd)
 - Testbench source: [psi_fix_sqrt_tb.vhd](../testbench/psi_fix_sqrt_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name          | type          | Description                                                   |
|:--------------|:--------------|:--------------------------------------------------------------|
| infmt_g       | psi_fix_fmt_t | must be unsigned, wuare root not defined for negative numbers |
| outfmt_g      | psi_fix_fmt_t | output format fp                                              |
| round_g       | psi_fix_rnd_t | round or trunc                                                |
| sat_g         | psi_fix_sat_t | sat or wrap                                                   |
| rambehavior_g | string        | rbw = read before write, wbr = write before read              |
| rst_pol_g     | std_logic     | N.A                                                           |

### Interfaces
| Name   | In/Out   | Length    | Description                 |
|:-------|:---------|:----------|:----------------------------|
| clk_i  | i        | 1         | $$ type=clk; freq=127e6 $$  |
| rst_i  | i        | 1         | $$ type=rst; clk=clk $      |
| dat_i  | i        | infmt_g)  | data input                  |
| vld_i  | i        | strobe    | valid signal (strobe input) |
| dat_o  | o        | outfmt_g) | data output                 |
| vld_o  | o        | 1         | output signal               |