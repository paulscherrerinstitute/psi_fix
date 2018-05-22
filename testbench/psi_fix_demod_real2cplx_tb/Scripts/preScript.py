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
GC_OPTIONS = (psi_fix_demod_real2cplx.GAINCORR_NONE, psi_fix_demod_real2cplx.GAINCORR_EXACT)

FSTART = fSig*0.99
FSTOP = fSig*1.01


t = np.arange(0, (SAMPLES-1)/fSample, 1/fSample)
sig = sps.chirp(t, FSTART, t[-1], FSTOP, method="linear")*0.1
sigFix = PsiFixFromReal(sig, dataFmt)
phase = np.ones_like(sigFix)*2
phase [100:1000] = 4

resutls = {}
for gc in GC_OPTIONS:
    demod = psi_fix_demod_real2cplx(dataFmt, Ratio, gaincorr=gc)
    resutls[gc] = demod.Process(sigFix, phase)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    for gc in GC_OPTIONS:
        plt.figure()
        plt.title(gc)
        plt.plot(resutls[gc][0], resutls[gc][1])
        plt.figure()
        plt.title(gc)
        plt.plot(resutls[gc][0], 'b')
        plt.plot(resutls[gc][1], 'r')
        plt.show()


#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((PsiFixGetBitsAsInt(sigFix, dataFmt),
                            phase)),
           fmt="%i", header="input phase")
for gc in GC_OPTIONS:
    np.savetxt(STIM_DIR + "/output_{}.txt".format(gc),
               np.column_stack((PsiFixGetBitsAsInt(resutls[gc][0], dataFmt),
                               PsiFixGetBitsAsInt(resutls[gc][1], dataFmt))),
               fmt="%i", header="result-I result-Q")


