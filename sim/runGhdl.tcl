#Load dependencies
source ../../../TCL/PsiSim/PsiSim.tcl
namespace import psi::sim::*

#Initialize Simulation
init -ghdl

#Configure
source ./config.tcl

#Run Simulation
puts "------------------------------"
puts "-- Compile"
puts "------------------------------"
compile_files -all -clean
puts "------------------------------"
puts "-- Run"
puts "------------------------------"
run_tb -all
puts "------------------------------"
puts "-- Check"
puts "------------------------------"

run_check_errors "###ERROR###"