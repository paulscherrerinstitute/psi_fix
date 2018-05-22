import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_demod_real2cplx import psi_fix_demod_real2cplx
from matplotlib import pyplot as plt
import scipy.signal as sps
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 10000

PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Simulation
#############################################################
dataFmt = PsiFixFmt(1, 0, 15)
fSample = 100e6
Ratio = 5
fSig = fSample/Ratio

FSTART = fSig*0.99
FSTOP = fSig*1.01


t = np.arange(0, (SAMPLES-1)/fSample, 1/fSample)
sig = sps.chirp(t, FSTART, t[-1], FSTOP, method="linear")*0.1
sigFix = PsiFixFromReal(sig, dataFmt)

demod = psi_fix_demod_real2cplx(dataFmt, Ratio)
resI, resQ = demod.Process(sigFix, 0)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    plt.plot(resI, resQ)
    plt.show()


#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt", PsiFixGetBitsAsInt(sigFix, dataFmt), fmt="%i", header="input")
np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack((PsiFixGetBitsAsInt(resI, dataFmt),
                           PsiFixGetBitsAsInt(resQ, dataFmt))),
           fmt="%i", header="result-I result-Q")


