<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_complex_abs
 - VHDL source: [psi_fix_complex_abs](../hdl/psi_fix_complex_abs.vhd)
 - Testbench source: [psi_fix_complex_abs_tb.vhd](../testbench/psi_fix_complex_abs_tb/psi_fix_complex_abs_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                      |
|:---------------|:--------------|:-------------------------------------------------|
| in_fmt_g       | psi_fix_fmt_t | fp format in                                     |
| out_fmt_g      | psi_fix_fmt_t | fp format out                                    |
| round_g        | psi_fix_rnd_t | trunc or round                                   |
| sat_g          | psi_fix_sat_t | wrap or sat                                      |
| rst_pol_g      | std_logic     | reset polarity active high                       |
| ram_behavior_g | string        | rbw = read before write, wbr = write before read |

### Interfaces
| Name      | In/Out   | Length    | Description                  |
|:----------|:---------|:----------|:-----------------------------|
| clk_i     | i        | 1         | $$ type=clk; freq=127e6 $$   |
| rst_i     | i        | 1         | $$ type=rst; clk=clk_i $$    |
| dat_inp_i | i        | in_fmt_g) | data inphase i               |
| dat_qua_i | i        | in_fmt_g) | data quadrature q            |
| vld_i     | i        | 1         | valid signal in              |
| dat_o     | o        | i^2+q^2)  | results output dqrt(i^2+q^2) |
| vld_o     | o        | 1         | valid signal out             |