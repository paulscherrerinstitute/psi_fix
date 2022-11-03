<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_mov_avg
 - VHDL source: [psi_fix_mov_avg](../hdl/psi_fix_mov_avg.vhd)
 - Testbench source: [psi_fix_mov_avg_tb.vhd](../testbench/psi_fix_mov_avg_tb/psi_fix_mov_avg_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name        | type           | Description                                     |
|:------------|:---------------|:------------------------------------------------|
| in_fmt_g    | psi_fix_fmt_t; | input format $$ constant=(1,0,10) $$            |
| out_fmt_g   | psi_fix_fmt_t; | output format $$ constant=(1,1,12) $$           |
| taps_g      | positive;      | number of taps $$ constant=7 $$                 |
| gain_corr_g | string         | N.A                                             |
| round_g     | psi_fix_rnd_t  | round or trunc                                  |
| sat_g       | psi_fix_sat_t  | saturate or wrap                                |
| out_regs_g  | natural        | add number of output register $$ export=true $$ |

### Interfaces
| Name   | In/Out   | Length     | Description                             |
|:-------|:---------|:-----------|:----------------------------------------|
| clk_i  | i        | 1          | system clock $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1          | system reset $$ type=rst; clk=clk_i $$  |
| dat_i  | i        | in_fmt_g)  | data input                              |
| vld_i  | i        | 1          | valid input sampling frequency          |
| dat_o  | o        | out_fmt_g) | data output                             |
| vld_o  | o        | 1          | valid output sampling frequency         |