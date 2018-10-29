## 1.9.1
* Added Features
  * None
* Bugfixes
  * Modify psi\_fix shift range checks in python models to work with np.ndarray instead of scalars

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