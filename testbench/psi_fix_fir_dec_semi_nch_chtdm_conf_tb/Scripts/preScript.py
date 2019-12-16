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
from typing import NamedTuple

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
STIM_SAMPLES = 1000

PLOT_ON = True

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

Settings = NamedTuple("Settings", (("Ratio", int), ("Taps", int)))

#############################################################
# Inputs
#############################################################
#Common Settings
inFmt = PsiFixFmt(1, 0, 15)
outFmt = PsiFixFmt(1, 0, 13)
coefFmt = PsiFixFmt(1, 0, 17)

#Generate Common Inputs
np.random.seed(0)
sigRand = np.random.randn(STIM_SAMPLES)*2-1
sigRand = PsiFixFromReal(sigRand, inFmt, errSat=False)

sigRand2 = np.random.randn(STIM_SAMPLES)*2-1
sigRand2 = PsiFixFromReal(sigRand2, inFmt, errSat=False)

sigPulse = np.zeros(STIM_SAMPLES)
sigPulse[50] = 0.5
sigPulse = PsiFixFromReal(sigPulse, inFmt, errSat=False)

#############################################################
# Loop
#############################################################
#Settings
ALL_SETTINGS = [Settings(Ratio=3, Taps=48),
                Settings(Ratio=12, Taps=160),
                Settings(Ratio=1, Taps=48)]
fw = psi_fix_pkg_writer()
for s in ALL_SETTINGS:
    #############################################################
    # Simulation
    #############################################################
    coefs = sps.firwin(s.Taps, 0.6*1/s.Ratio)
    coefs = PsiFixFromReal(coefs, coefFmt)

    model = psi_fix_fir(inFmt, outFmt, coefFmt)

    respRand = model.Filter(sigRand, s.Ratio, coefs)
    respRand2 = model.Filter(sigRand2, s.Ratio, coefs)
    respPulse = model.Filter(sigPulse, s.Ratio, coefs)

    #############################################################
    # Write Files for Co sim
    #############################################################
    in2ch = np.reshape(np.column_stack((sigPulse, sigRand)), 2*sigPulse.size)
    out2ch = np.reshape(np.column_stack((respPulse, respRand)), 2*respPulse.size)

    in3ch = np.reshape(np.column_stack((sigPulse, sigRand, sigRand2)), 3*sigPulse.size)
    out3ch = np.reshape(np.column_stack((respPulse, respRand, respRand2)), 3*respPulse.size)

    np.savetxt(STIM_DIR + "/Input_1Ch.txt", PsiFixGetBitsAsInt(sigPulse, inFmt), fmt="%i", header="input")
    np.savetxt(STIM_DIR + "/Input_2Ch.txt", PsiFixGetBitsAsInt(in2ch, inFmt), fmt="%i", header="input interleaved")
    np.savetxt(STIM_DIR + "/Input_3Ch.txt", PsiFixGetBitsAsInt(in3ch, inFmt), fmt="%i", header="input interleaved")
    np.savetxt(STIM_DIR + "/Output_1Ch_R{}_{}Taps.txt".format(s.Ratio, s.Taps), PsiFixGetBitsAsInt(respPulse, outFmt), fmt="%i", header="output")
    np.savetxt(STIM_DIR + "/Output_2Ch_R{}_{}Taps.txt".format(s.Ratio, s.Taps), PsiFixGetBitsAsInt(out2ch, outFmt), fmt="%i", header="output interleaved")
    np.savetxt(STIM_DIR + "/Output_3Ch_R{}_{}Taps.txt".format(s.Ratio, s.Taps), PsiFixGetBitsAsInt(out3ch, outFmt), fmt="%i", header="output interleaved")
    np.savetxt(STIM_DIR + "/Coefs_R{}_{}Taps.txt".format(s.Ratio, s.Taps), PsiFixGetBitsAsInt(coefs, coefFmt), fmt="%i", header="coef")

    #############################################################
    # Write Coefficient File for Simulation
    #############################################################
    fw.AddArray("Coefs_R{}_{}Taps".format(s.Ratio, s.Taps), coefs, VhdlType.REAL)

fw.WritePkg("psi_fix_fir_dec_semi_nch_chtdm_conf_rbw_tb_coefs_pkg", STIM_DIR + "/..")



