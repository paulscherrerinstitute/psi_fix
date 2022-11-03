<img align="right" src="../doc/psi_logo.png">
***

# psi_fix_dds_18b
 - VHDL source: [psi_fix_dds_18b](../hdl/psi_fix_dds_18b.vhd)
 - Testbench source: [psi_fix_dds_18b_tb.vhd](../testbench/psi_fix_dds_18b_tb/psi_fix_dds_18b_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name           | type          | Description                                    |
|:---------------|:--------------|:-----------------------------------------------|
| phase_fmt_g    | psi_fix_fmt_t | phase format width => generally counter length |
| tdm_channels_g | positive      | time division multiplexed number of channels   |
| ram_behavior_g | string        | ram beahvior read before write                 |
| rst_pol_g      | std_logic     | reset polarity active high = '1'               |
| rst_sync_g     | boolean       | reset sync or async                            |

### Interfaces
| Name         | In/Out   | Length       | Description                                       |
|:-------------|:---------|:-------------|:--------------------------------------------------|
| clk_i        | i        | 1            | clk system                                        |
| rst_i        | i        | 1            | rst system                                        |
| phi_step_i   | i        | rasterized   | phase step (rasterized make sens for phase noise) |
| phi_offset_i | i        | phase_fmt_g) | phase offset                                      |
| dat_sin_o    | o        | 17           | sinus output                                      |
| dat_cos_o    | o        | 17           | cosine output 90â° phase shifted                  |
| vld_o        | o        | 1            | freqeuncy sampling output valid                   |