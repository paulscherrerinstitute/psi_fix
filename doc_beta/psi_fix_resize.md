<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_resize
 - VHDL source: [psi_fix_resize](../hdl/psi_fix_resize.vhd)
 - Testbench source: [psi_fix_resize_tb.vhd](../testbench/psi_fix_resize_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type          | Description                             |
|:----------|:--------------|:----------------------------------------|
| infmt_g   | psi_fix_fmt_t | must be signed $$ constant=(1,1,14) $$  |
| outfmt_g  | psi_fix_fmt_t | must be unsigned $$ constant=(0,0,8) $$ |
| round_g   | psi_fix_rnd_t | round or trunc $$ constant=true $$      |
| sat_g     | psi_fix_sat_t | saturate or wrap $$ constant=true $$    |
| rst_pol_g | std_logic     | reset polarity                          |

### Interfaces
| Name   | In/Out   | Length    | Description                                          |
|:-------|:---------|:----------|:-----------------------------------------------------|
| clk_i  | i        | 1         | system clock $$ type=clk; freq=100e6 $$              |
| rst_i  | i        | 1         | system reset $$ type=rst; clk=clk_i $$               |
| vld_i  | i        | 1         | valid input sampling freqeuncy                       |
| rdy_o  | o        | 1         | ready output signal active high $$ lowactive=true $$ |
| dat_i  | i        | infmt_g)  | data input                                           |
| vld_o  | o        | 1         | valid signa output                                   |
| dat_o  | o        | outfmt_g) | daat output signal                                   |