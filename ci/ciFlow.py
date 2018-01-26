import os
import sys

##################################
# Modelsim
##################################
os.chdir("../sim")
os.system("vsim -c -do ci.do")

with open("Transcript.transcript") as f:
	content = f.read()
	
if "###ERROR###" in content:
	exit(-1)

##################################
# Python Unit Test
##################################
print("Currently Omitted because Python 3.x is not installed on Jenkins Server")

