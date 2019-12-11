########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_fir import psi_fix_fir
from psi_fix_pkg_writer import psi_fix_pkg_writer, VhdlType
from matplotlib import pyplot as plt
from scipy import signal as sps
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
STIM_SAMPLES = 1000

PLOT_ON = True

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Simulation
#############################################################
inFmt = PsiFixFmt(1, 0, 15)
outFmt = PsiFixFmt(1, 0, 13)
coefFmt = PsiFixFmt(1, 0, 17)
Taps = 48

np.random.seed(0)
sigRand = np.random.randn(STIM_SAMPLES)*2-1
sigRand = PsiFixFromReal(sigRand, inFmt, errSat=False)

sigRand2 = np.random.randn(STIM_SAMPLES)*2-1
sigRand2 = PsiFixFromReal(sigRand2, inFmt, errSat=False)

sigPulse = np.zeros(STIM_SAMPLES)
sigPulse[50] = 0.5
sigPulse = PsiFixFromReal(sigPulse, inFmt, errSat=False)

coefs = sps.firwin(48, 0.2)
coefs = PsiFixFromReal(coefs, coefFmt)

model = psi_fix_fir(inFmt, outFmt, coefFmt)

respRand = model.Filter(sigRand, 1, coefs)
respRand2 = model.Filter(sigRand2, 1, coefs)
respPulse = model.Filter(sigPulse, 1, coefs)

#############################################################
# Write Files for Co sim
#############################################################

in2ch = np.reshape(np.column_stack((sigPulse, sigRand)), 2*STIM_SAMPLES)
out2ch = np.reshape(np.column_stack((respPulse, respRand)), 2*STIM_SAMPLES)

in3ch = np.reshape(np.column_stack((sigPulse, sigRand, sigRand2)), 3*STIM_SAMPLES)
out3ch = np.reshape(np.column_stack((respPulse, respRand, respRand2)), 3*STIM_SAMPLES)

np.savetxt(STIM_DIR + "/Input_1Ch.txt", PsiFixGetBitsAsInt(sigPulse, inFmt), fmt="%i", header="input")
np.savetxt(STIM_DIR + "/Input_2Ch.txt", PsiFixGetBitsAsInt(in2ch, inFmt), fmt="%i", header="input interleaved")
np.savetxt(STIM_DIR + "/Input_3Ch.txt", PsiFixGetBitsAsInt(in3ch, inFmt), fmt="%i", header="input interleaved")
np.savetxt(STIM_DIR + "/Output_1Ch.txt", PsiFixGetBitsAsInt(respPulse, outFmt), fmt="%i", header="output")
np.savetxt(STIM_DIR + "/Output_2Ch.txt", PsiFixGetBitsAsInt(out2ch, outFmt), fmt="%i", header="output interleaved")
np.savetxt(STIM_DIR + "/Output_3Ch.txt", PsiFixGetBitsAsInt(out3ch, outFmt), fmt="%i", header="output interleaved")
np.savetxt(STIM_DIR + "/Coefs.txt", PsiFixGetBitsAsInt(coefs, coefFmt), fmt="%i", header="coef")

#############################################################
# Write Coefficient File for Simulation
#############################################################
fw = psi_fix_pkg_writer()
fw.AddArray("Coefs", coefs, VhdlType.REAL)
fw.WritePkg("psi_fix_fir_par_nch_chtdm_conf_tb_coefs_pkg", STIM_DIR + "/..")



