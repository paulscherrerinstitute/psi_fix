########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
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
inAbsFmt = psi_fix_fmt_t(0, 0, 16)
inAngleFmt = psi_fix_fmt_t(0,0,15)
outFmt = psi_fix_fmt_t(1, 0, 16)

np.random.seed(0)
sigRandAbs = psi_fix_from_real(np.random.rand(SAMPLES_RAND), inAbsFmt, err_sat=False)
sigRandAng = psi_fix_from_real(np.random.rand(SAMPLES_RAND), inAngleFmt, err_sat=False)

anglesLogic = np.linspace(0, 1, SAMPLES_LOGIC)
amplitudeLogic = np.linspace(0.01, 0.99, SAMPLES_LOGIC)
sigLogicAbs = psi_fix_from_real(amplitudeLogic, inAbsFmt, err_sat=False)
sigLogicAng = psi_fix_from_real(anglesLogic, inAngleFmt, err_sat=False)

sigAbs = np.concatenate((sigLogicAbs, sigRandAbs))
sigAng = np.concatenate((sigLogicAng, sigRandAng))

conv = psi_fix_pol2cart_approx(inAbsFmt, inAngleFmt, outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
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
    plt.plot((resI-np.cos(sigAng*2*np.pi)*sigAbs)*2**outFmt.f, (resQ-np.sin(sigAng*2*np.pi)*sigAbs)*2**outFmt.f, ".")
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((psi_fix_get_bits_as_int(sigAbs, inAbsFmt),
                            psi_fix_get_bits_as_int(sigAng, inAngleFmt))),
           fmt="%i", header="input-Abs input-Ang")
np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack((psi_fix_get_bits_as_int(resI, outFmt),
                           psi_fix_get_bits_as_int(resQ, outFmt))),
           fmt="%i", header="result-I result-Q")


