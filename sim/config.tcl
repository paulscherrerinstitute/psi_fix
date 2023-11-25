##############################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Benoit Stef, Radoslaw Rybaniec
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
  psi_common/hdl/psi_common_dyn_sft.vhd \
  psi_common/hdl/psi_common_tdm_par.vhd \
  psi_common/hdl/psi_common_tdm_par.vhd \
  psi_common/hdl/psi_common_pl_stage.vhd \
  psi_common/hdl/psi_common_multi_pl_stage.vhd \
  psi_common/hdl/psi_common_trigger_digital.vhd \
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
  psi_tb/hdl/psi_tb_activity_pkg.vhd \
} -tag lib

# project sources
add_sources "../hdl" {
  psi_fix_resize_pipe.vhd \
  psi_fix_param_ram.vhd \
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
  psi_fix_lin_approx_inv18b.vhd \
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
  psi_fix_cic_dec_cfg_1ch.vhd \
  psi_fix_cic_dec_cfg_nch_par_tdm.vhd \
  psi_fix_cic_dec_cfg_nch_tdm_tdm.vhd \
  psi_fix_sqrt.vhd \
  psi_fix_inv.vhd \
  psi_fix_comparator.vhd \
  psi_fix_nch_analog_trigger_tdm.vhd \
  psi_fix_matrix_mult.vhd \
  psi_fix_ss_solver.vhd
} -tag src

# testbenches
add_sources "../testbench" {
  psi_fix_pkg_tb/psi_fix_pkg_tb.vhd \
  psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_tb.vhd \
  psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_dual_tb.vhd \
  psi_fix_lin_approx_tb/sqrt18b/psi_fix_lin_approx_sqrt18b_tb.vhd \
  psi_fix_lin_approx_tb/gaussify20b/psi_fix_lin_approx_gaussify20b_tb.vhd \
  psi_fix_lin_approx_tb/inv18b/psi_fix_lin_approx_inv18b_tb.vhd \
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
  psi_fix_resize_pipe_tb/psi_fix_resize_pipe_tb.vhd \
  psi_fix_param_ram_tb/psi_fix_param_ram_tb.vhd \
  psi_fix_cic_dec_cfg_1ch_tb/psi_fix_cic_dec_cfg_1ch_tb.vhd \
  psi_fix_cic_dec_cfg_nch_par_tdm_tb/psi_fix_cic_dec_cfg_nch_par_tdm_tb.vhd \
  psi_fix_cic_dec_cfg_nch_tdm_tdm_tb/psi_fix_cic_dec_cfg_nch_tdm_tdm_tb.vhd \
  psi_fix_sqrt_tb/psi_fix_sqrt_tb.vhd \
  psi_fix_inv_tb/psi_fix_inv_tb.vhd \
  psi_fix_comparator_tb/psi_fix_comparator_tb.vhd \
  psi_fix_nch_analog_trigger_tdm_tb/psi_fix_nch_analog_trigger_tdm_tb.vhd \
  psi_fix_matrix_mult_tb/psi_fix_matrix_mult_tb.vhd \
  psi_fix_ss_solver_tb/psi_fix_ss_solver_tb.vhd 
} -tag tb
  
#TB Runs
create_tb_run "en_cl_fix_pkg_tb"
add_tb_run

create_tb_run "psi_fix_pkg_tb"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gstimuli_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_sin18b_dual_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
tb_run_add_arguments "-gstimuli_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_sqrt18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sqrt18b"]
tb_run_add_arguments "-gstimuli_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_gaussify20b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/gaussify20b"]
tb_run_add_arguments "-gstimuli_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_lin_approx_inv18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/inv18b"]
tb_run_add_arguments "-gstimuli_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Data"]
tb_run_add_arguments   "-gstimuli_path_g=$dataDir -gduty_cycle_g=32 -gram_behavior_g=RBW" \
            "-gstimuli_path_g=$dataDir -gduty_cycle_g=4 -gram_behavior_g=RBW" \
            "-gstimuli_path_g=$dataDir -gduty_cycle_g=4 -gram_behavior_g=WBR"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_fix_coef_tb"
