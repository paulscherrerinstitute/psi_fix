########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
import scipy.signal as sps
from psi_fix_pkg import *
from psi_fix_fir import psi_fix_fir
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 1000
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
# Functions
#############################################################

def WriteFile(signal, filePath, fracBits):
    # Scale to fixed point
    signal = (signal * pow(2, fracBits)).round()

    # Write to File
    with open(filePath, "w+") as f:
        f.writelines(["{}\n".format(int(val)) for val in signal])

#############################################################
# Data Generation
#############################################################
inFmt = PsiFixFmt(1, 0, 16)
coefFmt = PsiFixFmt(1, 0, 15)
outFmt = PsiFixFmt(1, 0, 17)

coefs = sps.firwin(12, 0.2)
coefsFix = PsiFixFromReal(coefs, coefFmt)

np.random.seed(0)
inSig = []
for i in range(2):
    sigFloat = (np.random.rand(SAMPLES)-0.5)*1.99
    sigFix = PsiFixFromReal(sigFloat, inFmt)
    inSig.append(sigFix)

outSig = []
model = psi_fix_fir(inFmt, outFmt, coefFmt)
for i in range(2):
    firOut = model.Filter(inSig[i], 3, coefsFix)
    outSig.append(firOut)

#############################################################
# Write files
#############################################################
with open(STIM_DIR + "/input.txt", "w+") as f:
    inSigInt0 = PsiFixGetBitsAsInt(inSig[0], inFmt)
    inSigInt1 = PsiFixGetBitsAsInt(inSig[1], inFmt)
    for i in range(SAMPLES):
        f.write("{} {}\n".format(inSigInt0[i], inSigInt1[i]))

with open(STIM_DIR + "/coefs.txt", "w+") as f:
    for c in coefsFix:
        f.write("{}\n".format(PsiFixGetBitsAsInt(c, coefFmt)))


with open(STIM_DIR + "/output.txt", "w+") as f:
    outSigInt0 = PsiFixGetBitsAsInt(outSig[0], outFmt)
    outSigInt1 = PsiFixGetBitsAsInt(outSig[1], outFmt)
    for i in range(outSig[0].size):
        f.write("{} {}\n".format(outSigInt0[i], outSigInt1[i]))


