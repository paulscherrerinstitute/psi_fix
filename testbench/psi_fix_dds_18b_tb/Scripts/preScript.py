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
PHASE_STEP0 = PsiFixFromReal(0.12345, PHASE_FMT)
PHASE_OFFS0 = PsiFixFromReal(0.98765, PHASE_FMT)
PHASE_STEP1 = PsiFixFromReal(0.2, PHASE_FMT)
PHASE_OFFS1 = PsiFixFromReal(0.3, PHASE_FMT)
SAMPLES = 10000


########################################################################################################################
# Run Simulation
########################################################################################################################
model = psi_fix_dds_18b(PHASE_FMT)
sigSin0, sigCos0 = model.Synthesize(PHASE_STEP0, SAMPLES, PHASE_OFFS0)
sigSin1, sigCos1 = model.Synthesize(PHASE_STEP1, SAMPLES, PHASE_OFFS1)

if PLOT_ON:
    sigCplx = 1j * sigSin0 + sigCos0
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
# 1 Channel
np.savetxt(STIM_DIR + "/Config.txt",
           np.column_stack((np.repeat(PsiFixGetBitsAsInt(PHASE_STEP0, PHASE_FMT), SAMPLES),
                            np.repeat(PsiFixGetBitsAsInt(PHASE_OFFS0, PHASE_FMT), SAMPLES))),
           fmt="%i", header="PhaseStep PhaseOFfs")
np.savetxt(STIM_DIR + "/SinCos.txt",
           np.column_stack((PsiFixGetBitsAsInt(sigSin0, model.OUT_FMT),
                            PsiFixGetBitsAsInt(sigCos0, model.OUT_FMT))),
           fmt="%i", header="Sin Cos")

# 2 Channels
np.savetxt(STIM_DIR + "/Config2Ch.txt",
           np.column_stack((np.tile(PsiFixGetBitsAsInt(np.array([PHASE_STEP0, PHASE_STEP1]), PHASE_FMT), SAMPLES,),
                            np.tile(PsiFixGetBitsAsInt(np.array([PHASE_OFFS0, PHASE_OFFS1]), PHASE_FMT), SAMPLES))),
           fmt="%i", header="PhaseStep PhaseOFfs")
np.savetxt(STIM_DIR + "/SinCos2Ch.txt",
           np.column_stack((PsiFixGetBitsAsInt(np.hstack(list(zip(sigSin0,sigSin1))), model.OUT_FMT),
                            PsiFixGetBitsAsInt(np.hstack(list(zip(sigCos0,sigCos1))), model.OUT_FMT))),
           fmt="%i", header="Sin Cos")



