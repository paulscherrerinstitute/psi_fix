########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Radoslaw Rybaniec
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
from psi_fix_demod_real2cplx import psi_fix_demod_real2cplx
from matplotlib import pyplot as plt
import scipy.signal as sps
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 10000

PLOT_ON = False
DEBUG_ON = True

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass


#############################################################
# Simulation
#############################################################
inFmt = psi_fix_fmt_t(1, 0, 15)
outFmt = psi_fix_fmt_t(1, 0, 16)

coefBits = 25
coefFmt = psi_fix_fmt_t(1, 0, coefBits)
fSample = 100e6

ratio_nums = [5, 100]
ratio_denums = [3, 1]

for ratio_num in ratio_nums:
    for ratio_denum in ratio_denums:
        #ratio_num = 5
        #ratio_denum = 3
        fSig = fSample/ratio_num

        coefUnusedIntBits = np.floor(np.log2(ratio_num))
        coefFmt = psi_fix_fmt_t(1, 0-coefUnusedIntBits, coefBits+coefUnusedIntBits-1)
        multFmt = psi_fix_fmt_t(1, inFmt.i + coefFmt.i, outFmt.f + np.ceil(np.log2(ratio_num)) + 2)
        #self.multFmt = psi_fix_fmt_t(1, self.inFmt.i+self.coefFmt.i, self.outFmt.f+np.ceil(np.log2(ratio_num/ratio_denum)) + 2) #truncation error does only lead to 1/4 LSB error on output

        FSTART = fSig*0.99
        FSTOP = fSig*1.01


        t = np.arange(0, (SAMPLES-1)/fSample, 1/fSample)
        sig = sps.chirp(t, FSTART, t[-1], FSTOP, method="linear")*0.99

        #We use IF 
        sig = np.sin(np.arange(0,SAMPLES-1)*2*np.pi*1/(ratio_num/ratio_denum))*(2**(inFmt.f+inFmt.i)-1)/2**(inFmt.f+inFmt.i)

        ## We use ones instead of Chirp
        #sig = np.ones(t.size)*(2**(inFmt.f+inFmt.i)-1)/2**(inFmt.f+inFmt.i)

        sigFix = psi_fix_from_real(sig, inFmt)
        phase = np.ones_like(sigFix)*0
        phase [100:1000] = 1

        demod = psi_fix_demod_real2cplx(inFmt, outFmt, coefBits, ratio_num, ratio_denum, DEBUG_ON)
        resI, resQ = demod.Process(sigFix, phase)

        #############################################################
        # Plot (if required)
        #############################################################
        if PLOT_ON:
            plt.figure()
            plt.plot(sig)
            plt.figure()
            plt.plot(resI, resQ)
            plt.figure()
            plt.plot(resI, 'b')
            plt.plot(resQ, 'r')
            plt.plot(np.sqrt(resI*resI + resQ*resQ), 'k')
            plt.show()


        #############################################################
        # Write Files for Co sim
        #############################################################
        np.savetxt(STIM_DIR + "/input_{}_{}.txt".format(ratio_num, ratio_denum),
                   np.column_stack((psi_fix_get_bits_as_int(sigFix, inFmt),
                                    #psi_fix_get_bits_as_int(sig2Fix, inFmt),
                                    phase)),
                   fmt="%i", header="input phase")
        np.savetxt(STIM_DIR + "/output_{}_{}.txt".format(ratio_num, ratio_denum),
                   np.column_stack((psi_fix_get_bits_as_int(resI, outFmt),
                                    psi_fix_get_bits_as_int(resQ, outFmt),
                                    )),
                                    #psi_fix_get_bits_as_int(res2I, outFmt),
                                    #psi_fix_get_bits_as_int(res2Q, outFmt))),
                   fmt="%i", header="result-I result-Q")

