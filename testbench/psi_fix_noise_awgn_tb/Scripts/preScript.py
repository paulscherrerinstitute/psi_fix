########################################################################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
from psi_fix_pkg import *
from psi_fix_noise_awgn import psi_fix_noise_awgn
from matplotlib import pyplot as plt
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
FORMAT = PsiFixFmt(1,0,15)

Gen = psi_fix_noise_awgn(FORMAT)
Results = Gen.Generate(SAMPLES)

#############################################################
# Plots
#############################################################
if PLOT_ON:
    fig, ax = plt.subplots(3, 1)
    ax[0].plot(Results)
    ax[0].set_title("values")
    spec = np.abs(np.fft.fft(Results))
    specDb = 20*np.log10(spec+1e-12)
    ax[1].plot(specDb)
    ax[1].set_title("Spectrum in dB")
    ax[2].hist(Results, 20)
    ax[2].set_title("Distribution")
    plt.show()



#############################################################
# Write Files for Co sim
#############################################################
np.savetxt(STIM_DIR + "/output.txt".format(FORMAT), PsiFixGetBitsAsInt(Results, FORMAT), fmt="%i", header="noise")


