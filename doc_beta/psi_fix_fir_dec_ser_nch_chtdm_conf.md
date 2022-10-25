<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_fir_dec_ser_nch_chtdm_conf
 - VHDL source: [psi_fix_fir_dec_ser_nch_chtdm_conf](../hdl/psi_fix_fir_dec_ser_nch_chtdm_conf.vhd)
 - Testbench source: [psi_fix_fir_dec_ser_nch_chtdm_conf_tb.vhd](../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name          | type          | Description                                      |
|:--------------|:--------------|:-------------------------------------------------|
| infmt_g       | psi_fix_fmt_t | internal format                                  |
| outfmt_g      | psi_fix_fmt_t | output format                                    |
| coeffmt_g     | psi_fix_fmt_t | coefficient format                               |
| channels_g    | natural       | channels                                         |
| maxratio_g    | natural       | max decimation ratio                             |
| maxtaps_g     | natural       | max number of taps                               |
| rnd_g         | psi_fix_rnd_t | rounding truncation                              |
| sat_g         | psi_fix_sat_t | saturate or wrap                                 |
| usefixcoefs_g | boolean       | use fix coefficients or update them              |
| coefs_g       | t_areal       | see doc                                          |
| rambehavior_g | string        | rbw = read before write, wbr = write before read |
| rst_pol_g     | std_logic     | reset polarity active high ='1'                  |

### Interfaces
| Name             | In/Out   | Length     | Description                         |
|:-----------------|:---------|:-----------|:------------------------------------|
| clk_i            | i        | 1          | system clock                        |
| rst_i            | i        | 1          | system reset                        |
| dat_i            | i        | infmt_g)   | data input                          |
| vld_i            | i        | 1          | valid input frequency sampling      |
| dat_o            | o        | outfmt_g)  | data output                         |
| vld_o            | o        | 1          | valid output new frequency sampling |
| coef_if_rd_dat_o | o        | coeffmt_g) | coef read                           |
| busy_o           | o        | 1          | calculation on going active high    |