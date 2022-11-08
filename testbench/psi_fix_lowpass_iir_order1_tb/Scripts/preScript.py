########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_lowpass_iir_order1 import psi_fix_lowpass_iir_order1
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
outFmt = psi_fix_fmt_t(1, 0, 14)
intFmt = psi_fix_fmt_t(1, 0, 24)
coefFmt = psi_fix_fmt_t(1, 0, 17)
fSample = 100e6
fCutoff = 1e6

FSTART = fCutoff/10
FSTOP = fCutoff*10


t = np.arange(0, (SAMPLES-1)/fSample, 1/fSample)
sig = sps.chirp(t, FSTART, t[-1], FSTOP, method="log")*0.999
sigFix = psi_fix_from_real(sig, inFmt)

iir = psi_fix_lowpass_iir_order1(fSample, fCutoff, inFmt, outFmt, intFmt, coefFmt)

res = iir.Filter(sigFix)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    print(FSTART, FSTOP)
    freqs = np.logspace(np.log10(FSTART), np.log10(FSTOP), sigFix.size, base=10)
    plt.semilogx(freqs, 20*np.log10(abs(sigFix)), 'b')
    plt.semilogx(freqs, 20*np.log10(abs(res)+1e-12), 'r')
    plt.ylim((-40, 0))
    plt.show()


#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt", psi_fix_get_bits_as_int(sigFix, inFmt), fmt="%i", header="input")
np.savetxt(STIM_DIR + "/output.txt", psi_fix_get_bits_as_int(res, outFmt), fmt="%i", header="output")


