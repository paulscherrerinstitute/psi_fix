<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_complex_mult
 - VHDL source: [psi_fix_complex_mult](../hdl/psi_fix_complex_mult.vhd)
 - Testbench source: [psi_fix_complex_mult_tb.vhd](../testbench/psi_fix_complex_mult_tb/psi_fix_complex_mult_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                                                     |
|:---------------|:--------------|:--------------------------------------------------------------------------------|
| rst_pol_g      | std_logic     | set reset polarity $$ constant='1' $$                                           |
| pipeline_g     | boolean       | when false 3 pipes stages, when false 6 pipes (increase fmax) $$ export=true $$ |
| in_a_fmt_g     | psi_fix_fmt_t | input a fixed point format $$ constant=(1,0,15) $$                              |
| in_b_fmt_g     | psi_fix_fmt_t | input b fixed point format $$ constant=(1,0,24) $$                              |
| internal_fmt_g | psi_fix_fmt_t | internal calc. fixed point format $$ constant=(1,1,24) $$                       |
| out_fmt_g      | psi_fix_fmt_t | output fixed point format $$ constant=(1,0,20) $$                               |
| round_g        | psi_fix_rnd_t | trunc or round $$ constant=psi_fix_round $$                                     |
| sat_g          | psi_fix_sat_t | sat or wrap $$ constant=psi_fix_sat $$                                          |
| in_a_is_cplx_g | boolean       | complex number?                                                                 |
| in_b_is_cplx_g | boolean       | complex number?                                                                 |

### Interfaces
| Name          | In/Out   | Length      | Description                         |
|:--------------|:---------|:------------|:------------------------------------|
| clk_i         | i        | 1           | clk $$ type=clk; freq=100e6 $$      |
| rst_i         | i        | 1           | sync. rst $$ type=rst; clk=clk_i $$ |
| dat_ina_inp_i | i        | in_a_fmt_g) | inphase input of signal a           |
| dat_ina_qua_i | i        | in_a_fmt_g) | quadrature input of signal a        |
| dat_inb_inp_i | i        | in_b_fmt_g) | inphase input of signal b           |
| dat_inb_qua_i | i        | in_b_fmt_g) | quadrature input of signal b        |
| vld_i         | i        | 1           | strobe input                        |
| dat_inp_o     | o        | out_fmt_g)  | data output i                       |
| dat_qua_o     | o        | out_fmt_g)  | data output q                       |
| vld_o         | o        | 1           | strobe output                       |