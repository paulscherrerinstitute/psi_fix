<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_complex_addsub
 - VHDL source: [psi_fix_complex_addsub](../hdl/psi_fix_complex_addsub.vhd)
 - Testbench source: [psi_fix_complex_addsub_tb.vhd](../testbench/psi_fix_complex_addsub_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type          | Description                                                                     |
|:-----------------|:--------------|:--------------------------------------------------------------------------------|
| generic(rstpol_g | std_logic     | set reset polarity $$ constant='1' $$                                           |
| pipeline_g       | boolean       | when false 3 pipes stages, when false 6 pipes (increase fmax) $$ export=true $$ |
| inafmt_g         | psi_fix_fmt_t | input a fixed point format $$ constant=(1,0,15) $$                              |
| inbfmt_g         | psi_fix_fmt_t | input b fixed point format $$ constant=(1,0,24) $$                              |
| outfmt_g         | psi_fix_fmt_t | output fixed point format $$ constant=(1,0,20) $$                               |
| round_g          | psi_fix_rnd_t | round or trunc $$ constant=psifixround $$                                       |
| sat_g            | psi_fix_sat_t | adder or subtracter $$ constant=psifixsat $$                                    |
| addsub_g         | string        | N.A                                                                             |

### Interfaces
| Name          | In/Out   | Length    | Description                         |
|:--------------|:---------|:----------|:------------------------------------|
| clk_i         | i        | 1         | clk $$ type=clk; freq=100e6 $$      |
| rst_i         | i        | 1         | sync. rst $$ type=rst; clk=clk_i $$ |
| dat_ina_inp_i | i        | inafmt_g) | inphase input of signal a           |
| dat_ina_qua_i | i        | inafmt_g) | quadrature input of signal a        |
| dat_inb_inp_i | i        | inbfmt_g) | inphase input of signal b           |
| dat_inb_qua_i | i        | inbfmt_g) | quadrature input of signal b        |
| vld_i         | i        | 1         | strobe input                        |
| dat_out_inp_o | o        | outfmt_g) | data output i                       |
| dat_out_qua_o | o        | outfmt_g) | data output q                       |
| vld_o         | o        | 1         | strobe output                       |