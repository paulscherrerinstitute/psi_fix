## 1.5.1

* Added Features
  * None
* Bugfixes
  * Fixed various small bugs that prevented the regression-test from succeeding on Linux
* Changed Dependencies
  * TCL/PsiSim >= 1.5.1 

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