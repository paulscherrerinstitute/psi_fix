<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_fir_par_nch_chtdm_conf
 - VHDL source: [psi_fix_fir_par_nch_chtdm_conf](../hdl/psi_fix_fir_par_nch_chtdm_conf.vhd)
 - Testbench source: [psi_fix_fir_par_nch_chtdm_conf_tb.vhd](../testbench/psi_fix_fir_par_nch_chtdm_conf_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name          | type          | Description                                  |
|:--------------|:--------------|:---------------------------------------------|
| infmt_g       | psi_fix_fmt_t | input format fp $$ constant=(1,0,15) $$      |
| outfmt_g      | psi_fix_fmt_t | output format fp $$ constant=(1,2,13) $$     |
| coeffmt_g     | psi_fix_fmt_t | coeffcient format fp $$ constant=(1,0,17) $$ |
| channels_g    | natural       | number of channel $$ export=true $$          |
| taps_g        | natural       | taps number $$ export=true $$                |
| rnd_g         | psi_fix_rnd_t | round or trunc                               |
| sat_g         | psi_fix_sat_t | sat or wrap                                  |
| usefixcoefs_g | boolean       | use fixed coef or updated from table         |
| coefs_g       | t_areal       | see doc                                      |

### Interfaces
| Name   | In/Out   | Length    | Description                             |
|:-------|:---------|:----------|:----------------------------------------|
| clk_i  | i        | 1         | system clock $$ type=clk; freq=100e6 $$ |
| rst_i  | i        | 1         | system reset $$ type=rst; clk=clk $$    |
| dat_i  | i        | infmt_g)  | data input fp                           |
| vld_i  | i        | 1         | valid input frequency sampling          |
| dat_o  | o        | outfmt_g) | data output                             |
| vld_o  | o        | 1         | valid output frequency sampling         |