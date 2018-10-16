import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_complex_addsub import psi_fix_complex_addsub
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
inAFmt = PsiFixFmt(1, 0, 15)
inBFmt = PsiFixFmt(1, 0, 15)
outFmt = PsiFixFmt(1, 0, 15)

sigRot = np.exp(2j*np.pi*np.linspace(0, 1, 360))*0.99
sigRamp = np.linspace(0.5, 0.9, 360)
sigRandA = (np.random.rand(RAND_SAMPLES)+1j*np.random.rand(RAND_SAMPLES))*2-1-1j
sigRandB = (np.random.rand(RAND_SAMPLES)+1j*np.random.rand(RAND_SAMPLES))*2-1-1j

sigA = np.concatenate((sigRot, sigRamp, sigRandA))
sigB = np.concatenate((sigRamp, sigRot, sigRandB))

sigAI = PsiFixFromReal(sigA.real, inAFmt, errSat=False)
sigAQ = PsiFixFromReal(sigA.imag, inAFmt, errSat=False)
sigBI = PsiFixFromReal(sigB.real, inAFmt, errSat=False)
sigBQ = PsiFixFromReal(sigB.imag, inAFmt, errSat=False)

addsub = psi_fix_complex_addsub(inAFmt, inBFmt, outFmt, PsiFixRnd.Round, PsiFixSat.Sat)
addResI, addResQ = addsub.Process(sigAI, sigAQ, sigBI, sigBQ, 1)
subResI, subResQ = addsub.Process(sigAI, sigAQ, sigBI, sigBQ, 0)

#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((PsiFixGetBitsAsInt(sigAI, inAFmt),
                            PsiFixGetBitsAsInt(sigAQ, inAFmt),
                            PsiFixGetBitsAsInt(sigBI, inBFmt),
                            PsiFixGetBitsAsInt(sigBQ, inBFmt))),
           fmt="%i", header="ai aq bi bq")
np.savetxt(STIM_DIR + "/output_add.txt",
           np.column_stack((PsiFixGetBitsAsInt(addResI, outFmt),
                            PsiFixGetBitsAsInt(addResQ, outFmt))),
           fmt="%i", header="result-I result-Q")


np.savetxt(STIM_DIR + "/output_sub.txt",
           np.column_stack((PsiFixGetBitsAsInt(subResI, outFmt),
                            PsiFixGetBitsAsInt(subResQ, outFmt))),
           fmt="%i", header="result-I result-Q")

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    plt.figure()
    plt.plot(addResI, addResQ)
    plt.figure()
    plt.plot(addResI, 'b')
    plt.plot(addResQ, 'r')
    plt.show()