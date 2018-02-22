#Constants
set LibPath "../.."

#Import psi::sim
namespace import psi::sim::*

#Set library
add_library psi_fix

#suppress messages
compile_suppress 135,1236
run_suppress 8684,3479,3813,8009,3812

# Library
add_sources $LibPath {
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_tb/hdl/psi_tb_compare_pkg.vhd \
	psi_common/hdl/psi_common_math_pkg.vhd \
	psi_common/hdl/psi_common_tdp_ram_rbw.vhd \
	psi_common/hdl/psi_common_array_pkg.vhd \
	psi_common/hdl/psi_common_logic_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {
	psi_fix_pkg.vhd \
	psi_fix_cordic_abs_pl.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf.vhd \
	psi_fix_lin_approx_calc.vhd \
	psi_fix_lin_approx_sin18b.vhd \
	psi_fix_lin_approx_sin18b_dual.vhd \
	psi_fix_cic_dec_fix_1ch.vhd \
	psi_fix_cic_int_fix_1ch.vhd \
	psi_fix_bin_div.vhd \
	psi_fix_dds_18b.vhd \
} -tag src

# testbenches
add_sources "../testbench" {
	psi_fix_pkg_tb/psi_fix_pkg_tb.vhd \
	psi_fix_cordic_abs_pl_tb/psi_fix_cordic_abs_pl_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_dual_tb.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case0_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb_case1_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chtdm_conf_tb/psi_fix_fir_dec_ser_nch_chtdm_conf_tb.vhd \
	psi_fix_bin_div_tb/psi_fix_bin_div_tb.vhd \
	psi_fix_cic_dec_fix_1ch_tb/psi_fix_cic_dec_fix_1ch_tb.vhd \
	psi_fix_cic_int_fix_1ch_tb/psi_fix_cic_int_fix_1ch_tb.vhd \
	psi_fix_dds_18b_tb/psi_fix_dds_18b_tb.vhd \
} -tag tb
	
#TB Runs
create_tb_run "psi_fix_pkg_tb"
add_tb_run

create_tb_run "psi_fix_cordic_abs_pl_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cordic_abs_pl_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_abs_pl_tb/Data"]
tb_run_add_arguments "-gDataDir_g=$dataDir -gPipelineFactor_g=1" \
					 "-gDataDir_g=$dataDir -gPipelineFactor_g=4" \
					 "-gDataDir_g=$dataDir -gPipelineFactor_g=100"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_dual_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gStimuliDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Data"]
tb_run_add_arguments 	"-gStimuliPath_g=$dataDir -gDutyCycle_g=32" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments 	"-gStimuliPath_g=$dataDir -gDutyCycle_g=32" \
						"-gStimuliPath_g=$dataDir -gDutyCycle_g=4"
add_tb_run

create_tb_run "psi_fix_bin_div_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_bin_div_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_bin_div_tb/Data"]
tb_run_add_arguments "-gDataDir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_cic_dec_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_1ch_tb/Data"]
tb_run_add_arguments 	"-gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input_o3_r10_dd1_gcTrue.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input_o4_r9_dd2_gcTrue.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input_o4_r6_dd2_gcFalse.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_int_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_int_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_int_fix_1ch_tb/Data"]
# Go through different configurations as well as through different handshaking siutations (input starving, output blocked, both)
tb_run_add_arguments 	"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=9 -gDiffDelay_g=2 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o4_r9_dd2_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gInIdleCycles_g=0 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gInIdleCycles_g=20 -gOutIdleCycles_g=2 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gInIdleCycles_g=2 -gOutIdleCycles_g=0 -gOrder_g=4 -gRatio_g=6 -gDiffDelay_g=2 -gAutoGainCorr_g=False -gInFile_g=input.txt -gOutFile_g=output_o4_r6_dd2_gcFalse.txt -gDataDir_g=$dataDir -gIdleCycles_g=0" \
						"-gInIdleCycles_g=2 -gOutIdleCycles_g=20 -gOrder_g=3 -gRatio_g=10 -gDiffDelay_g=1 -gAutoGainCorr_g=True -gInFile_g=input.txt -gOutFile_g=output_o3_r10_dd1_gcTrue.txt -gDataDir_g=$dataDir -gIdleCycles_g=0"
add_tb_run

create_tb_run "psi_fix_dds_18b_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_dds_18b_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_dds_18b_tb/Data"]
tb_run_add_arguments 	"-gFileFolder_c=$dataDir -gIdleCycles_g=0" \
						"-gFileFolder_c=$dataDir -gIdleCycles_g=5"
add_tb_run