tb_run_add_arguments   "-gtest_ram_init_g=true" \
            "-gtest_ram_init_g=false"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments   "-gstimuli_path_g=$dataDir -gduty_cycle_g=32 -gram_behavior_g=RBW" \
            "-gstimuli_path_g=$dataDir -gduty_cycle_g=4 -gram_behavior_g=RBW" \
            "-gstimuli_path_g=$dataDir -gduty_cycle_g=4 -gram_behavior_g=WBR"
add_tb_run

create_tb_run "psi_fix_fir_dec_ser_nch_chtdm_conf_fix_coef_tb"
tb_run_add_arguments   "-gtest_ram_init_g=true" \
            "-gtest_ram_init_g=false"
add_tb_run

create_tb_run "psi_fix_fir_par_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_par_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_par_nch_chtdm_conf_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gchannels_g=1 -gtaps_g=48 -gclk_per_spl_g=1 -guse_fix_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=1 -guse_fix_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=1 -gtaps_g=48 -gclk_per_spl_g=5 -guse_fix_coefs_g=true" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=5 -guse_fix_coefs_g=true"
add_tb_run

create_tb_run "psi_fix_fir_dec_semi_nch_chtdm_conf_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_dec_semi_nch_chtdm_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_semi_nch_chtdm_conf_tb/Data"]
tb_run_add_time_limit "5000 us"
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gchannels_g=1 -gtaps_g=48 -gclk_per_spl_g=10 -guse_fix_coefs_g=true -gmultipliers_g=8 -gratio_g=3 -gram_behavior_g=WBR -gfull_inp_rate_support_g=false -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=10 -guse_fix_coefs_g=false  -gmultipliers_g=10 -gratio_g=3 -gram_behavior_g=RBW -gfull_inp_rate_support_g=false -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=2 -guse_fix_coefs_g=true  -gmultipliers_g=8 -gratio_g=3 -gram_behavior_g=RBW -gfull_inp_rate_support_g=false -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=2 -gtaps_g=160 -gclk_per_spl_g=2 -guse_fix_coefs_g=false  -gmultipliers_g=40 -gratio_g=12 -gram_behavior_g=RBW -gfull_inp_rate_support_g=false -ginit_coefs_g=true" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=2 -guse_fix_coefs_g=true  -gmultipliers_g=24 -gratio_g=1 -gram_behavior_g=WBR -gfull_inp_rate_support_g=false -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=1 -gtaps_g=48 -gclk_per_spl_g=10 -guse_fix_coefs_g=false -gmultipliers_g=8 -gratio_g=3 -gram_behavior_g=WBR -gfull_inp_rate_support_g=true -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=1 -gtaps_g=48 -gclk_per_spl_g=1 -guse_fix_coefs_g=true -gmultipliers_g=16 -gratio_g=3 -gram_behavior_g=WBR -gfull_inp_rate_support_g=true -ginit_coefs_g=false" \
            "-gfile_folder_g=$dataDir -gchannels_g=3 -gtaps_g=48 -gclk_per_spl_g=1 -guse_fix_coefs_g=false -gmultipliers_g=16 -gratio_g=3 -gram_behavior_g=WBR -gfull_inp_rate_support_g=true -ginit_coefs_g=false"
add_tb_run


