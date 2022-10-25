<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_cic_dec_fix_1ch
 - VHDL source: [psi_fix_cic_dec_fix_1ch](../hdl/psi_fix_cic_dec_fix_1ch.vhd)
 - Testbench source: [psi_fix_cic_dec_fix_1ch_tb.vhd](../testbench/psi_fix_cic_dec_fix_1ch_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                                        |
|:---------------|:--------------|:-------------------------------------------------------------------|
| order_g        | integer       | cic filter order                                                   |
| ratio_g        | integer       | cic decimation ratio                                               |
| diffdelay_g    | natural       | differential delay                                                 |
| infmt_g        | psi_fix_fmt_t | input format fp                                                    |
| outfmt_g       | psi_fix_fmt_t | output format fp                                                   |
| rst_pol_g      | std_logic     | reset polarity active high = '1'                                   |
| autogaincorr_g | boolean       | uses up to 25 bits of the datapath and 17 bit correction parameter |

### Interfaces
| Name   | In/Out   | Length    | Description                                 |
|:-------|:---------|:----------|:--------------------------------------------|
| clk_i  | i        | 1         | clk system                                  |
| rst_i  | i        | 1         | rst system                                  |
| dat_i  | i        | infmt_g)  | data input                                  |
| vld_i  | i        | 1         | valid input sampling frequency              |
| dat_o  | o        | outfmt_g) | data output                                 |
| vld_o  | o        | 1         | vaid output new sampling frequency fs/ratio |
| busy_o | o        | 1         | active high                                 |