<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_fir_dec_ser_nch_chpar_conf
 - VHDL source: [psi_fix_fir_dec_ser_nch_chpar_conf](../hdl/psi_fix_fir_dec_ser_nch_chpar_conf.vhd)
 - Testbench source: [psi_fix_fir_dec_ser_nch_chpar_conf_tb.vhd](../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type          | Description                                      |
|:-----------------|:--------------|:-------------------------------------------------|
| generic(in_fmt_g | psi_fix_fmt_t | internal format                                  |
| out_fmt_g        | psi_fix_fmt_t | output format                                    |
| coef_fmt_g       | psi_fix_fmt_t | coefficient format                               |
| channels_g       | natural       | channels                                         |
| max_ratio_g      | natural       | max decimation ratio                             |
| max_taps_g       | natural       | max number of taps                               |
| rnd_g            | psi_fix_rnd_t | rounding truncation                              |
| sat_g            | psi_fix_sat_t | saturate or wrap                                 |
| use_fix_coefs_g  | boolean       | use fix coefficients or update them              |
| coefs_g          | t_areal       | see doc                                          |
| ram_behavior_g   | string        | rbw = read before write, wbr = write before read |
| rst_pol_g        | std_logic     | reset polarity active high ='1'                  |

### Interfaces
| Name             | In/Out   | Length      | Description                         |
|:-----------------|:---------|:------------|:------------------------------------|
| clk_i            | i        | 1           | system clock                        |
| rst_i            | i        | 1           | system reset                        |
| dat_i            | i        | in_fmt_g)   | data input                          |
| vld_i            | i        | 1           | valid input frequency sampling      |
| dat_o            | o        | out_fmt_g)  | data output                         |
| vld_o            | o        | 1           | valid output new frequency sampling |
| coef_if_rd_dat_o | o        | coef_fmt_g) | coef read                           |
| busy_o           | o        | 1           | calculation on going active high    |