create_tb_run "psi_fix_bin_div_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_bin_div_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_bin_div_tb/Data"]
tb_run_add_arguments "-gdata_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_cic_dec_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_1ch_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=6 -gratio_g=5001 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o6_r5001_dd2_gcTrue.txt -gout_file_g=output_o6_r5001_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_int_fix_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_int_fix_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_int_fix_1ch_tb/Data"]
# Go through different configurations as well as through different handshaking siutations (input starving, output blocked, both)
tb_run_add_arguments   "-gin_idle_cycles_g=0 -gout_idle_cycles_g=0 -gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir" \
            "-gin_idle_cycles_g=0 -gout_idle_cycles_g=0 -gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir" \
            "-gin_idle_cycles_g=0 -gout_idle_cycles_g=0 -gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir" \
            "-gin_idle_cycles_g=20 -gout_idle_cycles_g=2 -gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir" \
            "-gin_idle_cycles_g=2 -gout_idle_cycles_g=0 -gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir" \
            "-gin_idle_cycles_g=2 -gout_idle_cycles_g=20 -gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_dds_18b_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_dds_18b_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_dds_18b_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gidle_cycles_g=0 -gtdm_channels_g=1" \
            "-gfile_folder_g=$dataDir -gidle_cycles_g=5 -gtdm_channels_g=1" \
            "-gfile_folder_g=$dataDir -gidle_cycles_g=0 -gtdm_channels_g=2" \
            "-gfile_folder_g=$dataDir -gidle_cycles_g=5 -gtdm_channels_g=2"
tb_run_add_time_limit "1000 us"
add_tb_run

create_tb_run "psi_fix_lowpass_iir_order1_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_lowpass_iir_order1_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_lowpass_iir_order1_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gpipeline_g=true" \
            "-gfile_folder_g=$dataDir -gpipeline_g=false"
add_tb_run

