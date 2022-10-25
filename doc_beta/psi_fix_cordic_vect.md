<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_cordic_vect
 - VHDL source: [psi_fix_cordic_vect](../hdl/psi_fix_cordic_vect.vhd)
 - Testbench source: [psi_fix_cordic_vect_tb.vhd](../testbench/psi_fix_cordic_vect_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                                                         |
|:---------------|:--------------|:------------------------------------------------------------------------------------|
| infmt_g        | psi_fix_fmt_t | must be signed $$ constant=(1,0,15) $$                                              |
| outfmt_g       | psi_fix_fmt_t | must be unsigned $$ constant=(0,2,16) $$                                            |
| internalfmt_g  | psi_fix_fmt_t | must be signed $$ constant=(1,2,22) $$                                              |
| anglefmt_g     | psi_fix_fmt_t | must be unsigned $$ constant=(0,0,15) $$                                            |
| angleintfmt_g  | psi_fix_fmt_t | must be signed $$ constant=(1,0,18) $$                                              |
| iterations_g   | natural       | number of iteration prior to get results $$ constant=13 $$                          |
| gaincomp_g     | boolean       | gain compensation $$ export=true $$                                                 |
| round_g        | psi_fix_rnd_t | round or trunc $$ export=true $$                                                    |
| sat_g          | psi_fix_sat_t | saturation or wrap $$ export=true $$                                                |
| mode_g         | string        | pipelined or serial $$ export=true $$                                               |
| plstgperiter_g | integer       | number of pipeline stages per iteration (does only affect pipelined implementation) |

### Interfaces
| Name      | In/Out   | Length      | Description                              |
|:----------|:---------|:------------|:-----------------------------------------|
| clk_i     | i        | 1           | clk system $$ type=clk; freq=100e6 $$    |
| rst_i     | i        | 1           | rst system $$ type=rst; clk=clk $$       |
| dat_inp_i | i        | infmt_g)    | data input input                         |
| dat_qua_i | i        | infmt_g)    | dat quadrature input                     |
| vld_i     | i        | 1           | valid signal in                          |
| rdy_i     | o        | 1           | ready signal output $$ lowactive=true $$ |
| dat_abs_o | o        | outfmt_g)   | data amplitude output                    |
| dat_ang_o | o        | anglefmt_g) | dat angle output                         |
| vld_o     | o        | 1           | valid output                             |