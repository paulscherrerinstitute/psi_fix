########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
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
inFmt = psi_fix_fmt_t(1, 0, 15)
outFmt = psi_fix_fmt_t(0, 2, 16)
intFmt = psi_fix_fmt_t(1, 2, 22)
angleFmt = psi_fix_fmt_t(0,0,15)
angleIntFmt = psi_fix_fmt_t(1,0,18)
iterations = 13

np.random.seed(0)
sigRandI = psi_fix_from_real(np.random.rand(SAMPLES_RAND)*2-1, inFmt, err_sat=False)
sigRandQ = psi_fix_from_real(np.random.rand(SAMPLES_RAND)*2-1, inFmt, err_sat=False)

anglesLogic = np.linspace(0, 2*np.pi, SAMPLES_LOGIC)
amplitudeLogic = np.linspace(0.01, 0.99, SAMPLES_LOGIC)
sigLogicI = psi_fix_from_real(np.cos(anglesLogic)*amplitudeLogic, inFmt, err_sat=False)
sigLogicQ = psi_fix_from_real(np.sin(anglesLogic)*amplitudeLogic, inFmt, err_sat=False)

sigI = np.concatenate((sigLogicI, sigRandI))
sigQ = np.concatenate((sigLogicQ, sigRandQ))
sigCplx = sigI + 1j*sigQ

cordic = psi_fix_cordic_vect(inFmt, outFmt, intFmt, angleFmt, angleIntFmt, iterations, True, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
resAmp, resAng = cordic.Process(sigI, sigQ)

cordicNoGc = psi_fix_cordic_vect(inFmt, outFmt, intFmt, angleFmt, angleIntFmt, iterations, False, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
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
    plt.plot((resAmp-np.abs(sigCplx))*2**outFmt.f)
    plt.figure()
    plt.title("Angle error [LSB]")
    plt.plot(np.unwrap(resAng*2*np.pi - np.angle(sigCplx))/(2*np.pi)*2**angleFmt.f)
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((psi_fix_get_bits_as_int(sigI, inFmt),
                            psi_fix_get_bits_as_int(sigQ, inFmt))),
           fmt="%i", header="input-I input-Q")
np.savetxt(STIM_DIR + "/outputWithGc.txt",
           np.column_stack((psi_fix_get_bits_as_int(resAmp, outFmt),
                           psi_fix_get_bits_as_int(resAng, angleFmt))),
           fmt="%i", header="result-Amp result-Ang")
np.savetxt(STIM_DIR + "/outputWithNoGc.txt",
           np.column_stack((psi_fix_get_bits_as_int(resNoGcAmp, outFmt),
                           psi_fix_get_bits_as_int(resNoGcAng, angleFmt))),
           fmt="%i", header="result-Amp result-Ang")

