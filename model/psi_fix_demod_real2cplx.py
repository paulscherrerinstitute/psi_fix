########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
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
    def __init__(self, inFmt: PsiFixFmt, outFmt : PsiFixFmt, coefBits : int, ratio: int):
        """
        Constructor for the demodulator model object
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format
        :param coefBits: Number of bits to use for the coefficients of the sin/cos demodulation table
        :param ratio: Ratio Fsample/Fsignal (must be integer)
        """
        self.inFmt = inFmt
        self.outFmt = outFmt
        coefUnusedIntBits = np.floor(np.log2(ratio))
        self.coefFmt = PsiFixFmt(1, 0-coefUnusedIntBits, coefBits+coefUnusedIntBits-1)
        self.outFmt = outFmt
        self.ratio = ratio
        self.multFmt = PsiFixFmt(1, self.inFmt.I+self.coefFmt.I, self.outFmt.F+np.ceil(np.log2(ratio)) + 2) #truncation error does only lead to 1/4 LSB error on output
        self.movAvg = psi_fix_mov_avg(self.multFmt, self.outFmt, ratio, psi_fix_mov_avg.GAINCORR_NONE, PsiFixRnd.Round, PsiFixSat.Sat)

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
        dataFix = PsiFixFromReal(inData, self.inFmt, errSat=True)

        #Limit the phase offset
        phaseOffset = np.minimum(phOffset, self.ratio-1).astype("int32")

        #ROM pointer
        #Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(inData.size,dtype=np.int64)
        phaseSteps[0] = 0 #start at zero
        cptInt = np.cumsum(phaseSteps,dtype=np.int64) % self.ratio
        cptIntOffs = cptInt + phaseOffset
        cpt = np.where(cptIntOffs > self.ratio-1, cptIntOffs - self.ratio, cptIntOffs)

        #Get Sin/Cos value
        scale = (1.0-2.0**-self.coefFmt.F)/self.ratio
        sinTable = PsiFixFromReal(np.sin(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.coefFmt)
        cosTable = PsiFixFromReal(np.cos(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.coefFmt)

        #I-Path
        multI = PsiFixMult(dataFix, self.inFmt, sinTable[cpt], self.coefFmt, self.multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        resI = self.movAvg.Process(multI)

        #Q-Path
        multQ = PsiFixMult(dataFix, self.inFmt, cosTable[cpt], self.coefFmt, self.multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        resQ = self.movAvg.Process(multQ)

        return resI, resQ

