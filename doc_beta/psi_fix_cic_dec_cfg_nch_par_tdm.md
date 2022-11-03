<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_cic_dec_cfg_nch_par_tdm
 - VHDL source: [psi_fix_cic_dec_cfg_nch_par_tdm](../hdl/psi_fix_cic_dec_cfg_nch_par_tdm.vhd)
 - Testbench source: [psi_fix_cic_dec_cfg_nch_par_tdm_tb.vhd](../testbench/psi_fix_cic_dec_cfg_nch_par_tdm_tb/psi_fix_cic_dec_cfg_nch_par_tdm_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type          | Description                                                             |
|:-----------------|:--------------|:------------------------------------------------------------------------|
| channels_g       | integer       | min. 2                                                                  |
| order_g          | integer       | filter order                                                            |
| max_ratio_g      | natural       | maximaum decimation ratio                                               |
| diff_delay_g     | natural       | differential delay                                                      |
| in_fmt_g         | psi_fix_fmt_t | input fomrat fp                                                         |
| out_fmt_g        | psi_fix_fmt_t | output fromat fp                                                        |
| rst_pol_g        | std_logic     | reset polarity active high ='1'                                         |
| auto_gain_corr_g | boolean       | use cfggaincorr for fine-grained gain correction (beyond pure shifting) |

### Interfaces
| Name            | In/Out   | Length     | Description                                                                               |
|:----------------|:---------|:-----------|:------------------------------------------------------------------------------------------|
| clk_i           | i        | 1          | clk system                                                                                |
| rst_i           | i        | 1          | rst system                                                                                |
| cfg_ratio_i     | i        | 1          | N.A                                                                                       |
| cfg_shift_i     | i        | 7          | shifting by more than 255 bits is not supported, this would lead to timing issues anyways |
| cfg_gain_corr_i | i        | 16         | gain correction factor in format [0,1,16]                                                 |
| dat_i           | i        | in_fmt_g)  | data input                                                                                |
| vld_i           | i        | 1          | valid input                                                                               |
| dat_o           | o        | out_fmt_g) | data output                                                                               |
| vld_o           | o        | 1          | valid otuput                                                                              |
| busy_o          | o        | 1          | busy signal output active high                                                            |