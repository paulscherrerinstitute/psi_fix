import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_cordic_abs_pl import psi_fix_cordic_abs_pl
import os

STIM_DIR = os.path.abspath(__file__) + "/../../Data"
SAMPLES = 1000

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
# Data Generation
#############################################################
inFmt = PsiFixFmt(1, 0, 15)
intFmt = PsiFixFmt(1, 1, 20)
outFmt = PsiFixFmt(0, 1, 17)
iterations = 13

np.random.seed(0)
inI = (np.random.rand(SAMPLES)-0.5)*1.99
inQ = (np.random.rand(SAMPLES)-0.5)*1.99
inI = PsiFixFromReal(inI, inFmt)
inQ = PsiFixFromReal(inQ, inFmt)

cordic = psi_fix_cordic_abs_pl(inFmt, outFmt, intFmt, iterations, PsiFixRnd.Trunc, PsiFixSat.Wrap)
out = cordic.Process(inI, inQ)

with open(STIM_DIR + "/input.txt", "w+") as f:
    f.writelines(["{} {}\n".format(int(i), int(q)) for i, q in zip(PsiFixToInt(inI, inFmt), PsiFixToInt(inQ, inFmt))])
with open(STIM_DIR + "/output.txt", "w+") as f:
    f.writelines(["{}\n".format(int(r)) for r in PsiFixToInt(out, outFmt)])

