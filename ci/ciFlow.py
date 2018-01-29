import os
import sys
import unittest

##################################
# Modelsim
##################################
os.chdir("../sim")
os.system("vsim -c -do ci.do")

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
os.chdir("../unittest")
sys.path.append(".")
from psi_fix_pkg_test import *
res = unittest.main(exit=False)
if len(res.result.errors) > 0 or len(res.result.failures) > 0:
	exit(-1)


