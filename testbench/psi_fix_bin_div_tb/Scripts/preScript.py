########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_bin_div import psi_fix_bin_div
from matplotlib import pyplot
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 1000

PLOT_ON = False

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
# Simulation
#############################################################
numFmt = psi_fix_fmt_t(1, 2, 5)
denomFmt = psi_fix_fmt_t(1, 2, 8)
outFmt = psi_fix_fmt_t(1, 4, 10)

np.random.seed(0)
num = (np.random.random(SAMPLES)-0.5)*2*3.9
denom = (np.random.random(SAMPLES)-0.5)*2*3.9
#num[0] = 3
#denom[0] = 0.5

numF = psi_fix_from_real(num, numFmt)
denomF = psi_fix_from_real(denom, denomFmt)

res = psi_fix_bin_div(numF, numFmt, denomF, denomFmt, outFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    resExp = numF/denomF
    resExp = psi_fix_from_real(resExp, outFmt, err_sat=False)
    err = res - resExp
    pyplot.plot(err*2**outFmt.f)
    pyplot.show()

#############################################################
# Write Files for Co sim
#############################################################
with open(STIM_DIR + "/input.txt", "w+") as f:
    f.writelines(["{} {}\n".format(int(i), int(q)) for i, q in zip(psi_fix_get_bits_as_int(numF, numFmt), psi_fix_get_bits_as_int(denomF, denomFmt))])
with open(STIM_DIR + "/output.txt", "w+") as f:
    f.writelines(["{}\n".format(int(r)) for r in psi_fix_get_bits_as_int(res, outFmt)])

