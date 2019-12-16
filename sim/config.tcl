##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Benoit Stef
##############################################################################

#Constants
set LibPath "../.."

#Import psi::sim
namespace import psi::sim::*

#Set library
add_library psi_fix

#suppress messages
compile_suppress 135,1236,1073
run_suppress 8684,3479,3813,8009,3812

#Run scripts that generate code before it is compilec
set old_dir [pwd]
cd ../testbench/psi_fix_lut_gen_tb/Script
exec python3 fir_design_test.py
cd $old_dir

# Library
add_sources $LibPath {
	en_cl_fix/vhdl/src/en_cl_fix_pkg.vhd \
    psi_common/hdl/psi_common_array_pkg.vhd \
	psi_common/hdl/psi_common_math_pkg.vhd \
	psi_common/hdl/psi_common_tdp_ram.vhd \
	psi_common/hdl/psi_common_logic_pkg.vhd \
	psi_common/hdl/psi_common_sdp_ram.vhd \
	psi_common/hdl/psi_common_delay.vhd \
	psi_common/hdl/psi_common_par_tdm.vhd \
	psi_common/hdl/psi_common_sync_fifo.vhd \
} -tag lib

# Library TB
add_sources $LibPath {
	en_cl_fix/vhdl/tb/en_cl_fix_pkg_tb.vhd \
} -tag libtb

# project sources
add_sources "../hdl" {
	psi_fix_pkg.vhd \
} -tag src

