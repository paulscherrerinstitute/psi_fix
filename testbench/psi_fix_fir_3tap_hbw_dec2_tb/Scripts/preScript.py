########################################################################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Radoslaw Rybaniec
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_fir import psi_fix_fir
from matplotlib import pyplot
from scipy import signal

import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 1000

PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
# Simulation
#############################################################
inFmt = psi_fix_fmt_t(1, 0, 17)
outFmt = psi_fix_fmt_t(1, 0, 17)
coefFmt = psi_fix_fmt_t(1, 0, 17)

h = np.array([0.25,0.5,0.25])

#############################################################
# Write Files for Co sim
#############################################################

MAX_CHANNELS = 4
DATA_LEN = 512

inData = psi_fix_from_real(np.random.random((MAX_CHANNELS,DATA_LEN))*0.9999-0.5, inFmt)
outData = np.zeros((MAX_CHANNELS,DATA_LEN//2))

for ch in range(0, MAX_CHANNELS):
    inData[ch,0:16] = 0.0
    f = psi_fix_fir(inFmt, outFmt, coefFmt)
    outData[ch] = f.Filter(inData[ch], 2, h)
    inData[ch,1:]=inData[ch,0:-1]

for separate in [True, False]:
    for channels in [1,2,4]:
        with open(STIM_DIR + "/inChannels{}Separate{}.txt".format(int(channels), separate), "w+") as f:
            if separate:
                for i in range(0,inData.shape[1],2):
                    line = ""
                    for ch in range(0,inData.shape[0]):
                        line = line + "{} {} ".format(int(psi_fix_get_bits_as_int(inData[ch,i], inFmt)), int(psi_fix_get_bits_as_int(inData[ch,i+1], inFmt)))
                    f.writelines(line+"\n")
            else:
                for i in range(0,inData.shape[1],2*channels):
                    line = ""
                    for ch in range(0,2*channels,2):
                        line = line + "{} {} ".format(int(psi_fix_get_bits_as_int(inData[1,i+ch], inFmt)), int(psi_fix_get_bits_as_int(inData[1,i+ch+1], inFmt)))
                    f.writelines(line+"\n")

        with open(STIM_DIR + "/outChannels{}Separate{}.txt".format(int(channels), separate), "w+") as f:                
            if separate:
                for i in range(0,outData.shape[1]):
                    line = ""
                    for ch in range(0,outData.shape[0]):
                        line = line + " {}".format(int(psi_fix_get_bits_as_int(outData[ch,i], outFmt)))
                    f.writelines(line+"\n")
            else:
                for i in range(0,outData.shape[1],channels):
                    line = ""
                    for ch in range(0,channels):
                        line = line + " {}".format(int(psi_fix_get_bits_as_int(outData[1,i+ch], outFmt)))
                    f.writelines(line+"\n")

                    
                    


