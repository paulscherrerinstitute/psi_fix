<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_demod_real2cplx
 - VHDL source: [psi_fix_demod_real2cplx](../hdl/psi_fix_demod_real2cplx.vhd)
 - Testbench source: [psi_fix_demod_real2cplx_tb.vhd](../testbench/psi_fix_demod_real2cplx_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name       | type           | Description                                          |
|:-----------|:---------------|:-----------------------------------------------------|
| rstpol_g   | std_logic      | reset polarity active high ='1' $$ constant = '1' $$ |
| infmt_g    | psi_fix_fmt_t; | input format fp $$ constant=(1,0,15) $$              |
| outfmt_g   | psi_fix_fmt_t; | output format fp $$ constant=(1,0,16) $$             |
| coefbits_g | positive       | internal coefficent number of bits $$ constant=25 $$ |
| channels_g | natural        | number of channels tdm $$ constant=2 $$              |
| ratio_g    | natural        | ratio betwenn clock and if/rf $$ constant=5 $$       |

### Interfaces
| Name         | In/Out   | Length                | Description                           |
|:-------------|:---------|:----------------------|:--------------------------------------|
| clk_i        | i        | 1                     | clk system $$ type=clk; freq=100e6 $$ |
| rst_i        | i        | 1                     | rst system $$ type=rst; clk=clk_i $$  |
| dat_i        | i        | infmt_g)*channels_g   | data input if/rf                      |
| vld_i        | i        | 1                     | valid input freqeuncy sampling        |
| phi_offset_i | i        | ratio_g)-1            | phase offset for demod lut            |
| dat_inp_o    | o        | outfmt_g)*channels_g- | inphase data output                   |
| dat_qua_o    | o        | outfmt_g)*channels_g- | quadrature data output                |
| vld_o        | o        | 1                     | valid output                          |