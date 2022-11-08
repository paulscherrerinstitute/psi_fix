########################################################################################################################
# Set path
########################################################################################################################
import sys
sys.path.append("../../../model")

########################################################################################################################
# Import Statements
########################################################################################################################
from psi_fix_complex_abs import psi_fix_complex_abs
from psi_fix_pkg import *
import numpy as np
from scipy import signal as sps
from matplotlib import pyplot as plt
import os

########################################################################################################################
# Constants
########################################################################################################################
PLOT_ON = False
SIMPLE_SAMPLES = 360
RAND_SAMPLES = 1000

filepath = os.path.realpath(__file__)
dirpath = os.path.dirname(filepath)
STIM_DIR = os.path.join(dirpath, "../Data")

IN_FMT = psi_fix_fmt_t(1, 2, 14)
OUT_FMT = psi_fix_fmt_t(0, 1, 15)

########################################################################################################################
# Simulation
########################################################################################################################
# Stimuli Data
stimSimpleAmp = np.linspace(0, 3, SIMPLE_SAMPLES)
stimSimpleAng = np.linspace(0, 2*np.pi, SIMPLE_SAMPLES)
stimRandAmp = np.random.rand(RAND_SAMPLES)
stimRandAng = np.random.rand(RAND_SAMPLES)*2*np.pi
stimAmp = np.concatenate((stimSimpleAmp, stimRandAmp))
stimAng = np.concatenate((stimSimpleAng, stimRandAng))
stimAmp[0] = 2**-12

stimI = np.cos(stimAng)*stimAmp
stimQ = np.sin(stimAng)*stimAmp

stimIQuant = psi_fix_from_real(stimI, IN_FMT, err_sat=False)
stimQQuant = psi_fix_from_real(stimQ, IN_FMT, err_sat=False)

#Simulation
model = psi_fix_complex_abs(IN_FMT, OUT_FMT, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
out = model.Process(stimIQuant, stimQQuant)

########################################################################################################################
# Plots
########################################################################################################################
if PLOT_ON:
    fig, ax = plt.subplots(2,1)
    exp = np.sqrt(stimIQuant**2+stimQQuant**2)
    exp = np.minimum(exp, psi_fix_upper_bound(OUT_FMT))
    ax[0].plot(out, "b")
    ax[0].plot(exp, "r")
    ax[0].set_title("compare to expected")
    ax[1].plot(out-exp)
    ax[1].plot(2**-OUT_FMT.F*np.ones_like(out), "r")
    ax[1].plot(-2 ** -OUT_FMT.F * np.ones_like(out), "r")
    ax[1].set_title("error")
    plt.show()

########################################################################################################################
# Write Files
########################################################################################################################
try:
    os.makedirs(STIM_DIR)
except FileExistsError:
    pass

np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((psi_fix_get_bits_as_int(stimIQuant, IN_FMT),
                            psi_fix_get_bits_as_int(stimQQuant, IN_FMT))),
           fmt="%i", header="I Q")
np.savetxt(STIM_DIR + "/output.txt",
           psi_fix_get_bits_as_int(out, OUT_FMT),
           fmt="%i", header="abs")
