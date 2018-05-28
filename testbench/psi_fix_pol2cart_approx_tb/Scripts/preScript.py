import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_pol2cart_approx import psi_fix_pol2cart_approx
from matplotlib import pyplot as plt
import scipy.signal as sps
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES_RAND = 1000
SAMPLES_LOGIC = 361

PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Simulation
#############################################################
inAbsFmt = PsiFixFmt(0, 0, 16)
inAngleFmt = PsiFixFmt(0,0,15)
outFmt = PsiFixFmt(1, 0, 16)

np.random.seed(0)
sigRandAbs = PsiFixFromReal(np.random.rand(SAMPLES_RAND), inAbsFmt, errSat=False)
sigRandAng = PsiFixFromReal(np.random.rand(SAMPLES_RAND), inAngleFmt, errSat=False)

anglesLogic = np.linspace(0, 1, SAMPLES_LOGIC)
amplitudeLogic = np.linspace(0.01, 0.99, SAMPLES_LOGIC)
sigLogicAbs = PsiFixFromReal(amplitudeLogic, inAbsFmt, errSat=False)
sigLogicAng = PsiFixFromReal(anglesLogic, inAngleFmt, errSat=False)

sigAbs = np.concatenate((sigLogicAbs, sigRandAbs))
sigAng = np.concatenate((sigLogicAng, sigRandAng))

conv = psi_fix_pol2cart_approx(inAbsFmt, inAngleFmt, outFmt, PsiFixRnd.Round, PsiFixSat.Sat)
resI, resQ = conv.Process(sigAbs, sigAng)


#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    plt.figure()
    plt.title("Input")
    plt.plot(sigAbs*np.cos(sigAng*2*np.pi), sigAbs*np.sin(sigAng*2*np.pi), ".")
    plt.figure()
    plt.title("Result")
    plt.plot(resI, 'r'),
    plt.plot(resQ, 'b')
    plt.figure()
    plt.title("Error [LSB]")
    plt.plot((resI-np.cos(sigAng*2*np.pi)*sigAbs)*2**outFmt.F, (resQ-np.sin(sigAng*2*np.pi)*sigAbs)*2**outFmt.F, ".")
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((PsiFixGetBitsAsInt(sigAbs, inAbsFmt),
                            PsiFixGetBitsAsInt(sigAng, inAngleFmt))),
           fmt="%i", header="input-Abs input-Ang")
np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack((PsiFixGetBitsAsInt(resI, outFmt),
                           PsiFixGetBitsAsInt(resQ, outFmt))),
           fmt="%i", header="result-I result-Q")


