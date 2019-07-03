########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import os
import sys
import unittest

THIS_DIR = os.path.dirname(os.path.abspath(__file__))

##################################
# Modelsim
##################################
os.chdir(THIS_DIR + "/../sim")
os.system("vsim -batch -do ci.do -logfile Transcript.transcript")

with open("Transcript.transcript") as f:
	content = f.read()
	
#Expected Errors
if "###ERROR###" in content:
	exit(-1)
#Unexpected Errors
if "SIMULATIONS COMPLETED SUCCESSFULLY" not in content:
	exit(-2)

##################################
# Python Unit Test
##################################
os.chdir(THIS_DIR + "/../unittest")
sys.path.append(".")
from psi_fix_pkg_test import *
res = unittest.main(exit=False)
if len(res.result.errors) > 0 or len(res.result.failures) > 0:
	exit(-1)