# Library
add_sources $LibPath {
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_tb/hdl/psi_tb_compare_pkg.vhd \
	psi_tb/hdl/psi_tb_textfile_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {
	psi_fix_fir_dec_ser_nch_chpar_conf.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf.vhd \
	psi_fix_mult_add_stage.vhd \
	psi_fix_fir_par_nch_chtdm_conf.vhd \
	psi_fix_fir_dec_semi_nch_chtdm_conf.vhd \
	psi_fix_lin_approx_calc.vhd \
	psi_fix_lin_approx_sin18b.vhd \
	psi_fix_lin_approx_sin18b_dual.vhd \
	psi_fix_lin_approx_sqrt18b.vhd \
	psi_fix_lin_approx_gaussify20b.vhd \
	psi_fix_cic_dec_fix_1ch.vhd \
	psi_fix_cic_int_fix_1ch.vhd \
	psi_fix_bin_div.vhd \
	psi_fix_dds_18b.vhd \
	psi_fix_lowpass_iir_order1.vhd \
	psi_fix_complex_mult.vhd \
	psi_fix_mov_avg.vhd \
	psi_fix_demod_real2cplx.vhd \
	psi_fix_cordic_vect.vhd \
	psi_fix_cordic_rot.vhd \
	psi_fix_pol2cart_approx.vhd \
	psi_fix_cic_dec_fix_nch_par_tdm.vhd \
	psi_fix_cic_dec_fix_nch_tdm_tdm.vhd \
	psi_fix_mod_cplx2real.vhd \
	psi_fix_complex_addsub.vhd \
	psi_fix_complex_abs.vhd \
	psi_fix_phase_unwrap.vhd \
	psi_fix_white_noise.vhd \
    psi_fix_noise_awgn.vhd \
    psi_fix_fir_3tap_hbw_dec2.vhd \
} -tag src

# testbenches
add_sources "../testbench" {
	psi_fix_pkg_tb/psi_fix_pkg_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_dual_tb.vhd \
	psi_fix_lin_approx_tb/sqrt18b/psi_fix_lin_approx_sqrt18b_tb.vhd \
	psi_fix_lin_approx_tb/gaussify20b/psi_fix_lin_approx_gaussify20b_tb.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case1_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb.vhd \
	psi_fix_fir_par_nch_chtdm_conf_tb/psi_fix_fir_par_nch_chtdm_conf_tb_coefs_pkg.vhd \
	psi_fix_fir_par_nch_chtdm_conf_tb/psi_fix_fir_par_nch_chtdm_conf_tb.vhd \
	psi_fix_fir_dec_semi_nch_chtdm_conf_tb/psi_fix_fir_dec_semi_nch_chtdm_conf_tb_coefs_pkg.vhd \
	psi_fix_fir_dec_semi_nch_chtdm_conf_tb/psi_fix_fir_dec_semi_nch_chtdm_conf_tb.vhd \
	psi_fix_bin_div_tb/psi_fix_bin_div_tb.vhd \
	psi_fix_cic_dec_fix_1ch_tb/psi_fix_cic_dec_fix_1ch_tb.vhd \
	psi_fix_cic_int_fix_1ch_tb/psi_fix_cic_int_fix_1ch_tb.vhd \
	psi_fix_dds_18b_tb/psi_fix_dds_18b_tb.vhd \
	psi_fix_lowpass_iir_order1_tb/psi_fix_lowpass_iir_order1_tb.vhd \
	psi_fix_complex_mult_tb/psi_fix_complex_mult_tb.vhd \
	psi_fix_mov_avg_tb/psi_fix_mov_avg_tb.vhd \
	psi_fix_demod_real2cplx_tb/psi_fix_demod_real2cplx_tb.vhd \
	psi_fix_cordic_vect_tb/psi_fix_cordic_vect_tb.vhd \
	psi_fix_cordic_rot_tb/psi_fix_cordic_rot_tb.vhd \
	psi_fix_pol2cart_approx_tb/psi_fix_pol2cart_approx_tb.vhd \
	psi_fix_cic_dec_fix_nch_par_tdm_tb/psi_fix_cic_dec_fix_nch_par_tdm_tb.vhd \
	psi_fix_cic_dec_fix_nch_tdm_tdm_tb/psi_fix_cic_dec_fix_nch_tdm_tdm_tb.vhd \
	psi_fix_mod_cplx2real_tb/psi_fix_mod_cplx2real_tb.vhd \
	psi_fix_lut_gen_tb/psi_fix_lut_test1.vhd \
	psi_fix_lut_gen_tb/psi_fix_lut_gen_tb.vhd \
	psi_fix_complex_addsub_tb/psi_fix_complex_addsub_tb.vhd \
	psi_fix_complex_abs_tb/psi_fix_complex_abs_tb.vhd \
	psi_fix_phase_unwrap_tb/psi_fix_phase_unwrap_tb.vhd \
	psi_fix_white_noise_tb/psi_fix_white_noise_tb.vhd \
    psi_fix_noise_awgn_tb/psi_fix_noise_awgn_tb.vhd \
    psi_fix_fir_3tap_hbw_dec2_tb/psi_fix_fir_3tap_hbw_dec2_tb.vhd \
} -tag tb
	
#TB Runs
create_tb_run "en_cl_fix_pkg_tb"
add_tb_run

create_tb_run "psi_fix_pkg_tb"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_dual_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_sqrt18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sqrt18b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_gaussify20b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/gaussify20b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Data"]
tb_run_add_arguments 	"-gStimuliPath_g=$dataDir -gDutyCycle_g=32 -gRamBehavior_g=RBW" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4 -gRamBehavior_g=RBW" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments 	"-gStimuliPath_g=$dataDir -gDutyCycle_g=32 -gRamBehavior_g=RBW" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4 -gRamBehavior_g=RBW" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4 -gRamBehavior_g=WBR"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb"
add_tb_run

create_tb_run "psi_fix_fir_par_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_par_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_par_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gChannels_g=1 -gTaps_g=48 -gClkPerSpl_g=1 -gUseFixCoefs_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=1 -gUseFixCoefs_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=1 -gTaps_g=48 -gClkPerSpl_g=5 -gUseFixCoefs_g=true" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=5 -gUseFixCoefs_g=true"
add_tb_run

create_tb_run "psi_fix_fir_dec_semi_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_semi_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_semi_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gChannels_g=1 -gTaps_g=48 -gClkPerSpl_g=10 -gUseFixCoefs_g=true -gMultipliers_g=8 -gRatio_g=3 -gRamBehavior_g=WBR -gFullInpRateSupport_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=10 -gUseFixCoefs_g=false  -gMultipliers_g=10 -gRatio_g=3 -gRamBehavior_g=RBW -gFullInpRateSupport_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=2 -gUseFixCoefs_g=true  -gMultipliers_g=8 -gRatio_g=3 -gRamBehavior_g=RBW -gFullInpRateSupport_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=2 -gTaps_g=160 -gClkPerSpl_g=2 -gUseFixCoefs_g=false  -gMultipliers_g=40 -gRatio_g=12 -gRamBehavior_g=RBW -gFullInpRateSupport_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=2 -gUseFixCoefs_g=true  -gMultipliers_g=24 -gRatio_g=1 -gRamBehavior_g=WBR -gFullInpRateSupport_g=false" \
						"-gFileFolder_g=$dataDir -gChannels_g=1 -gTaps_g=48 -gClkPerSpl_g=10 -gUseFixCoefs_g=false -gMultipliers_g=8 -gRatio_g=3 -gRamBehavior_g=WBR -gFullInpRateSupport_g=true" \
						"-gFileFolder_g=$dataDir -gChannels_g=1 -gTaps_g=48 -gClkPerSpl_g=1 -gUseFixCoefs_g=true -gMultipliers_g=16 -gRatio_g=3 -gRamBehavior_g=WBR -gFullInpRateSupport_g=true" \
						"-gFileFolder_g=$dataDir -gChannels_g=3 -gTaps_g=48 -gClkPerSpl_g=1 -gUseFixCoefs_g=false -gMultipliers_g=16 -gRatio_g=3 -gRamBehavior_g=WBR -gFullInpRateSupport_g=true"
add_tb_run


create_tb_run "psi_fix_bin_div_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_bin_div_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_bin_div_tb/Data"]
tb_run_add_arguments "-gDataDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_cic_dec_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_1ch_tb/Data"]
tb_run_add_arguments 	"-gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input_o3_r10_dd1_gcTrue.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=5" \
						"-gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input_o4_r9_dd2_gcTrue.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input_o4_r6_dd2_gcFalse.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=6 -gRatio_g=5001 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input_o6_r5001_dd2_gcTrue.txt -gOutFile_g=output_o6_r5001_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_int_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_int_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_int_fix_1ch_tb/Data"]
