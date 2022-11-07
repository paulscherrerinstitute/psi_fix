<img align="right" src="../../doc/psi_logo.png">

***

[**component list**](../README.md)

# psi_fix_cic_dec_cfg_nch_par_tdm
 - VHDL source: [psi_fix_cic_dec_cfg_nch_par_tdm](../../hdl/psi_fix_cic_dec_cfg_nch_par_tdm.vhd)
 - Testbench source: [psi_fix_cic_dec_cfg_nch_par_tdm_tb.vhd](../../testbench/psi_fix_cic_dec_cfg_nch_par_tdm_tb/psi_fix_cic_dec_cfg_nch_par_tdm_tb.vhd)

### Description
This is the same CIC filter as  [psi_fix_cic_dec_fix_nch_par_tdm](psi_fix_cic_dec_fix_nch_par_tdm.md) but with the decimation ratio selectable at runtime. For general documentation, refer to the section given above. This section only describes the differences between the two filters.

The static shift of the original filter is replaced by a pipelined dynamic shift with two stages. Otherwise, the architecture is unchanged.

<img align="center" src="psi_fix_cic_dec_fix_nch_par_tdm.png">

### Generics
| Name             | type          | Description                                                             |
|:-----------------|:--------------|:------------------------------------------------------------------------|
| channels_g       | integer       | min. 2                                                                  |
| order_g          | integer       | filter order                                                            |
| max_ratio_g      | natural       | Maximum supported decimation ratio. Replaces the Ratio_g generic of the original filter                                              |
| diff_delay_g     | natural       | differential delay                                                      |
| in_fmt_g         | psi_fix_fmt_t | input format fp                                                         |
| out_fmt_g        | psi_fix_fmt_t | output format fp                                                        |
| rst_pol_g        | std_logic     | reset polarity active high ='1'                                         |
| auto_gain_corr_g | boolean       | True = Multiplier for exact gain compensation is implemented;	False = compensation by shift only |

### Interfaces
| Name            | In/Out   | Length     | Description                                                                               |
|:----------------|:---------|:-----------|:------------------------------------------------------------------------------------------|
| clk_i           | i        | 1          | clk system                                                                                |
| rst_i           | i        | 1          | rst system                                                                                |
| cfg_ratio_i     | i        | 1          | N.A                                                                                       |
| cfg_shift_i     | i        | 7          | shifting by more than 255 bits is not supported, this would lead to timing issues anyways -  Number of bits to shift for gain compensation. Sft*|
| cfg_gain_corr_i | i        | 16         | gain correction factor in format [0,1,16]    Gain correction factor in the format [0,1,16]. This port is only used if auto_gain_corr_g = True.  |
| dat_i           | i        | in_fmt_g)  | data input                                                                                |
| vld_i           | i        | 1          | valid input                                                                               |
| dat_o           | o        | out_fmt_g) | data output                                                                               |
| vld_o           | o        | 1          | valid otuput                                                                              |
| busy_o          | o        | 1          | busy signal output active high                                                            |

---
[**component list**](../README.md)
