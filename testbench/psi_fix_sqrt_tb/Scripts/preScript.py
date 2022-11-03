########################################################################################################################
# Set path
########################################################################################################################
import sys
sys.path.append("../../../model")

########################################################################################################################
# Import Statements
########################################################################################################################
from psi_fix_sqrt import psi_fix_sqrt
from psi_fix_pkg import *
import numpy as np
from matplotlib import pyplot as plt
import os

########################################################################################################################
# Constants
########################################################################################################################
PLOT_ON = False
SIMPLE_SAMPLES = 20
RAND_SAMPLES = 200

filepath = os.path.realpath(__file__)
dirpath = os.path.dirname(filepath)
STIM_DIR = os.path.join(dirpath, "../Data")

IN_FMT = psi_fix_fmt_t(0, 2, 14)
OUT_FMT = psi_fix_fmt_t(1, 0, 15)

########################################################################################################################
# Simulation
########################################################################################################################
# Stimuli Data
stimSimple = np.linspace(0.01, 3, SIMPLE_SAMPLES)
stimRand= np.random.rand(RAND_SAMPLES)
stim = np.concatenate(([1/8, 1/4, 1/2, 1, 2, 4], stimSimple, stimRand))

stimQuant = psi_fix_from_real(stim, IN_FMT, err_sat=False)

#Simulation
model = psi_fix_sqrt(IN_FMT, OUT_FMT, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
out = model.Process(stimQuant)

########################################################################################################################
# Plots
########################################################################################################################
if PLOT_ON:
    fig, ax = plt.subplots(2,1)
    exp = np.sqrt(stimQuant)
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
           psi_fix_get_bits_as_int(stimQuant, IN_FMT),
           fmt="%i", header="I Q")
np.savetxt(STIM_DIR + "/output.txt",
           psi_fix_get_bits_as_int(out, OUT_FMT),
           fmt="%i", header="sqrt")
