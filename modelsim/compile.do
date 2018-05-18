#========================================================================================
# Do file to help compiling file from psi common
# watch out path! may be different
# do compile.do ../Hdl
#========================================================================================
vlib work
echo "source file path enetered $1"

vcom -2008 -work work $1/psi_fix_pkg.vhd 
vcom -2008 -work work $1/psi_fix_lin_approx_calc.vhd 
vcom -2008 -work work $1/psi_fix_lin_approx_sin18b.vhd 
vcom -2008 -work work $1/psi_fix_lin_approx_sin18b_dual.vhd 

vcom -quiet -2008 -work work $1/psi_fix_bin_div.vhd 
vcom -quiet -2008 -work work $1/psi_fix_cic_dec_fix_1ch.vhd 
vcom -quiet -2008 -work work $1/psi_fix_cic_int_fix_1ch.vhd
vcom -quiet -2008 -work work $1/psi_fix_cordic_abs_pl.vhd
vcom -quiet -2008 -work work $1/psi_fix_dds_18b.vhd 

vdir -lib work
echo "______________________________________"
echo "library psi fix available to be mapped"
