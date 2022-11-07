<img align="right" src="../../doc/psi_logo.png">

***

Prior to use the library following readings are recommended.

**[1 Introduction](Introduction.md)**

**[2 Tips and tricks with psi_fix](tips.md)**

**[3 Design Flow](design_flow.md)**



# List of compoments

Component 				                               | Source                                                                    | Description
-------------------------------------------------|---------------------------------------------------------------------------|:-------------------------------------------:
Binary division 																 | [psi_fix_bin_div.vhd](../../hdl/psi_fix_bin_div.vhd)	 		 									 | [link](psi_fix_bin_div.md)
Filter CIC Decimation 1 channel configurable   	 | [psi_fix_cic_dec_cfg_1ch.vhd](../../hdl/psi_fix_cic_dec_cfg_1ch.vhd)	 	  	 | [link](psi_fix_cic_dec_cfg_1ch.md)
Filter CIC Decimation N channels parallel input Tdm output configurable   	 | [psi_fix_cic_dec_cfg_nch_par_tdm.vhd](../../hdl/psi_fix_cic_dec_cfg_nch_par_tdm.vhd)	 	  	 | [link](psi_fix_cic_dec_cfg_nch_par_tdm.md)  
Filter CIC Decimation N channels Tdm input Tdm output configurable   	 | [psi_fix_cic_dec_cfg_nch_tdm_tdm.vhd](../../hdl/psi_fix_cic_dec_cfg_nch_tdm_tdm.vhd)	 	  	 | [link](psi_fix_cic_dec_cfg_nch_tdm_tdm.md)  
Filter CIC Decimation 1 channel fixed parameters (generics)  	 | [psi_fix_cic_dec_fix_1ch.vhd](../../hdl/psi_fix_cic_dec_fix_1ch.vhd)	 	  	 | [link](psi_fix_cic_dec_fix_1ch.md)  
Filter CIC Decimation N channels parallel input Tdm output fixed parameters (generics)   	 | [psi_fix_cic_dec_fix_nch_par_tdm.vhd](../../hdl/psi_fix_cic_dec_fix_nch_par_tdm.vhd)	 	  	 | [link](psi_fix_cic_dec_fix_nch_par_tdm.md)  
Filter CIC Decimation N channels  Tdm input Tdm output fixed parameters (generics)  	 | [psi_fix_cic_dec_fix_nch_tdm_tdm.vhd](../../hdl/psi_fix_cic_dec_fix_nch_tdm_tdm.vhd)	 	  	 | [link](psi_fix_cic_dec_fix_nch_tdm_tdm.md)  
Filter CIC Interpolation 1 channel fixed parameters   	 | [psi_fix_cic_int_fix_1ch.vhd](../../hdl/psi_fix_cic_int_fix_1ch.vhd)	 	  	 | [link](psi_fix_cic_int_fix_1ch.md)  
Simple comparator with unique FP format  | [psi_fix_comparator.vhd](../../hdl/psi_fix_comparator.vhd)   | [link](psi_fix_comparator.md)   
Complex amplitude calculation (no cordic)  |   [psi_fix_complex_abs.vhd](../../hdl/psi_fix_complex_abs.vhd)   | [link](psi_fix_complex_abs.md)  
Complex adder or subtractor   |  [psi_fix_complex_addsub.vhd](../../hdl/psi_fix_complex_addsub.vhd)   | [link](psi_fix_complex_addsub.md)   
Complex multiplier  | [psi_fix_complex_mult.vhd](../../hdl/psi_fix_complex_mult.vhd)   | [link](psi_fix_complex_mult.md)   
CORDIC rotation mode Polar to Cartesian - Parallel/Serial mode | [psi_fix_cordic_rot.vhd](../../hdl/psi_fix_cordic_rot.vhd)   | [link](psi_fix_cordic_rot.md)  
CORDIC vector mode Cartesian to Polar - Parallel/Serial mode | [psi_fix_cordic_vect.vhd](../../hdl/psi_fix_cordic_vect.vhd)   | [link](psi_fix_cordic_vect.md)
DDS 18bits fixed output | [psi_fix_dds_18b.vhd](../../hdl/psi_fix_dds_18b.vhd)   | [link](psi_fix_dds_18b.md)   
Non IQ demodulator with phase offset input and fixed non-integer ratio (generics) | [psi_fix_demod_real2cplx.vhd](../../hdl/psi_fix_demod_real2cplx.vhd)    | [link](psi_fix_demod_real2cplx.md)  
Non IQ modulator with phase offset input and fixed non-integer ratio (generics) | [psi_fix_mod_cplx2real.vhd](../../hdl/psi_fix_mod_cplx2real.vhd)    | [link](psi_fix_mod_cplx2real.md)   
LP Filter Half-bandwidth 0.25 0.5 0.25 and decimation by 2 (without using multipliers)  | [psi_fix_fir_3tap_hbw_dec2.vhd](../../hdl/psi_fix_fir_3tap_hbw_dec2.vhd)    | [link](psi_fix_fir_3tap_hbw_dec2.md)
1/2 MAC FIR filter *decimation with optimized used of resources configurable  | [psi_fix_fir_dec_semi_nch_chtdm_conf.vhd](../../hdl/psi_fix_fir_dec_semi_nch_chtdm_conf.vhd)    | [link](psi_fix_fir_dec_semi_nch_chtdm_conf.md)   
MAC FIR filter *decimation N Channels input parallel configurable  | [psi_fix_fir_dec_ser_nch_chpar_conf.vhd](../../hdl/psi_fix_fir_dec_ser_nch_chpar_conf.vhd)    | [link](psi_fix_fir_dec_ser_nch_chpar_conf.md)   
MAC FIR filter *decimation N Channels input Tdm configurable  | [psi_fix_fir_dec_ser_nch_chtdm_conf.vhd](../../hdl/psi_fix_fir_dec_ser_nch_chtdm_conf.vhd)    | [link](psi_fix_fir_dec_ser_nch_chtdm_conf.md)   
Direct FIR filter N Channels input Tdm configurable  | [psi_fix_fir_par_nch_chtdm_conf.vhd](../../hdl/psi_fix_fir_par_nch_chtdm_conf.vhd)    | [link](psi_fix_fir_par_nch_chtdm_conf.md)   
1/X inversion calculation  | [psi_fix_inv.vhd](../../hdl/psi_fix_inv.vhd)    | [link](psi_fix_inv.md)   
Linear approximation calculation, to be used with table generated from python (sin/sqrt)  |  [psi_fix_lin_approx_calc.vhd](../../hdl/psi_fix_lin_approx_calc.vhd)    | [link](psi_fix_lin_approx_calc.md)   
Gaussify function in a 20bit width & 1024 depth LUT  | [psi_fix_lin_approx_gaussify20b.vhd](../../hdl/psi_fix_lin_approx_gaussify20b.vhd)    | [link](psi_fix_lin_approx_gaussify20b.md)     
IIR 1st Order fixed parameters (generics) | [psi_fix_lowpass_iir_order1.vhd](../../hdl/psi_fix_lowpass_iir_order1.vhd)    | [link](psi_fix_lowpass_iir_order1.md)   
IIR 1st Order configurable  | [psi_fix_lowpass_iir_order1_cfg.vhd](../../hdl/psi_fix_lowpass_iir_order1_cfg.vhd)    | [link](psi_fix_lowpass_iir_order1_cfg.md)     
Moving average filter | [psi_fix_mov_avg.vhd](../../hdl/psi_fix_mov_avg.vhd)    | [link](psi_fix_mov_avg.md)    
Polar to cartesian approximation  |  [psi_fix_pol2cart_approx.vhd](../../hdl/psi_fix_pol2cart_approx.vhd)    | [link](psi_fix_pol2cart_approx.md)     
SQRT function  |  [psi_fix_sqrt.vhd](../../hdl/psi_fix_sqrt.vhd)    | [link](psi_fix_sqrt.md)    

# Misc
