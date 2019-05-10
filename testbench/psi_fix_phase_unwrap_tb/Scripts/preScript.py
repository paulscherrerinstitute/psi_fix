########################################################################################################################
# Set path
########################################################################################################################
import sys
sys.path.append("../../../model")

########################################################################################################################
# Import Statements
########################################################################################################################
from psi_fix_phase_unwrap import psi_fix_phase_unwrap
from psi_fix_pkg import *
import numpy as np
from matplotlib import pyplot as plt
import os

########################################################################################################################
# Constants
########################################################################################################################
PLOT_ON = False

filepath = os.path.realpath(__file__)
dirpath = os.path.dirname(filepath)
STIM_DIR = os.path.join(dirpath, "../Data")

IN_FMT_S = PsiFixFmt(1, 0, 15)
IN_FMT_U = PsiFixFmt(0, 1, 15)
OUT_FMT = PsiFixFmt(1, 3, 15)

########################################################################################################################
# Simulation
########################################################################################################################
# Stimuli Data
rampForward = np.cumsum(np.ones(20)*0.2)
rampBackward = np.cumsum(np.concatenate([rampForward[-1:-1], np.ones(20)*-0.2]))
bigSteps = np.array([0.7, 0.6, -0.7, -0.6])
overflowPos = np.cumsum(np.ones(100)*0.2)
overflowNeg = np.cumsum(np.ones(100)*-0.3)

stim = np.concatenate((rampForward, rampBackward, bigSteps, overflowPos, overflowNeg))
stimFixS = PsiFixResize(stim, PsiFixFmt(1,20,20), IN_FMT_S)
stimFixU = PsiFixResize(stim, PsiFixFmt(1,20,20), IN_FMT_U)

#Simulation
modelS = psi_fix_phase_unwrap(IN_FMT_S, OUT_FMT, PsiFixRnd.Trunc)
outSSig, outSWrap = modelS.Process(stimFixS)
modelU = psi_fix_phase_unwrap(IN_FMT_U, OUT_FMT, PsiFixRnd.Trunc)
outUSig, outUWrap = modelU.Process(stimFixU)

########################################################################################################################
# Plots
########################################################################################################################
if PLOT_ON:
    fig, ax = plt.subplots(2,1, sharex="all")
    fig.suptitle("Input Signed")
    ax[0].plot(stimFixS)
    ax[0].set_ylabel("input")
    ax[1].plot(outSSig, "r")
    ax[1].plot(outSWrap, "b")
    ax[1].set_ylabel("output")

    fig, ax = plt.subplots(2,1, sharex="all")
    fig.suptitle("Input Unsigned")
    ax[0].plot(stimFixU)
    ax[0].set_ylabel("input")
    ax[1].plot(outUSig, "r")
    ax[1].plot(outUWrap, "b")
    ax[1].set_ylabel("output")

    plt.show()

########################################################################################################################
# Write Files
########################################################################################################################
try:
    os.makedirs(STIM_DIR)
except FileExistsError:
    pass

np.savetxt(STIM_DIR + "/inputS.txt",
           (PsiFixGetBitsAsInt(stimFixS, IN_FMT_S)),
           fmt="%i", header="Input")
np.savetxt(STIM_DIR + "/inputU.txt",
           (PsiFixGetBitsAsInt(stimFixU, IN_FMT_U)),
           fmt="%i", header="Input")
np.savetxt(STIM_DIR + "/OutputS.txt",
           np.column_stack((PsiFixGetBitsAsInt(outSSig, OUT_FMT),
                            np.array(outSWrap, dtype=int))),
           fmt="%i", header="Sig, Wrp")
np.savetxt(STIM_DIR + "/OutputU.txt",
           np.column_stack((PsiFixGetBitsAsInt(outUSig, OUT_FMT),
                            np.array(outUWrap, dtype=int))),
           fmt="%i", header="Sig, Wrp")
