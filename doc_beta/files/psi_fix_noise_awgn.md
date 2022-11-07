<img align="right" src="../../doc/psi_logo.png">

***

[**component list**](../README.md)

# psi_fix_noise_awgn
 - VHDL source: [psi_fix_noise_awgn](../../hdl/psi_fix_noise_awgn.vhd)
 - Testbench source: [psi_fix_noise_awgn_tb.vhd](../../testbench/psi_fix_noise_awgn_tb/psi_fix_noise_awgn_tb.vhd)

### Description

This entity generates average-free, white, gaussian distributed noise in the range from -1 to + 1. It does so by using the [psi_fix_white_noise](psi_fix_white_noise.md) generator and map the distribution to a gaussian one using [psi_fix_lin_approx](psi_fix_lin_approx.md).
The LFSRs are 32-bits wide, and the sequence repeats every 2’734’686’208 samples. For normal applications, this is long enough to be considered as uncorrelated.
The seed of the generator can be modified using generics. This allows generating different random sequences in the same design.


### Generics
| Name      | type          | Description      |
|:----------|:--------------|:-----------------|
| out_fmt_g | psi_fix_fmt_t | output format fp |
| seed_g    | unsigned(31   | seed 32 bits     |
| rst_pol_g | std_logic     | reset polarity   |

### Interfaces
| Name   | In/Out   | Length     | Description   |
|:-------|:---------|:-----------|:--------------|
| clk_i  | i        | 1          | system clock  |
| rst_i  | i        | 1          | system reset  |
| dat_o  | o        | out_fmt_g) | output data   |
| vld_o  | o        | 1          | valid output  |

The signal vld_i is mainly used for bit trueness purposes. It allows adding noise to a signal exactly the same way as I the simulation by requesting the next sample vld_i=’1’ whenever a new signal sample is available.

Of course the signal must be delayed for the processing time of the noise generator in this case in order to add the first noise sample to the first signal sample. This delay can easiest and most flexibly be achieved by a FIFO (this also still works if for any reasons the delay of the noise generator should slightly change).


[**component list**](../README.md)
