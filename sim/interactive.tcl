#This script setps up Modelsim for interactively
# .. working from the TCL console.

#Import TCL Framework
source ../../../TCL/PsiSim/PsiSim.tcl
namespace import psi::sim::*

#Initialize Simulation
init

#Configure
source ./config.tcl
compile_files -all -clean