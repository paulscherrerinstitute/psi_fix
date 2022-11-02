<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_pol2cart_approx
 - VHDL source: [psi_fix_pol2cart_approx](../hdl/psi_fix_pol2cart_approx.vhd)
 - Testbench source: [psi_fix_pol2cart_approx_tb.vhd](../testbench/psi_fix_pol2cart_approx_tb/psi_fix_pol2cart_approx_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                              |
|:---------------|:--------------|:-----------------------------------------|
| in_abs_fmt_g   | psi_fix_fmt_t | must be unsigned $$ constant=(0,0,16) $$ |
| in_angle_fmt_g | psi_fix_fmt_t | must be unsigned $$ constant=(0,0,15) $$ |
| out_fmt_g      | psi_fix_fmt_t | usually signed $$ constant=(1,0,16) $$   |
| round_g        | psi_fix_rnd_t | round or trunc                           |
| sat_g          | psi_fix_sat_t | sat or wrap                              |
| rst_pol_g      | std_logic     | reset polarity                           |

### Interfaces
| Name      | In/Out   | Length          | Description                           |
|:----------|:---------|:----------------|:--------------------------------------|
| clk_i     | i        | 1               | clk system $$ type=clk; freq=100e6 $$ |
| rst_i     | i        | 1               | rst system $$ type=rst; clk=clk_i $$  |
| dat_abs_i | i        | in_abs_fmt_g)   | data amplitude                        |
| dat_ang_i | i        | in_angle_fmt_g) | data phase                            |
| vld_i     | i        | 1               | valid input signal freqeucy sampling  |
| dat_inp_o | o        | out_fmt_g)      | data inphase                          |
| dat_qua_o | o        | out_fmt_g)      | data quadrature                       |
| vld_o     | o        | 1               | valid output                          |