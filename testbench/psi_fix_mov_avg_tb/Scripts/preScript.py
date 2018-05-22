import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_mov_avg import psi_fix_mov_avg
from matplotlib import pyplot as plt
import scipy.signal as sps
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
RAND_SAMPLES = 10000

PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Simulation
#############################################################
sigDbg = np.concatenate((np.ones(10)*0.99, np.ones(10)*-0.99, np.ones(10)*0.99, np.zeros(10), np.ones(10)*0.2, np.zeros(100)))
inFmt = PsiFixFmt(1, 0, 10)
outFmt = PsiFixFmt(1, 1, 12)
Taps = 7
GcOptions = (psi_fix_mov_avg.GAINCORR_NONE, psi_fix_mov_avg.GAINCORR_ROUGH, psi_fix_mov_avg.GAINCORR_EXACT)

np.random.seed(0)
sigRand = np.random.randn(RAND_SAMPLES)*2-1

sigAll = np.concatenate((sigDbg, sigRand, np.zeros(100)))
sigFix = PsiFixFromReal(sigAll, inFmt, errSat=False)

result = {}
for gc in GcOptions:
    ms = psi_fix_mov_avg(inFmt, outFmt, Taps, gc)
    res = ms.Process(sigFix)
    result[gc] = res

    if PLOT_ON is True:
        plt.figure()
        plt.title(gc)
        plt.plot(res)
if PLOT_ON:
    plt.show()


#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt", PsiFixGetBitsAsInt(sigFix, inFmt), fmt="%i", header="input")
for gc in GcOptions:
    np.savetxt(STIM_DIR + "/output_{}.txt".format(gc.lower()), PsiFixGetBitsAsInt(result[gc], outFmt), fmt="%i", header="result-I result-Q")


