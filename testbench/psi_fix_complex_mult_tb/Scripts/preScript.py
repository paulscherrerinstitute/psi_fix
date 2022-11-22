########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_complex_mult import psi_fix_complex_mult
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
inAFmt = psi_fix_fmt_t(1, 0, 15)
inBFmt = psi_fix_fmt_t(1, 0, 24)
intFmt = psi_fix_fmt_t(1, 1, 24)
outFmt = psi_fix_fmt_t(1, 0, 20)

sigRot = np.exp(2j*np.pi*np.linspace(0, 1, 360))*0.99
sigRamp = np.linspace(0.5, 0.9, 360)
sigRandA = (np.random.rand(RAND_SAMPLES)+1j*np.random.rand(RAND_SAMPLES))*2-1-1j
sigRandB = (np.random.rand(RAND_SAMPLES)+1j*np.random.rand(RAND_SAMPLES))*2-1-1j

sigA = np.concatenate((sigRot, sigRamp, sigRandA))
sigB = np.concatenate((sigRamp, sigRot, sigRandB))

sigAI = psi_fix_from_real(sigA.real, inAFmt, err_sat=False)
sigAQ = psi_fix_from_real(sigA.imag, inAFmt, err_sat=False)
sigBI = psi_fix_from_real(sigB.real, inAFmt, err_sat=False)
sigBQ = psi_fix_from_real(sigB.imag, inAFmt, err_sat=False)

mult = psi_fix_complex_mult(inAFmt, inBFmt, intFmt, outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
resI, resQ = mult.Process(sigAI, sigAQ, sigBI, sigBQ)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    plt.figure()
    plt.plot(resI, resQ)
    plt.figure()
    plt.plot(resI, 'b')
    plt.plot(resQ, 'r')
    plt.show()


#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((psi_fix_get_bits_as_int(sigAI, inAFmt),
                            psi_fix_get_bits_as_int(sigAQ, inAFmt),
                            psi_fix_get_bits_as_int(sigBI, inBFmt),
                            psi_fix_get_bits_as_int(sigBQ, inBFmt))),
           fmt="%i", header="ai aq bi bq")
np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack((psi_fix_get_bits_as_int(resI, outFmt),
                            psi_fix_get_bits_as_int(resQ, outFmt))),
           fmt="%i", header="result-I result-Q")


