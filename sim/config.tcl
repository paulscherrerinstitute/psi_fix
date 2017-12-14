#Constants
set LibPath "../.."

#Set library
psi::sim::add_library psi_fix

#suppress messages
psi::sim::compile_suppress 135,1236
psi::sim::run_suppress 8684,3479,3813,8009,3812

# Library
psi::sim::add_sources $LibPath {
	psi_tb/hdl/psi_tb_txt_util.vhd \
	psi_common/hdl/psi_common_math_pkg.vhd \
	psi_common/hdl/psi_common_tdp_ram_rbw.vhd \
	psi_common/hdl/psi_common_array_pkg.vhd \
} -tag lib

# project sources
psi::sim::add_sources "../hdl" {
	psi_fix_pkg.vhd \
	psi_fix_cordic_abs_pl.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf.vhd \
	psi_fix_lin_approx_calc.vhd \
	psi_fix_lin_approx_sin18b.vhd \
	psi_fix_lin_approx_sin18b_dual.vhd \
} -tag src

# testbenches
psi::sim::add_sources "../testbench" {
	psi_fix_pkg_tb/psi_fix_pkg_tb.vhd \
	psi_fix_cordic_abs_pl_tb/psi_fix_cordic_abs_pl_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_tb.vhd \
	psi_fix_lin_approx_tb/sin18b/psi_fix_lin_approx_sin18b_dual_tb.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case0_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb_case1_pkg.vhd \
	psi_fix_fir_dec_ser_nch_chpar_conf_tb/psi_fix_fir_dec_ser_nch_chpar_conf_tb.vhd \
} -tag tb
	
#TB Runs
psi::sim::create_tb_run "psi_fix_pkg_tb"
psi::sim::add_tb_run

psi::sim::create_tb_run "psi_fix_cordic_abs_pl_tb"
psi::sim::tb_run_add_pre_script "python" "preScript.py" "../testbench/psi_fix_cordic_abs_pl_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_cordic_abs_pl_tb/Data"]
psi::sim::tb_run_add_arguments "-gDataDir_g=$dataDir"
psi::sim::add_tb_run

psi::sim::create_tb_run "psi_fix_lin_approx_sin18b_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
psi::sim::tb_run_add_arguments "-gStimuliDir_g=$dataDir"
psi::sim::add_tb_run

psi::sim::create_tb_run "psi_fix_lin_approx_sin18b_dual_tb"
set dataDir [file normalize "../testbench/psi_fix_lin_approx_tb/sin18b"]
psi::sim::tb_run_add_arguments "-gStimuliDir_g=$dataDir"
psi::sim::add_tb_run

psi::sim::create_tb_run "psi_fix_fir_dec_ser_nch_chpar_conf_tb"
psi::sim::tb_run_add_pre_script "python" "preScript.py" "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Scripts"
set dataDir [file normalize "../testbench/psi_fix_fir_dec_ser_nch_chpar_conf_tb/Data"]
psi::sim::tb_run_add_arguments 	"-gStimuliPath_g=$dataDir -gDutyCycle_g=32" \
								"-gStimuliPath_g=$dataDir -gDutyCycle_g=4"
psi::sim::add_tb_run




