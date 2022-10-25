<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_nch_analog_trigger_tdm
 - VHDL source: [psi_fix_nch_analog_trigger_tdm](../hdl/psi_fix_nch_analog_trigger_tdm.vhd)
 - Testbench source: [psi_fix_nch_analog_trigger_tdm_tb.vhd](../testbench/psi_fix_nch_analog_trigger_tdm_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type          | Description                      |
|:----------------|:--------------|:---------------------------------|
| generic(ch_nb_g | natural       | number of input/output channel   |
| trig_ext_nb_g   | natural       | number of input external trigger |
| fix_fmt_g       | psi_fix_fmt_t | fp format                        |
| trig_nb_g       | natural       | number of output trigger         |

### Interfaces
| Name           | In/Out   | Length                    | Description                          |
|:---------------|:---------|:--------------------------|:-------------------------------------|
| clk_i          | i        | 1                         | processing clock                     |
| rst_i          | i        | 1                         | reset processing '1' <=> active high |
| dat_i          | i        | fix_fmt_g)-               | // data input                        |
| vld_i          | i        | 1                         | tdm strobe input                     |
| ext_i          | i        | trig_ext_nb_g-1           | external trigger input               |
| mask_min_i     | i        | trig_nb_g*ch_nb_g-1       | mask min results                     |
| mask_max_i     | i        | trig_nb_g*ch_nb_g-1       | mask max results                     |
| mask_ext_i     | i        | trig_nb_g*trig_ext_nb_g-1 | mask external trigger                |
| thld_min_i     | i        | fix_fmt_g)-1              | thld to set max window               |
| thld_max_i     | i        | fix_fmt_g)-1              | thld to set min window               |
| trig_clr_ext_i | i        | trig_nb_g*trig_ext_nb_g-1 | N.A                                  |
| trig_arm_i     | i        | trig_nb_g-1               | N.A                                  |
| dat_pipe_o     | o        | fix_fmt_g)-1              | data out pipelined for recording     |
| str_pipe_o     | o        | 1                         | strobe out pipelined for recording   |
| trig_o         | o        | trig_nb_g-1               | trigger out                          |
| is_arm_o       | o        | trig_nb_g-1               | trigger is armed                     |