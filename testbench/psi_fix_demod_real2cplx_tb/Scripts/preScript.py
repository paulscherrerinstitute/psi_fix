########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
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
inFmt = psi_fix_fmt_t(1, 0, 15)
outFmt = psi_fix_fmt_t(1, 0, 16)
coefBits = 25
fSample = 100e6
Ratio = 5
fSig = fSample/Ratio

FSTART = fSig*0.99
FSTOP = fSig*1.01


t = np.arange(0, (SAMPLES-1)/fSample, 1/fSample)
sig = sps.chirp(t, FSTART, t[-1], FSTOP, method="linear")*0.99
sigFix = psi_fix_from_real(sig, inFmt)
sig2 = np.random.rand(t.size)*1.99-1
sig2Fix = psi_fix_from_real(sig2, inFmt)
phase = np.ones_like(sigFix)*2
phase [100:1000] = 4



demod = psi_fix_demod_real2cplx(inFmt, outFmt, coefBits, Ratio)
resI, resQ = demod.Process(sigFix, phase)
res2I, res2Q = demod.Process(sig2Fix, phase)

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
           np.column_stack((psi_fix_get_bits_as_int(sigFix, inFmt),
                            psi_fix_get_bits_as_int(sig2Fix, inFmt),
                            phase)),
           fmt="%i", header="input phase")
np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack((psi_fix_get_bits_as_int(resI, outFmt),
                            psi_fix_get_bits_as_int(resQ, outFmt),
                            psi_fix_get_bits_as_int(res2I, outFmt),
                            psi_fix_get_bits_as_int(res2Q, outFmt))),
           fmt="%i", header="result-I result-Q")


