<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_comparator
 - VHDL source: [psi_fix_comparator](../hdl/psi_fix_comparator.vhd)
 - Testbench source: [psi_fix_comparator_tb.vhd](../testbench/psi_fix_comparator_tb/psi_fix_comparator_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name      | type          | Description                     |
|:----------|:--------------|:--------------------------------|
| fmt_g     | psi_fix_fmt_t | format fixed for all            |
| rst_pol_g | std_logic     | reset polarity active high ='1' |

### Interfaces
| Name      | In/Out   | Length   | Description         |
|:----------|:---------|:---------|:--------------------|
| clk_i     | i        | 1        | clk input           |
| rst_i     | i        | 1        | rst input           |
| set_min_i | i        | fmt_g)   | min threshold       |
| set_max_i | i        | fmt_g)   | max threshold       |
| data_i    | i        | fmt_g)   | data input          |
| vld_i     | i        | 1        | valid input signal  |
| vld_o     | o        | 1        | valid signal output |
| min_o     | o        | 1        | minimum flag output |
| max_o     | o        | 1        | maximum fag output  |