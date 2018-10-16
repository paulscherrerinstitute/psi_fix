########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")

from psi_fix_pkg import *
from psi_fix_dds_18b import psi_fix_dds_18b
import matplotlib.pyplot as plt
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
PLOT_ON = False

np.random.seed(1)
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

########################################################################################################################
# Constants
########################################################################################################################
PHASE_FMT = PsiFixFmt(0, 0, 31)
PHASE_STEP = PsiFixFromReal(0.12345, PHASE_FMT)
PHASE_OFFS = PsiFixFromReal(0.98765, PHASE_FMT)
SAMPLES = 10000


########################################################################################################################
# Run Simulation
########################################################################################################################
model = psi_fix_dds_18b(PHASE_FMT)
sigSin, sigCos = model.Synthesize(PHASE_STEP, SAMPLES, PHASE_OFFS)

if PLOT_ON:
    sigCplx = 1j * sigSin + sigCos
    wndw = np.blackman(sigCplx.size)
    pwr = 20 * np.log10(abs(np.fft.fft(sigCplx*wndw/np.average(wndw))) / SAMPLES)
    frq = np.linspace(0, 1, pwr.size)
    plt.plot(frq, pwr)
    plt.grid()
    plt.xlabel("Frequency [Fs]")
    plt.ylabel("Amplitude [dB]")
    plt.title("Output Spectrum")
    plt.show()

########################################################################################################################
# Write Files
########################################################################################################################
with open(STIM_DIR + "/Config.txt", "w+") as f:
    f.write("PhaseStep PhaseOffs\n")
    f.write("{} {}".format(PsiFixGetBitsAsInt(PHASE_STEP, PHASE_FMT), PsiFixGetBitsAsInt(PHASE_OFFS, PHASE_FMT)))
with open(STIM_DIR + "/SinCos.txt", "w+") as f:
    sinInt = PsiFixGetBitsAsInt(sigSin, model.OUT_FMT)
    cosInt = PsiFixGetBitsAsInt(sigCos, model.OUT_FMT)
    for i in range(SAMPLES):
        f.write("{} {}\n".format(sinInt[i], cosInt[i]))



