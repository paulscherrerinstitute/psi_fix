<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_fir_3tap_hbw_dec2
 - VHDL source: [psi_fix_fir_3tap_hbw_dec2](../hdl/psi_fix_fir_3tap_hbw_dec2.vhd)
 - Testbench source: [psi_fix_fir_3tap_hbw_dec2_tb.vhd](../testbench/psi_fix_fir_3tap_hbw_dec2_tb/psi_fix_fir_3tap_hbw_dec2_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name       | type          | Description                              |
|:-----------|:--------------|:-----------------------------------------|
| in_fmt_g   | psi_fix_fmt_t | input format fp                          |
| out_fmt_g  | psi_fix_fmt_t | output format fp                         |
| channels_g | natural       | number of channels tdm $$ export=true $$ |
| separate_g | boolean       | $$ export=true $$                        |
| rnd_g      | psi_fix_rnd_t | round or trunc                           |
| sat_g      | psi_fix_sat_t | saturation or wrap                       |
| rst_pol_g  | std_logic     | reset polarity active high ='1'          |
| rst_sync_g | boolean       | async reset or sync architecture         |

### Interfaces
| Name   | In/Out   | Length     | Description                                       |
|:-------|:---------|:-----------|:--------------------------------------------------|
| clk_i  | i        | 1          | clk system $$ type=clk; freq=100e6; proc=input $$ |
| rst_i  | i        | 1          | rst system $$ type=rst; clk=clk $$                |
| dat_i  | i        | in_fmt_g)  | data input $$ proc=input $$                       |
| vld_i  | i        | 1          | valid input frequency sampling $$ proc=input $$   |
| dat_o  | o        | out_fmt_g) | data output $$ proc=output $$                     |
| vld_o  | o        | 1          | valid otuput $$ proc=output $$                    |