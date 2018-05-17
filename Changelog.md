## 1.4.0 [TO BE RELEASED]

* Added Features
  * None
* Changes
  * Changed some TBs to use the new psi_tb_textfile_pkg (including the automatically generated psi_fix_lin_appprox testbenches)
* Bugfixes
  * None
* Changed Dependencies
  * psi_tb >= 1.1.0

## 1.3.0

* Added Features
  * Added support for constant coeefficients to FIR filters (psi_fix_fir_dec_ser_nch_chpar_conf, psi_fix_fir_dec_ser_nch_chtdm_conf)
* Bugfixes
  * None
* Changed Dependencies
  * None

## 1.2.0

* Added Features
  * Implemented single-channel CIC decimator for fixed ratio (psi_fix_cic_dec_fix_1ch)
  * Implemented single channel CIC interpolator for fixed ratio (psi_fix_cic_int_fix_1ch)
  * Implemented 18-bit DDS (psi_fix_dds_18b)
  * Added interface functions and example for usage of the Python models from MATLAB
  * Added parameter to psi_fix_cordic_abs_pl to select the amount of pipelining
  * Added documentation of all library elements 
* Bugfixes
  * None
* Changed Dependencies
  * psi_common >= 1.2.0

## V1.01

* Added Features
  * Added multi-channel serial decimating FIR that calculates channels TDM
  * Added binary division
* Bugfixes
  * None

## V1.00
* First release