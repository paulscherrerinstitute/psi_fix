<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_phase_unwrap
 - VHDL source: [psi_fix_phase_unwrap](../hdl/psi_fix_phase_unwrap.vhd)
 - Testbench source: [psi_fix_phase_unwrap_tb.vhd](../testbench/psi_fix_phase_unwrap_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type          | Description    |
|:----------|:--------------|:---------------|
| infmt_g   | psi_fix_fmt_t | input format   |
| outfmt_g  | psi_fix_fmt_t | output format  |
| round_g   | psi_fix_rnd_t | round or trunc |
| rst_pol_g | std_logic     | reset polarity |

### Interfaces
| Name   | In/Out   | Length    | Description                |
|:-------|:---------|:----------|:---------------------------|
| clk_i  | i        | 1         | $$ type=clk; freq=127e6 $$ |
| rst_i  | i        | 1         | $$ type=rst; clk=clk $$    |
| dat_i  | i        | infmt_g)  | data input                 |
| vld_i  | i        | 1         | valid signal input         |
| dat_o  | o        | outfmt_g) | data output                |
| vld_o  | o        | 1         | valid signal output        |
| wrap_o | o        | 1         | wrap output                |