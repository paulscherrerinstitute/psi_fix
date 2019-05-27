########################################################################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_white_noise import psi_fix_white_noise
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
FMT_U = PsiFixFmt(0,2,13)
FMT_S = PsiFixFmt(1,2,15)
FORMATS = {"U" : FMT_U, "S" : FMT_S}

Results = {}
for k, fmt in FORMATS.items():
    Gen = psi_fix_white_noise(fmt)
    Results[k] = Gen.Generate(SAMPLES)

#############################################################
# Plots
#############################################################
if PLOT_ON:
    for k, val in Results.items():
        fig, ax = plt.subplots(2, 1)
        fig.suptitle(k)
        ax[0].plot(val)
        ax[0].set_title("values")
        spec = np.abs(np.fft.fft(val))
        specDb = 20*np.log10(spec+1e-12)
        ax[1].plot(specDb)
        ax[1].set_title("Spectrum in dB")
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
for fmt, format in FORMATS.items():
    np.savetxt(STIM_DIR + "/output_{}.txt".format(fmt), PsiFixGetBitsAsInt(Results[fmt], format), fmt="%i", header="noise")


