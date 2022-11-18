########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Benoit Stef, Radoslaw Rybaniec
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
from typing import Tuple, Union
from psi_fix_mov_avg import psi_fix_mov_avg

########################################################################################################################
# Demodulator Model
########################################################################################################################
class psi_fix_demod_real2cplx:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, inFmt: psi_fix_fmt_t, outFmt : psi_fix_fmt_t, coefBits : int, ratio_num: int, ratio_denum : int, debug : bool = False):
        """
        Constructor for the demodulator model object
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format
        :param coefBits: Number of bits to use for the coefficients of the sin/cos demodulation table
        :param ratio_num: Ratio Fsample/Fsignal (must be integer)
        :param ratio_denum: Ratio denominator
        :param debug: Debugging mode
        """
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.ratio_num = ratio_num
        self.ratio_denum = ratio_denum
        self._debug = debug
        coefUnusedIntBits = np.floor(np.log2(ratio_num))
        self.coefFmt = psi_fix_fmt_t(1, 0-coefUnusedIntBits, coefBits+coefUnusedIntBits-1)
        #self.multFmt = psi_fix_fmt_t(1, self.inFmt.i+self.coefFmt.i, self.outFmt.f+np.ceil(np.log2(ratio_num/ratio_denum)) + 2) #truncation error does only lead to 1/4 LSB error on output
        self.multFmt = psi_fix_fmt_t(1, self.inFmt.i+self.coefFmt.i, self.outFmt.f+np.ceil(np.log2(ratio_num)) + 2) #truncation error does only lead to 1/4 LSB error on output
        self.movAvg = psi_fix_mov_avg(self.multFmt, self.outFmt, ratio_num, psi_fix_mov_avg.GAINCORR_NONE, psi_fix_rnd_t.round, psi_fix_sat_t.sat)

    ####################################################################################################################
    # Public Methods and Properties
    ####################################################################################################################
    def Process(self, inData : np.ndarray, phOffset : Union[np.ndarray,float]) -> Tuple[np.ndarray, np.ndarray]:
        """
        Demodulate date using the model object
        :param inData: Input signal to demodulate
        :param phOffset: Offset within the demodulation coefficient table
        :return: Demodulated signal as tuple (I, Q)
        """
        # resize real number to Fixed Point
        dataFix = psi_fix_from_real(inData, self.inFmt, err_sat=True)

        #Limit the phase offset
        phaseOffset = np.minimum(phOffset, self.ratio_num-1).astype("int32")

        #ROM pointer
        #Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(inData.size,dtype=np.int64)
        phaseSteps[0] = 1-self.ratio_denum #start at zero
        cpt = (phaseOffset + np.cumsum(phaseSteps+self.ratio_denum-1, dtype=np.int64)) % self.ratio_num
        #Get Sin/Cos value
        scale = (1.0-2.0**-self.coefFmt.f)/self.ratio_num
        sinTable = psi_fix_from_real(np.sin(2.0 * np.pi * np.arange(0, self.ratio_num) / self.ratio_num) * scale, self.coefFmt)
        cosTable = psi_fix_from_real(np.cos(2.0 * np.pi * np.arange(0, self.ratio_num) / self.ratio_num) * scale, self.coefFmt)

        #I-Path
        multI = psi_fix_mult(dataFix, self.inFmt, sinTable[cpt], self.coefFmt, self.multFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        resI = self.movAvg.Process(multI)
        #Q-Path
        multQ = psi_fix_mult(dataFix, self.inFmt, cosTable[cpt], self.coefFmt, self.multFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        resQ = self.movAvg.Process(multQ)

        if self._debug:
            for i in range(10):
                print("I{:3} IN {:10} TAB {:10} MULT {:10} CPT {:x}".format(i,
                    psi_fix_to_hex(dataFix[i], self.inFmt),
                    psi_fix_to_hex(sinTable[cpt[i]], self.coefFmt),
                    psi_fix_to_hex(multI[i], self.multFmt),
                    cpt[i]))

        return resI, resQ
