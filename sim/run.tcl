#Load dependencies
source ../../../../Lib/Tcl_Lib/PsiSim/PsiSim.tcl

#Initialize Simulation
psi::sim::init

#Configure
source ./config.tcl

#Run Simulation
puts "------------------------------"
puts "-- Compile"
puts "------------------------------"
psi::sim::compile -all -clean
puts "------------------------------"
puts "-- Run"
puts "------------------------------"
psi::sim::run_tb -all
puts "------------------------------"
puts "-- Check"
puts "------------------------------"

psi::sim::run_check_errors "###ERROR###"