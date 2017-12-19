# General Information

## What belongs into this Library

This library contains fixed point processing logic that is not very application specific and can be reused easily. Code
must be written with reuse in mind. All important parameters as well as number formats shall be implemented as Generics.

One of the main ideas behind en_fix is to have bittrue Python models of each VHDL component in the library. Therefore only
components that have a bittrue model shall be added to this library. If some VHDL components don't have a bittrue model,
it may be better to open a separate library for "non-bittrue fixed-point code".

It is suggested to use one .vhd file per Package or Entity.

Examples for things that belong into this library:
* Processing Entities such as FIR filters
* Code generators for en_fix (e.g. for Approximations)
* Packages that help with fixed-point processing

# Dependencies

* Libraries/TCL/PsiSim
* Libraries/VHDL/psi_common
* Libraries/VHDL/psi_tb

# Simulations and Testbenches

For everything that is non-trivial, self-checking testbenches shall be provided to allow easy and safe reuse of 
the library elements. Testbenches shall check bittrueness by comparing outputs from the python model to VHDL outputs.

A regression test script for Modelsim is present. New Testbenches must therefore be added to the configuration of the 
regression test script *sim/config.tcl*.

To run the regression test, execute the following command in modelsim from within the directory *sim*

```
source ./run.tcl
```

# Fixed Point Number Format

The fixed point number format used in this library is defined as follows:

[s, i, f]

s:	1 = Signed number (two's complement), 0 = Unsigned number
i:  Number of integer bits
f:  Number of fractional bits

The total number of bits required is s+i+f. 

The value of each bit depending on its position relative to the binary point (i-bits left, f-bits right) is given below.

... [4][2][1]**.**[0.5][0.25][0.125] ...

Some examples are given below:

| Number Format | Range             | Bit Pattern  | Example Int | Example Bits |
|:-------------:|:-----------------:|:------------:|:-----------:|:------------:|
| [1,2,1]       | -4 ... +3.5       | sii.f        | -2.5        | 101.1        |
| [1,2,2]       | -4 ... +3.75      | sii.ff       | -2.5        | 101.10       |
| [0,4,0]       | 0 ... 15          | iiii.        | 5           | 0101.        |
| [0,4,2]       | 0 ... 15.75       | iiii.ff      | 5.25        | 0101.01      |
| [1,4,-2]      | -16 ... 12        | sii--.       | -8          | 110--.       |
| [1,-2,4]      | -0.25 ... +0.1875 | s.--ff       | 0.125       | 0.--10       |



