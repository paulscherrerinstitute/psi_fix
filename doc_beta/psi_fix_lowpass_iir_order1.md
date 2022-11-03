<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_lowpass_iir_order1
 - VHDL source: [psi_fix_lowpass_iir_order1](../hdl/psi_fix_lowpass_iir_order1.vhd)
 - Testbench source: [psi_fix_lowpass_iir_order1_tb.vhd](../testbench/psi_fix_lowpass_iir_order1_tb/psi_fix_lowpass_iir_order1_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type          | Description                                                                     |
|:-----------------|:--------------|:--------------------------------------------------------------------------------|
| f_sample_hz_g    | real          | $$constant=100.0e6$$                                                            |
| f_cutoff_hz_g    | real          | $$constant=1.0e6$$                                                              |
| in_fmt_g         | psi_fix_fmt_t | $$constant='(1, 0, 15)'$$                                                       |
| out_fmt_g        | psi_fix_fmt_t | $$constant='(1, 0, 14)'$$                                                       |
| int_fmt_g        | psi_fix_fmt_t | number format for calculations, for details see documentation                   |
| coef_fmt_g       | psi_fix_fmt_t | coef format                                                                     |
| round_g          | psi_fix_rnd_t | round or trunc                                                                  |
| sat_g            | psi_fix_sat_t | sat or wrap                                                                     |
| pipeline_g       | boolean       | true = optimize for clock speed, false = optimize for latency $$ export=true $$ |
| reset_polarity_g | std_logic     | reset polarity active high = '1'                                                |

### Interfaces
| Name   | In/Out   | Length     | Description                            |
|:-------|:---------|:-----------|:---------------------------------------|
| clk_i  | i        | 1          | clock input $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1          | sync. reset $$ type=rst; clk=clk_i $$  |
| dat_i  | i        | in_fmt_g)  | data in                                |
| vld_i  | i        | 1          | input valid signal                     |
| dat_o  | o        | out_fmt_g) | data out                               |
| vld_o  | o        | 1          | output valid signal                    |