create_tb_run "psi_fix_complex_mult_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_mult_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_mult_tb/Data"]
set dataDir [file normalize "../testbench/psi_fix_complex_mult_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gpipeline_g=true -gclk_per_spl_g=1 -gfile_folder_g=$dataDir" \
            "-gfile_folder_g=$dataDir -gpipeline_g=false -gclk_per_spl_g=1 -gfile_folder_g=$dataDir" \
            "-gfile_folder_g=$dataDir -gpipeline_g=false -gclk_per_spl_g=5 -gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_mov_avg_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_mov_avg_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_mov_avg_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -ggain_corr_g=NONE -gduty_cycle_g=1 -gout_regs_g=0" \
            "-gfile_folder_g=$dataDir -ggain_corr_g=EXACT -gduty_cycle_g=5 -gout_regs_g=3" \
            "-gfile_folder_g=$dataDir -ggain_corr_g=ROUGH -gduty_cycle_g=3 -gout_regs_g=1"
add_tb_run

create_tb_run "psi_fix_demod_real2cplx_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_demod_real2cplx_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_demod_real2cplx_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gduty_cycle_g=1" \
            "-gfile_folder_g=$dataDir -gduty_cycle_g=5" \
            "-gfile_folder_g=$dataDir -gduty_cycle_g=1" "-gratio_num_g=5" "-gratio_den_g=3" \
            "-gfile_folder_g=$dataDir -gduty_cycle_g=1" "-gratio_num_g=100" "-gratio_den_g=3" \

add_tb_run

create_tb_run "psi_fix_cordic_vect_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cordic_vect_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_vect_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -ggain_comp_g=true -ground_g=psi_fix_round -gsat_g=psi_fix_sat -gmode_g=PIPELINED -gpl_stg_per_iter_g=1" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=true -ground_g=psi_fix_round -gsat_g=psi_fix_sat -gmode_g=PIPELINED -gpl_stg_per_iter_g=2" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=false -ground_g=psi_fix_trunc -gsat_g=psi_fix_wrap -gmode_g=PIPELINED -gpl_stg_per_iter_g=1" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=true -ground_g=psi_fix_round -gsat_g=psi_fix_sat -gmode_g=SERIAL" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=false -ground_g=psi_fix_trunc -gsat_g=psi_fix_wrap -gmode_g=SERIAL"
add_tb_run

create_tb_run "psi_fix_cordic_rot_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cordic_rot_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_rot_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -ggain_comp_g=true -ground_g=psi_fix_round -gsat_g=psi_fix_sat -gmode_g=PIPELINED" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=false -ground_g=psi_fix_trunc -gsat_g=psi_fix_wrap -gmode_g=PIPELINED" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=true -ground_g=psi_fix_round -gsat_g=psi_fix_sat -gmode_g=SERIAL" \
            "-gfile_folder_g=$dataDir -ggain_comp_g=false -ground_g=psi_fix_trunc -gsat_g=psi_fix_wrap -gmode_g=SERIAL"
add_tb_run

create_tb_run "psi_fix_pol2cart_approx_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_pol2cart_approx_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_pol2cart_approx_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_cic_dec_fix_nch_par_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_nch_par_tdm_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_dec_fix_nch_tdm_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_fix_nch_tdm_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_fix_nch_tdm_tdm_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run

create_tb_run "psi_fix_mod_cplx2real_tb"
tb_run_add_pre_script "python3" "psi_fix_mod_cplx2real_app.py" "../testbench/psi_fix_mod_cplx2real_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_mod_cplx2real_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir -gclk_per_spl_g=1 -gpl_stages_g=5" \
            "-gfile_folder_g=$dataDir -gclk_per_spl_g=1 -gpl_stages_g=6" \
            "-gfile_folder_g=$dataDir -gclk_per_spl_g=10 -gpl_stages_g=5" \
            "-gfile_folder_g=$dataDir -gclk_per_spl_g=10 -gpl_stages_g=6" \
            "-gfile_folder_g=$dataDir -gclk_per_spl_g=1 -gpl_stages_g=6 -gratio_num_g=5 -gratio_den_g=3" \

add_tb_run

create_tb_run "psi_fix_lut_gen_tb"
#Pre-Script is executed prior to compilation because it geenrates code to be compiled
set dataDir [file normalize "../testbench/psi_fix_lut_gen_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_complex_addsub_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_addsub_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_addsub_tb/Data"]
tb_run_add_arguments   "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_complex_abs_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_complex_abs_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_complex_abs_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_phase_unwrap_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_phase_unwrap_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_phase_unwrap_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir -gstimuli_set_g=S -gvld_duty_cycle_g=5" \
           "-gfile_folder_g=$dataDir -gstimuli_set_g=U -gvld_duty_cycle_g=5" \
           "-gfile_folder_g=$dataDir -gstimuli_set_g=S -gvld_duty_cycle_g=1"
add_tb_run

create_tb_run "psi_fix_white_noise_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_white_noise_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_white_noise_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir -gstimuli_set_g=S -gvld_duty_cycle_g=5" \
           "-gfile_folder_g=$dataDir -gstimuli_set_g=U -gvld_duty_cycle_g=5" \
           "-gfile_folder_g=$dataDir -gstimuli_set_g=S -gvld_duty_cycle_g=1"
add_tb_run

create_tb_run "psi_fix_noise_awgn_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_noise_awgn_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_noise_awgn_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=5" \
           "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=1"
add_tb_run


create_tb_run "psi_fix_fir_3tap_hbw_dec2_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_fir_3tap_hbw_dec2_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_3tap_hbw_dec2_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=5 -gchannels_g=1 -gin_file_g=inChannels1SeparateTrue.txt -gout_file_g=outChannels1SeparateTrue.txt"  \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=1 -gchannels_g=2 -gseparate_g=false -gin_file_g=inChannels2SeparateFalse.txt -gout_file_g=outChannels2SeparateFalse.txt" \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=5 -gchannels_g=4 -gseparate_g=false -gin_file_g=inChannels4SeparateFalse.txt -gout_file_g=outChannels4SeparateFalse.txt" \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=1 -gchannels_g=1 -gin_file_g=inChannels1SeparateTrue.txt -gout_file_g=outChannels1SeparateTrue.txt" \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=1 -gchannels_g=2 -gin_file_g=inChannels2SeparateTrue.txt -gout_file_g=outChannels2SeparateTrue.txt" \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=5 -gchannels_g=2 -gin_file_g=inChannels2SeparateTrue.txt -gout_file_g=outChannels2SeparateTrue.txt" \
    "-gfile_folder_g=$dataDir -gvld_duty_cycle_g=5 -gchannels_g=4 -gin_file_g=inChannels4SeparateTrue.txt -gout_file_g=outChannels4SeparateTrue.txt"
add_tb_run

create_tb_run "psi_fix_resize_pipe_tb"
add_tb_run

create_tb_run "psi_fix_param_ram_tb"
add_tb_run

create_tb_run "psi_fix_cic_dec_cfg_1ch_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_cfg_1ch_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_cfg_1ch_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=6 -gratio_g=5001 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o6_r5001_dd2_gcTrue.txt -gout_file_g=output_o6_r5001_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_dec_cfg_nch_par_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_cfg_nch_par_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_cfg_nch_par_tdm_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run

create_tb_run "psi_fix_cic_dec_cfg_nch_tdm_tdm_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_cic_dec_cfg_nch_tdm_tdm_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cic_dec_cfg_nch_tdm_tdm_tb/Data"]
tb_run_add_arguments   "-gorder_g=3 -gratio_g=10 -gdiff_delay_g=1 -gauto_gain_corr_g=True -gin_file_g=input_o3_r10_dd1_gcTrue.txt -gout_file_g=output_o3_r10_dd1_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=5" \
            "-gorder_g=4 -gratio_g=9 -gdiff_delay_g=2 -gauto_gain_corr_g=True -gin_file_g=input_o4_r9_dd2_gcTrue.txt -gout_file_g=output_o4_r9_dd2_gcTrue.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0" \
            "-gorder_g=4 -gratio_g=6 -gdiff_delay_g=2 -gauto_gain_corr_g=False -gin_file_g=input_o4_r6_dd2_gcFalse.txt -gout_file_g=output_o4_r6_dd2_gcFalse.txt -gdata_dir_g=$dataDir -gidle_cycles_g=0"

