import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_cordic_vect import psi_fix_cordic_vect
from psi_fix_cordic_abs_pl import psi_fix_cordic_abs_pl
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
inFmt = PsiFixFmt(1, 0, 15)
outFmt = PsiFixFmt(0, 2, 16)
intFmt = PsiFixFmt(1, 2, 22)
angleFmt = PsiFixFmt(0,0,15)
angleIntFmt = PsiFixFmt(1,0,18)
iterations = 13

np.random.seed(0)
sigRandI = PsiFixFromReal(np.random.rand(SAMPLES_RAND)*2-1, inFmt, errSat=False)
sigRandQ = PsiFixFromReal(np.random.rand(SAMPLES_RAND)*2-1, inFmt, errSat=False)

anglesLogic = np.linspace(0, 2*np.pi, SAMPLES_LOGIC)
amplitudeLogic = np.linspace(0.01, 0.99, SAMPLES_LOGIC)
sigLogicI = PsiFixFromReal(np.cos(anglesLogic)*amplitudeLogic, inFmt, errSat=False)
sigLogicQ = PsiFixFromReal(np.sin(anglesLogic)*amplitudeLogic, inFmt, errSat=False)

sigI = np.concatenate((sigLogicI, sigRandI))
sigQ = np.concatenate((sigLogicQ, sigRandQ))
sigCplx = sigI + 1j*sigQ

cordic = psi_fix_cordic_vect(inFmt, outFmt, intFmt, angleFmt, angleIntFmt, iterations, True, PsiFixRnd.Round, PsiFixSat.Sat)
resAmp, resAng = cordic.Process(sigI, sigQ)

cordicNoGc = psi_fix_cordic_vect(inFmt, outFmt, intFmt, angleFmt, angleIntFmt, iterations, False, PsiFixRnd.Trunc, PsiFixSat.Wrap)
resNoGcAmp, resNoGcAng = cordicNoGc.Process(sigI, sigQ)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    plt.figure()
    plt.title("input")
    plt.plot(sigI, sigQ, '.')
    plt.figure()
    plt.title("Amplitude")
    plt.plot(resAmp)
    plt.figure()
    plt.title("Angle")
    plt.plot(resAng, 'b')
    plt.figure()
    plt.title("Amplitude error [LSB]")
    plt.plot((resAmp-np.abs(sigCplx))*2**outFmt.F)
    plt.figure()
    plt.title("Angle error [LSB]")
    plt.plot(np.unwrap(resAng*2*np.pi - np.angle(sigCplx))/(2*np.pi)*2**angleFmt.F)
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((PsiFixGetBitsAsInt(sigI, inFmt),
                            PsiFixGetBitsAsInt(sigQ, inFmt))),
           fmt="%i", header="input-I input-Q")
np.savetxt(STIM_DIR + "/outputWithGc.txt",
           np.column_stack((PsiFixGetBitsAsInt(resAmp, outFmt),
                           PsiFixGetBitsAsInt(resAng, angleFmt))),
           fmt="%i", header="result-Amp result-Ang")
np.savetxt(STIM_DIR + "/outputWithNoGc.txt",
           np.column_stack((PsiFixGetBitsAsInt(resNoGcAmp, outFmt),
                           PsiFixGetBitsAsInt(resNoGcAng, angleFmt))),
           fmt="%i", header="result-Amp result-Ang")

