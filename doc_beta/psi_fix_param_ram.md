<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_param_ram
 - VHDL source: [psi_fix_param_ram](../hdl/psi_fix_param_ram.vhd)
 - Testbench source: [psi_fix_param_ram_tb.vhd](../testbench/psi_fix_param_ram_tb/psi_fix_param_ram_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name       | type          | Description                                          |
|:-----------|:--------------|:-----------------------------------------------------|
| depth_g    | positive      | memory depth                                         |
| fmt_g      | psi_fix_fmt_t | fixed format                                         |
| behavior_g | string        | "rbw" = read-before-write, "wbr" = write-before-read |
| init_g     | t_areal       | first n parameters are initialized, others are zero  |

### Interfaces
| Name   | In/Out   | Length   | Description   |
|:-------|:---------|:---------|:--------------|
| douta  | o        | fmt_g)   | data output a |
| doutb  | o        | fmt_g)   | data output b |