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

########################################################################################################################
# Bittrue model of the Moving Average
########################################################################################################################
class psi_fix_mov_avg:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    GAINCORR_NONE = "None"
    GAINCORR_ROUGH = "Rough"
    GAINCORR_EXACT = "Exact"

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  inFmt: PsiFixFmt,
                 outFmt : PsiFixFmt,
                 taps : int,
                 gaincorr : str = GAINCORR_EXACT,
                 rnd : PsiFixRnd = PsiFixRnd.Round,
                 sat : PsiFixSat = PsiFixSat.Sat):
        """
        Constructor for a moving average model object
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format
        :param taps: Number of taps (samples) the average is calculated over
        :param gaincorr: Gain correction mode (see documentation for details). Use one of the constants provided.
        :param rnd: Rounding mode at the output
        :param sat: Saturatioin mode at the output
        """
        #Checks
        if gaincorr not in (self.GAINCORR_EXACT, self.GAINCORR_NONE, self.GAINCORR_ROUGH):
            raise ValueError("psi_fix_mov_sum: gaincorr must be one of the constant values provided in the class")
        #Implementation
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.taps = taps
        self.gaincorr = gaincorr
        self.diffFmt = PsiFixFmt(1, inFmt.I+1, inFmt.F)
        self.rnd = rnd
        self.sat = sat
        gain = taps
        self.additionalBits = np.ceil(np.log2(gain))
        self.sumFmt = PsiFixFmt(1, inFmt.I+self.additionalBits, inFmt.F)
        self.gcInFmt = PsiFixFmt(1, inFmt.I, min(24-inFmt.I, self.sumFmt.F+self.additionalBits))
        self.gcCoefFmt = PsiFixFmt(0,1,16)
        self.gc = PsiFixFromReal(2.0**self.additionalBits/gain, self.gcCoefFmt)

    ####################################################################################################################
    # Public Methods
    ####################################################################################################################
    def Process(self, inData : np.ndarray) -> np.ndarray:
        """
        Process data using the model object
        :param inData: Input data
        :return: Output data
        """
        # resize real number to Fixed Point
        dataFix = PsiFixFromReal(inData, self.inFmt)

        #generate delayed version of the data
        dataDel = np.concatenate((np.zeros(self.taps), dataFix[:-self.taps]))

        #differentiate
        diff = PsiFixSub(dataFix, self.inFmt, dataDel, self.inFmt, self.diffFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap) #rounding not required, saturation cannot occur!

        #summation
        sum = PsiFixFromReal(np.cumsum(diff), self.sumFmt) #is bittrue since neither rounding nor saturation are required

        #Gain correction
        if self.gaincorr == self.GAINCORR_NONE:
            return PsiFixResize(sum, self.sumFmt, self.outFmt, self.rnd, self.sat)
        elif self.gaincorr == self.GAINCORR_ROUGH:
            return PsiFixShiftRight(sum, self.sumFmt, self.additionalBits, self.additionalBits, self.outFmt, self.rnd, self.sat)
        else:
            roughCorr = PsiFixShiftRight(sum, self.sumFmt, self.additionalBits, self.additionalBits, self.gcInFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
            return PsiFixMult(roughCorr, self.gcInFmt, self.gc, self.gcCoefFmt, self.outFmt, self.rnd, self.sat)




