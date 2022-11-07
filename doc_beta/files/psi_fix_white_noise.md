<img align="right" src="../../doc/psi_logo.png">

***

[**component list**](../README.md)

# psi_fix_white_noise
 - VHDL source: [psi_fix_white_noise](../../hdl/psi_fix_white_noise.vhd)
 - Testbench source: [psi_fix_white_noise_tb.vhd](../../testbench/psi_fix_white_noise_tb/psi_fix_white_noise_tb.vhd)

### Description

This entity generates equally distributed white noise.
It does so by implementing an LFSR based pseudo-random binary sequence for each bit. Because the bits are fully uncorrelated (different seed), the signal generated is completely white.

The LFSRs are 32-bits wide, and the sequence repeats every 2’734’686’208 samples. For normal applications, this is long enough to be considered as uncorrelated.

The seed of the generator can be modified using generics. This allows generating different random sequences in the same design.


### Generics
| Name               | type          | Description   |
|:-------------------|:--------------|:--------------|
| out_fmt_g 				| psi_fix_fmt_t | max 32 bits         |
| seed_g             | unsigned		   | N.A           |
| rst_pol_g          | std_logic     | reset polarity           |

### Interfaces
| Name   | In/Out   | Length     | Description   |
|:-------|:---------|:-----------|:--------------|
| clk_i  | i        | 1          | system clock           |
| rst_i  | i        | 1          | system reset  |
| vld_o  | o        | 1          | AXI-S handshaking signal valid output  |
| dat_o  | o        | out_fmt_g) | data output           |

The signal vld_i is mainly used for bit trueness purposes. It allows adding noise to a signal exactly the same way as I the simulation by requesting the next sample vld_i=’1’ whenever a new signal sample is available.

Of course the signal must be delayed for the processing time of the noise generator in this case in order to add the first noise sample to the first signal sample. This delay can easiest and most flexibly be achieved by a FIFO (this also still works if for any reasons the delay of the noise generator should slightly change).

---
[**component list**](../README.md)
