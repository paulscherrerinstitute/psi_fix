<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_cic_dec_fix_nch_par_tdm
 - VHDL source: [psi_fix_cic_dec_fix_nch_par_tdm](../hdl/psi_fix_cic_dec_fix_nch_par_tdm.vhd)
 - Testbench source: [psi_fix_cic_dec_fix_nch_par_tdm_tb.vhd](../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                                        |
|:---------------|:--------------|:-------------------------------------------------------------------|
| channels_g     | integer       | min. 2                                                             |
| order_g        | integer       | cic filter order                                                   |
| ratio_g        | integer       | decimation ratio watch out the number of channels                  |
| diffdelay_g    | natural       | diffrential delay                                                  |
| infmt_g        | psi_fix_fmt_t | input format fp                                                    |
| outfmt_g       | psi_fix_fmt_t | output fromat fp                                                   |
| rst_pol_g      | std_logic;    | reset polarity active high = '1'                                   |
| autogaincorr_g | boolean       | uses up to 25 bits of the datapath and 17 bit correction parameter |

### Interfaces
| Name   | In/Out   | Length    | Description                                  |
|:-------|:---------|:----------|:---------------------------------------------|
| clk_i  | i        | 1         | clk system                                   |
| rst_i  | i        | 1         | rst system                                   |
| dat_i  | i        | infmt_g)  | data input                                   |
| vld_i  | i        | 1         | valid input frequency sampling               |
| dat_o  | o        | outfmt_g) | data output                                  |
| vld_o  | o        | 1         | valid output new frequency sampling fs/ratio |
| busy_o | o        | 1         | active high                                  |