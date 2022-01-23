## 3.2.0
* Added Features
  * Added wide fixed-point support for Python (>53 bits)
* Changed Dependencies
  * en\_cl\_fix >= 1.2.0


## 3.1.0
* Added Features
  * Added psi\_fix\_nch\_analog\_trigger\_tdm
  * Added psi\_fix\_comparator
* Changed Dependencies
  * psi\_common >= 2.15.0
   

## 3.0.0
* Changes (not reverse compatiable)
  * In FIR filters renamed generic FixCoefs\_g to Coefs\_g
* Added Features
  * Added support for numbers bigger than 32 bits
  * PsiFixFmtFromString
  * In psi\_fix\_complex\_mult added option to save resources when multiplication is Complex x Real
  * In psi\_fix\_fir\_dec\_semi\_nch\_chtdm\_conf added flushing interface 
  * In FIR filters added CalcOngoing output
  * In psi\_fix\_fir\_dec\_semi\_nch\_chtdm\_conf allow writing coefficients during reset
  * In CIC filters added status output 
    * This feature allows higher level algorithms to detect if they still expect output from the CIC or if the CIC is currently idling.
  * Implemented pipeline psi\_fix\_resize (psi\_fix\_resize.vhd)
  * In psi\_fix\_dds\_18b added multi channel TDM support
  * In PsiFixFmt added warning if input exceeds the limit of bittrueness
  * Implemented psi\_fix\_cic\_dec\_cfg\_1ch
  * Implemented psi\_fix\_cic\_dec\_cfg\_nch\_par\_tdm
  * Implemented psi\_fix\_cic\_dec\_cfg\_nch\_tdm\_tdm
  * Implemented psi\_fix\_sqrt
  * Added Matlab functions to convert fixed point formats between psi and en\_cl conventions conveniently (fix\_cl2psi.m and fix\_psi2cl.m)
  * Implemented psi\_fix\_inv (inversion 1/x)
* Bugfixes
  * In serial FIR filters fixed replacement of outdated data by zero
  * In psi\_fix\_fir\_dec\_ser\_nch\_chtdm\_conf fixed behavior after reset
  * In psi\_fix\_fir\_dec\_semi\_nch\_chtdm\_conf prevented wrong behavior for large intermediate result
* Improved timing
  * In psi\_fix\_fir\_dec\_ser\_nch\_chpar\_conf by splitting round & saturate into two stages at the output
  * In psi\_fix\_fir\_dec\_ser\_nch\_chtdm\_conf by splitting round & saturate into two stages at the output
* Changed Dependencies
  * psi\_common >= 2.13.0
  * en\_cl\_fix >= 1.1.8


## 2.4.1
* Changed Dependencies
  * psi\_tb >= 2.5.0

## 2.4.0

* Added Features
  * Implemented psi\_fix\_mult\_add\_stage (multiply-add stage)
  * Implemented psi\_fix\_fir\_par\_nch\_chtdm\_conf (fully parallel FIR filter)
  * Implemented psi\_fix\_fir\_dec\_semi\_nch\_chtdm\_conf (semi parallel TDM-multi-channel FIR filter)
  * Implemented psi\_fix\_fir\_3tap\_hbw\_dec2 (decimating by 2 half-bandwidth filter)
  * In psi\_fix\_mod\_cplx2real added option for additional pipeline stage for better timing performance
* Improvements
  * In psi\_fix\_cic\_int\_fix\_1ch added more pipeline registers for gain compensation to improve timing
* Changed Dependencies
  * psi\_common >= 2.5.1

## 2.3.3

* Bugfixes
  *  For *psi\_fix\_lin\_approx* the Design mode of the python modl did crash for signed input ranges (no effect on implementation) 

## 2.3.2

* Added Features
  * Added dependency resolution script
* Bugfixes
  * Fixed simulation mismatch for CIC filters with high gain
* Changed Dependencies
  * psi\_common >= 2.5.0

## 2.3.1

* Added Features
  * none
* Bugfixes
  * Fixed stimuli file name in psi\_fix\_white\_noise TB to also work on linux (case was incorrect)

## 2.3.0

* Added Features
  * Implemented psi\_fix\_white\_noise (white noise generator, uniform distribution)
  * Implemented psi\_fix\_noise\_awgn (white noise generator, gaussian distribution)
* Bugfixes
  * Made GHDL simulation working by skipping psi\_fix\_mod\_cplx2real (only in GHDL) because it fails due to a GHDL bug.
* Changed Dependencies
  * PsiSim >= 2.1.0
  * en\_cl\_fix >= 1.1.2

## 2.2.0

* Added Features
  * Implemented psi\_fix\_phase\_unwrap (phase unwrapping)
  * Added multi channel support for psi\_fix\_demod\_real2cplx
* Bugfixes
  * None

## 2.1.0

* Added Features
  * Implemented psi\_fix\_complex\_abs (absolute value calculation using sum of squares)
  * Added more documentation (power point presentation)
* Bugfixes
  * PsiFixShiftLeft/Right range checks in Python did not work for nd.array type
  * Remove GHDL binary files from GIT
  * CIC Python model did not work when the output of the filter was at the absolute lower bound

## 2.0.0

* First open Source Release
* Added Features
  * Support GHDL as Simulator
  * Added psi\_fix\_complex\_addsub