# Go through different configurations as well as through different handshaking siutations (input starving, output blocked, both)
tb_run_add_arguments 	"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir" \
						"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir" \
						"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir" \
						"-gInIdleCycles_g=20 -gOutIdleCycles_g=2 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir" \
						"-gInIdleCycles_g=2 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir" \
						"-gInIdleCycles_g=2 -gOutIdleCycles_g=20 -gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_dds_18b_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_dds_18b_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_dds_18b_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_c=$dataDir -gIdleCycles_g=0" \
						"-gFileFolder_c=$dataDir -gIdleCycles_g=5"
add_tb_run

create_tb_run "psi_fix_lowpass_iir_order1_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_lowpass_iir_order1_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_lowpass_iir_order1_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gPipeline_g=true" \
						"-gFileFolder_g=$dataDir -gPipeline_g=false"
add_tb_run

create_tb_run "psi_fix_complex_mult_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_mult_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_mult_tb/Data"]
set dataDir [file normalize "../testbench/psi_fix_complex_mult_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gPipeline_g=true -gClkPerSpl_g=1 -gFileFolder_g=$dataDir" \
						"-gFileFolder_g=$dataDir -gPipeline_g=false -gClkPerSpl_g=1 -gFileFolder_g=$dataDir" \
						"-gFileFolder_g=$dataDir -gPipeline_g=false -gClkPerSpl_g=5 -gFileFolder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_mov_avg_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_mov_avg_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_mov_avg_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gGainCorr_G=NONE -gDutyCycle_g=1 -gOutRegs_g=0" \
						"-gFileFolder_g=$dataDir -gGainCorr_G=EXACT -gDutyCycle_g=5 -gOutRegs_g=3" \
						"-gFileFolder_g=$dataDir -gGainCorr_G=ROUGH -gDutyCycle_g=3 -gOutRegs_g=1"
add_tb_run

create_tb_run "psi_fix_demod_real2cplx_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_demod_real2cplx_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_demod_real2cplx_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gDutyCycle_g=1" \
						"-gFileFolder_g=$dataDir -gDutyCycle_g=5"
add_tb_run

create_tb_run "psi_fix_cordic_vect_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cordic_vect_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_vect_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gGainComp_g=true -gRound_g=PsiFixRound -gSat_g=PsiFixSat -gMode_g=PIPELINED -gPlStgPerIter_g=1" \
						"-gFileFolder_g=$dataDir -gGainComp_g=true -gRound_g=PsiFixRound -gSat_g=PsiFixSat -gMode_g=PIPELINED -gPlStgPerIter_g=2" \
						"-gFileFolder_g=$dataDir -gGainComp_g=false -gRound_g=PsiFixTrunc -gSat_g=PsiFixWrap -gMode_g=PIPELINED -gPlStgPerIter_g=1" \
						"-gFileFolder_g=$dataDir -gGainComp_g=true -gRound_g=PsiFixRound -gSat_g=PsiFixSat -gMode_g=SERIAL" \
						"-gFileFolder_g=$dataDir -gGainComp_g=false -gRound_g=PsiFixTrunc -gSat_g=PsiFixWrap -gMode_g=SERIAL"
add_tb_run

create_tb_run "psi_fix_cordic_rot_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cordic_rot_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_rot_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gGainComp_g=true -gRound_g=PsiFixRound -gSat_g=PsiFixSat -gMode_g=PIPELINED" \
						"-gFileFolder_g=$dataDir -gGainComp_g=false -gRound_g=PsiFixTrunc -gSat_g=PsiFixWrap -gMode_g=PIPELINED" \
						"-gFileFolder_g=$dataDir -gGainComp_g=true -gRound_g=PsiFixRound -gSat_g=PsiFixSat -gMode_g=SERIAL" \
						"-gFileFolder_g=$dataDir -gGainComp_g=false -gRound_g=PsiFixTrunc -gSat_g=PsiFixWrap -gMode_g=SERIAL"
add_tb_run

create_tb_run "psi_fix_pol2cart_approx_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_pol2cart_approx_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_pol2cart_approx_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_cic_dec_fix_nch_par_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb/Data"]
tb_run_add_arguments 	"-gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input_o3_r10_dd1_gcTrue.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=5" \
						"-gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input_o4_r9_dd2_gcTrue.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input_o4_r6_dd2_gcFalse.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_dec_fix_nch_tdm_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_nch_tdm_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_nch_tdm_tdm_tb/Data"]
