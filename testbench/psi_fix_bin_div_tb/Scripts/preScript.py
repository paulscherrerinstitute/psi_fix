import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_bin_div import psi_fix_bin_div
from matplotlib import pyplot
import os

STIM_DIR = os.path.abspath(__file__) + "/../../Data"
SAMPLES = 1000

PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Functions
#############################################################
def WriteFile(signal, filePath, fracBits):
    # Scale to fixed point
    signal = (signal * pow(2, fracBits)).round()

    # Write to File
    with open(filePath, "w+") as f:
        f.writelines(["{}\n".format(int(val)) for val in signal])

#############################################################
# Simulation
#############################################################
numFmt = PsiFixFmt(1, 2, 5)
denomFmt = PsiFixFmt(1, 2, 8)
outFmt = PsiFixFmt(1, 4, 10)

np.random.seed(0)
num = (np.random.random(SAMPLES)-0.5)*2*3.9
denom = (np.random.random(SAMPLES)-0.5)*2*3.9
#num[0] = 3
#denom[0] = 0.5

numF = PsiFixFromReal(num, numFmt)
denomF = PsiFixFromReal(denom, denomFmt)

res = psi_fix_bin_div(numF, numFmt, denomF, denomFmt, outFmt, PsiFixRnd.Trunc, PsiFixSat.Sat)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    resExp = numF/denomF
    resExp = PsiFixFromReal(resExp, outFmt, errSat=False)
    err = res - resExp
    pyplot.plot(err*2**outFmt.F)
    pyplot.show()

#############################################################
# Write Files for Co sim
#############################################################
with open(STIM_DIR + "/input.txt", "w+") as f:
    f.writelines(["{} {}\n".format(int(i), int(q)) for i, q in zip(PsiFixToInt(numF, numFmt), PsiFixToInt(denomF, denomFmt))])
with open(STIM_DIR + "/output.txt", "w+") as f:
    f.writelines(["{}\n".format(int(r)) for r in PsiFixToInt(res, outFmt)])