* Changes (not reverse compatiable)
  * Switched to open source version of all dependencies (not reverse compatible)
  * Modified entity and port names for better consistency
  * Use en\_cl\_fix package from Enclustra for fixed point math
  * Removed psi\_fix\_cordic\_abs\_pl (deprecated since 1.8.0)
* Changed Dependencies
  * PsiSim >= 2.0.0
  * en\_cl\_fix >= 1.1.1
  * psi\_common >= 2.0.0

## 1.9.0

* Added Features
  * Add PsiFixCompare function for to psi\_fix\_pkg (comparison of two fixed-point numbers with individual formats)
* Bugfixes
  * Made decimatin FIR filters working with MaxRatio\_g=1
  * Added pipeline stage to CIC gain correction multiplier to relax timing
  * Fixed behavior of psi\_fix\_cic\_int\_fix\_1ch for 100% output duty cycle
  * Fixed bittrueness issue in psi\_fix\_pol2cart\_approx

## 1.8.0

* Added Features
  * Added psi\_fix\_lut (python based VHDL code generator for LUTs, including simulation model)
  * Added psi\_fix\_pkg\_writer (python based VHDL package generator to pass constants from python to VHDL)
* Bugfixes and Improvements
  * Timing optimization in the cectoring cordic
* Deprecated features
  * psi\_fix\_cordic\_abs\_pl is deprecated (can be replaced by psi\_fix\_cordic\_vect)

## 1.7.1 

* Added Features
  * None
* Bugfixes
  * Rewrote psi\_fix\_complex\_mult since it had an unclean interface and it contained errors in the strobe handling.
  * Bugfixes for psi\_fix\_mod\_cplx2real: Strobe handling was incorrect
  * Miscellaneous timing optimizations

## 1.7.0

* Added Features
  * Added psi\_fix\_mod\_cplx2real (modulator with complex input and real output)
* Bugfixes
  * Improved timing of psi\_fix\_cordic\_vect (has now one cycle more delay)
  * Improved timing of psi\_fix\_complex\_mult (only round at the very output)
  * Updated compile scripts to work with psi\_common >= 1.10.0

## 1.6.0

* Added Features
  * Added psi\_fix\_lin\_approx\_sqrt18b (approximation of the square-root function)
  * Added psi\_fix\_cic\_dec\_fix\_nch\_par\_tdm (multi-channel CIC filter with parallel input and TDM output)
  * Added psi\_fix\_cic\_dec\_fix\_nch\_tdm\_tdm (multi-channel CIC filter with TDM input and output)
* Bugfixes
  * Fixed bugs in psi\_fix\_lin\_approx that prevented the sqrt approximation from working. These issues do not affect the existing approximation (sine).
  * Fixed meismatch between model and implementation for psi\_fix\_complex\_mult
* Changed Dependencies
  * psi\_common >= 1.9.0

## 1.5.1

* Added Features
  * None
* Bugfixes
  * Fixed various small bugs that prevented the regression-test from succeeding on Linux
* Changed Dependencies
  * TCL/PsiSim >= 1.3.1 

## 1.5.0

* Added Features
  * Added psi\_fix\_cordic\_vect (vectoring CORDIC for cart to polar converation)
  * Added psi\_fix\_cordic\_rot (rotating CORDIC for polar to cartesian conversion)
  * Added psi\_fix\_pol2cart\_approx (sine-approximation based polar to cartesian conversion)
* Bugfixes
  * Change PsiFixShiftLeft() and PsiFixShiftRight() to support dynamic shifts
  * Fixed integer overflow in PsiFixShiftLeft() and PsiFixShiftRight()
* Changed Dependencies
  * psi\_common >= 1.6.0

## 1.4.0 

* Added Features
  * Added psi\_fix\_lowpass\_iir\_order1 (order 1 lowpass with integrated coefficient calculation)
  * Added psi\_fix\_complex\_mult (multiplication of two complex numbers) 
  * Added psi\_fix\_demod\_real2cplx (demodulator with real input and complex output)
  * Added psi\_fix\_mov\_avg (moving average with different gain correction options)
* Changes
  * Changed some TBs to use the new psi\_tb\_textfile\_pkg (including the automatically generated psi\_fix\_lin\_appprox testbenches)
* Bugfixes
  * None
* Changed Dependencies
  * psi\_tb >= 1.1.0
  * psi\_common >= 1.5.0

## 1.3.0

* Added Features
  * Added support for constant coeefficients to FIR filters (psi\_fix\_fir\_dec\_ser\_nch\_chpar\_conf, psi\_fix\_fir\_dec\_ser\_nch\_chtdm\_conf)
* Bugfixes
  * None
* Changed Dependencies
  * None

## 1.2.0

* Added Features
  * Implemented single-channel CIC decimator for fixed ratio (psi\_fix\_cic\_dec\_fix\_1ch)
  * Implemented single channel CIC interpolator for fixed ratio (psi\_fix\_cic\_int\_fix\_1ch)
  * Implemented 18-bit DDS (psi\_fix\_dds\_18b)
  * Added interface functions and example for usage of the Python models from MATLAB
  * Added parameter to psi\_fix\_cordic\_abs\_pl to select the amount of pipelining
  * Added documentation of all library elements 
* Bugfixes
  * None
* Changed Dependencies
  * psi\_common >= 1.2.0

## V1.01

* Added Features
  * Added multi-channel serial decimating FIR that calculates channels TDM
  * Added binary division
* Bugfixes
  * None

## V1.00
* First release
