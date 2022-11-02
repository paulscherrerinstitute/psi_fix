<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_fir_dec_semi_nch_chtdm_conf
 - VHDL source: [psi_fix_fir_dec_semi_nch_chtdm_conf](../hdl/psi_fix_fir_dec_semi_nch_chtdm_conf.vhd)
 - Testbench source: [psi_fix_fir_dec_semi_nch_chtdm_conf_tb.vhd](../testbench/psi_fix_fir_dec_semi_nch_chtdm_conf_tb/psi_fix_fir_dec_semi_nch_chtdm_conf_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                    | type          | Description                                          |
|:------------------------|:--------------|:-----------------------------------------------------|
| in_fmt_g                | psi_fix_fmt_t | input format fp $$ constant=(1,0,15) $$              |
| out_fmt_g               | psi_fix_fmt_t | output format fp $$ constant=(1,2,13) $$             |
| coef_fmt_g              | psi_fix_fmt_t | coef format fp $$ constant=(1,0,17) $$               |
| channels_g              | natural       | number of parallel channels $$ export=true $$        |
| multipliers_g           | natural       | number of multipliers to use in parallel             |
| ratio_g                 | natural       | decimation ratio                                     |
| taps_g                  | natural       | number of taps implemented                           |
| rnd_g                   | psi_fix_rnd_t | round or trunc                                       |
| sat_g                   | psi_fix_sat_t | sat or wrap                                          |
| use_fix_coefs_g         | boolean       | if true fixed coefficient instead of configurable    |
| full_inp_rate_support_g | boolean       | true = valid signa can be high all the time          |
| ram_behavior_g          | string        | "rbw" = read-before-write, "wbr" = write-before-read |
| coefs_g                 | t_areal       | inital value for coefficients                        |
| impl_flush_if_g         | boolean       | implement memory flushing interface                  |

### Interfaces
| Name         | In/Out   | Length     | Description                                                                           |
|:-------------|:---------|:-----------|:--------------------------------------------------------------------------------------|
| clk_i        | i        | 1          | clk system $$ type=clk; freq=100e6 $$                                                 |
| rst_i        | i        | 1          | rst system $$ type=rst; clk=clk $$                                                    |
| dat_i        | i        | in_fmt_g)  | data input                                                                            |
| vld_i        | i        | 1          | valid input - axi-s handshaking                                                       |
| dat_o        | o        | out_fmt_g) | output data, one channel is passed after the other                                    |
| vld_o        | o        | 1          | valid output signal - axi-s handshaking                                               |
| flush_done_o | o        | 1          | a pulse on this port indicates that a flush started by flush_mem = '1' was completed. |
| busy_o       | o        | 1          | busy signal output status                                                             |