add_tb_run


create_tb_run "psi_fix_sqrt_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_sqrt_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_sqrt_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_inv_tb"
tb_run_add_pre_script "python3" "preScript.py" "../testbench/psi_fix_inv_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_inv_tb/Data"]
tb_run_add_arguments "-gfile_folder_g=$dataDir"
add_tb_run

create_tb_run "psi_fix_comparator_tb"
add_tb_run

create_tb_run "psi_fix_nch_analog_trigger_tdm_tb"
tb_run_add_arguments  "-gch_nb_g=4" \
                      "-gch_nb_g=8" \
                      "-gch_nb_g=16"
add_tb_run

create_tb_run "psi_fix_matrix_mult_tb"
tb_run_add_pre_script "python3" "io_gen.py" "../testbench/psi_fix_matrix_mult_tb/scripts"
set dataDir [file normalize "../testbench/psi_fix_matrix_mult_tb/data/"]
tb_run_add_arguments    "-gFileFolder_g=$dataDir -gFileIn_g=\"/input_2x2_2x2.txt\" -gFileOut_g=\"/output_2x2_2x2.txt\" -gDutyCycle_g=1 -gmatA_N_g=2 -gmatA_M_g=2 -gmatB_N_g=2 -gmatB_M_g=2" \
                        "-gFileFolder_g=$dataDir -gFileIn_g=\"/input_2x3_3x1.txt\" -gFileOut_g=\"/output_2x3_3x1.txt\" -gDutyCycle_g=1 -gmatA_N_g=2 -gmatA_M_g=3 -gmatB_N_g=3 -gmatB_M_g=1"
add_tb_run

create_tb_run "psi_fix_ss_solver_tb"
tb_run_add_pre_script "python3" "io_gen.py" "../testbench/psi_fix_ss_solver_tb/scripts"
set dataDir [file normalize "../testbench/psi_fix_ss_solver_tb/data"]
tb_run_add_arguments    "-gFileFolder_g=$dataDir -gDutyCycle_g=6"
add_tb_run