tb_run_add_arguments 	"-gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input_o3_r10_dd1_gcTrue.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=5" \
						"-gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input_o4_r9_dd2_gcTrue.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input_o4_r6_dd2_gcFalse.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0"

add_tb_run

create_tb_run "psi_fix_mod_cplx2real_tb"
tb_run_add_pre_script "python3" "psi_fix_mod_cplx2real_app.py" "../testbench/psi_fix_mod_cplx2real_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_mod_cplx2real_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir -gClkPerSpl_g=1 -gPlStages_g=5" \
						"-gFileFolder_g=$dataDir -gClkPerSpl_g=1 -gPlStages_g=6" \
						"-gFileFolder_g=$dataDir -gClkPerSpl_g=10 -gPlStages_g=5" \
						"-gFileFolder_g=$dataDir -gClkPerSpl_g=10 -gPlStages_g=6"
#Skipped for GHDL because of bug in GHDL (sin() is not 100% bittrue)
tb_run_skip GHDL
add_tb_run

create_tb_run "psi_fix_lut_gen_tb"
#Pre-Script is executed prior to compilation because it geenrates code to be compiled
set dataDir [file normalize "../testbench/psi_fix_lut_gen_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_complex_addsub_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_addsub_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_addsub_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_complex_abs_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_abs_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_abs_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_phase_unwrap_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_phase_unwrap_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_phase_unwrap_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir -gStimuliSet_g=S -gVldDutyCycle_g=5" \
					 "-gFileFolder_g=$dataDir -gStimuliSet_g=U -gVldDutyCycle_g=5" \
					 "-gFileFolder_g=$dataDir -gStimuliSet_g=S -gVldDutyCycle_g=1"
add_tb_run

create_tb_run "psi_fix_white_noise_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_white_noise_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_white_noise_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir -gStimuliSet_g=S -gVldDutyCycle_g=5" \
					 "-gFileFolder_g=$dataDir -gStimuliSet_g=U -gVldDutyCycle_g=5" \
					 "-gFileFolder_g=$dataDir -gStimuliSet_g=S -gVldDutyCycle_g=1"
add_tb_run

create_tb_run "psi_fix_noise_awgn_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_noise_awgn_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_noise_awgn_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir -gVldDutyCycle_g=5" \
					 "-gFileFolder_g=$dataDir -gVldDutyCycle_g=1"
add_tb_run


create_tb_run "psi_fix_fir_3tap_hbw_dec2_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_3tap_hbw_dec2_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_3tap_hbw_dec2_tb/Data"]
tb_run_add_arguments "-gFileFolder_g=$dataDir -gVldDutyCycle_g=5 -gChannels_g=1 -gInFile_g=inChannels1SeparateTrue.txt -gOutFile_g=outChannels1SeparateTrue.txt"  \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=1 -gChannels_g=2 -gSeparate_g=false -gInFile_g=inChannels2SeparateFalse.txt -gOutFile_g=outChannels2SeparateFalse.txt" \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=5 -gChannels_g=4 -gSeparate_g=false -gInFile_g=inChannels4SeparateFalse.txt -gOutFile_g=outChannels4SeparateFalse.txt" \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=1 -gChannels_g=1 -gInFile_g=inChannels1SeparateTrue.txt -gOutFile_g=outChannels1SeparateTrue.txt" \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=1 -gChannels_g=2 -gInFile_g=inChannels2SeparateTrue.txt -gOutFile_g=outChannels2SeparateTrue.txt" \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=5 -gChannels_g=2 -gInFile_g=inChannels2SeparateTrue.txt -gOutFile_g=outChannels2SeparateTrue.txt" \
    "-gFileFolder_g=$dataDir -gVldDutyCycle_g=5 -gChannels_g=4 -gInFile_g=inChannels4SeparateTrue.txt -gOutFile_g=outChannels4SeparateTrue.txt"
    

add_tb_run





