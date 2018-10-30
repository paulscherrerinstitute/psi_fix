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
from math import *

########################################################################################################################
# Interpolating CIC model
########################################################################################################################
class psi_fix_cic_int:
    """
    General model of a fixed point CIC interpolator. The model represents any bittrue implementation of a CIC interpolator, independently
    of tis RTL implementation (multi-channel, serial/parallel, etc.)
    """

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  order : int,
                        ratio : int,
                        diffDelay : int,
                        inFmt : PsiFixFmt,
                        outFmt : PsiFixFmt,
                        autoGainCorr : bool):
        """
        Creation of a interpolating CIC model
        :param order: CIC order
        :param ratio: CIC decimation ratio
        :param diffDelay: Differential delay (usually 1 or 2)
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format
        :param autoGainCorr: True = CIC gain is automatically compensated, False = CIC gain is not compensated
        """
        #Store Config
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.order = order
        self.ratio = ratio
        self.diffDelay = diffDelay
        self.autoGainCorr = autoGainCorr
        #Calculated constants
        self.cicGain = ((ratio*diffDelay)**order)/ratio
        self.cicAddBits = ceil(log2(self.cicGain))
        self.shift = self.cicAddBits
        self.diffFmt = PsiFixFmt(inFmt.S, inFmt.I+order+1, inFmt.F)
        self.accuFmt = PsiFixFmt(inFmt.S, inFmt.I+self.cicAddBits, inFmt.F)
        self.shftInFmt = PsiFixFmt(inFmt.S, inFmt.I, inFmt.F+self.cicAddBits)
        self.gcInFmt = PsiFixFmt(1, outFmt.I, min(24 - outFmt.I, self.shftInFmt.F))
        if autoGainCorr:
            self.shiftOutFmt = PsiFixFmt(inFmt.S, inFmt.I, self.gcInFmt.F+1)
        else:
            self.shiftOutFmt = PsiFixFmt(inFmt.S, inFmt.I, outFmt.F+1)
        #Constants
        self.gcCoefFmt = PsiFixFmt(0,1,16)
        self.gc = PsiFixFromReal(2**self.cicAddBits/self.cicGain, self.gcCoefFmt)

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Process(self, inp : np.ndarray):
        """
        Process data using the CIC model object
        :param inp: Input data
        :return: Output data
        """

        #Make iniput fixed point
        sig = PsiFixFromReal(inp, self.inFmt)

        # Do differentiation
        sigDiff = []
        sigDiff.append(sig)
        for stage in range(self.order):
            last = np.concatenate((np.zeros([self.diffDelay]), sigDiff[stage][0:-self.diffDelay]))
            stageOut = PsiFixSub(sigDiff[stage], self.diffFmt,
                                 last, self.diffFmt, self.diffFmt)
            sigDiff.append(stageOut)

        # Insert Zeros
        diffOut = sigDiff[-1]
        interpol = np.zeros((self.ratio,diffOut.size))
        interpol[0] = diffOut
        interpol = np.reshape(interpol, (1,interpol.size), "F")[0]

        # Do integration in integer to avoid fixed point precision problems
        sigInt = []
        sigInt.append(np.array(PsiFixGetBitsAsInt(interpol, self.accuFmt), dtype=object))
        for stage in range(self.order):
            stageOut = np.zeros(interpol.size, dtype=object)
            integrator = int(0)
            for i in range(interpol.size):
                integrator = (integrator + sigInt[stage][i]) % (1 << int(PsiFixSize(self.accuFmt)))
                stageOut[i] = integrator
            sigInt.append(stageOut)
        intOut = sigInt[-1]

        # Do decimation and shift
        addFracPlaces = self.shiftOutFmt.F - self.accuFmt.F
        if self.shift - addFracPlaces > 0:
            sigSftUns = (intOut >> (self.shift - addFracPlaces)) % (1 << int(PsiFixSize(self.shiftOutFmt)))
        else:
            sigSftUns = (intOut << (addFracPlaces - self.shift)) % (1 << int(PsiFixSize(self.shiftOutFmt)))
        signBitValue = 1 << int(PsiFixSize(self.shiftOutFmt) - 1)
        sigSftInt = np.where(sigSftUns >= signBitValue, sigSftUns - 2 * signBitValue, sigSftUns)
        sigSft = PsiFixFromBitsAsInt(sigSftInt, self.shiftOutFmt)

        # Gain Compensation
        if self.autoGainCorr:
            sigGcIn = PsiFixResize(sigSft, self.shiftOutFmt, self.gcInFmt, PsiFixRnd.Round, PsiFixSat.Sat)
            sigGcOut = PsiFixMult(sigGcIn, self.gcInFmt,
                                  self.gc, self.gcCoefFmt,
                                  self.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)
            return sigGcOut
        else:
            return PsiFixResize(sigSft, self.shiftOutFmt, self.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)










