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
                        inFmt : psi_fix_fmt_t,
                        outFmt : psi_fix_fmt_t,
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
        self.diffFmt = psi_fix_fmt_t(inFmt.s, inFmt.i+order+1, inFmt.f)
        self.accuFmt = psi_fix_fmt_t(inFmt.s, inFmt.i+self.cicAddBits, inFmt.f)
        self.shftInFmt = psi_fix_fmt_t(inFmt.s, inFmt.i, inFmt.f+self.cicAddBits)
        self.gcInFmt = psi_fix_fmt_t(1, outFmt.i, min(24 - outFmt.i, self.shftInFmt.f))
        if autoGainCorr:
            self.shiftOutFmt = psi_fix_fmt_t(inFmt.s, inFmt.i, self.gcInFmt.f+1)
        else:
            self.shiftOutFmt = psi_fix_fmt_t(inFmt.s, inFmt.i, outFmt.f+1)
        #Constants
        self.gcCoefFmt = psi_fix_fmt_t(0,1,16)
        self.gc = psi_fix_from_real(2**self.cicAddBits/self.cicGain, self.gcCoefFmt)

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
        sig = psi_fix_from_real(inp, self.inFmt)

        # Do differentiation
        sigDiff = []
        sigDiff.append(sig)
        for stage in range(self.order):
            last = np.concatenate((np.zeros([self.diffDelay]), sigDiff[stage][0:-self.diffDelay]))
            stageOut = psi_fix_sub(sigDiff[stage], self.diffFmt,
                                 last, self.diffFmt, self.diffFmt)
            sigDiff.append(stageOut)

        # Insert Zeros
        diffOut = sigDiff[-1]
        interpol = np.zeros((self.ratio,diffOut.size))
        interpol[0] = diffOut
        interpol = np.reshape(interpol, (1,interpol.size), "F")[0]

        # Do integration in integer to avoid fixed point precision problems
        sigInt = []
        sigInt.append(np.array(psi_fix_get_bits_as_int(interpol, self.accuFmt), dtype=object))
        for stage in range(self.order):
            stageOut = np.zeros(interpol.size, dtype=object)
            integrator = int(0)
            for i in range(interpol.size):
                integrator = (integrator + sigInt[stage][i]) % (1 << int(psi_fix_size(self.accuFmt)))
                stageOut[i] = integrator
            sigInt.append(stageOut)
        intOut = sigInt[-1]

        # Do decimation and shift
        addFracPlaces = self.shiftOutFmt.f - self.accuFmt.f
        if self.shift - addFracPlaces > 0:
            sigSftUns = (intOut >> (self.shift - addFracPlaces)) % (1 << int(psi_fix_size(self.shiftOutFmt)))
        else:
            sigSftUns = (intOut << (addFracPlaces - self.shift)) % (1 << int(psi_fix_size(self.shiftOutFmt)))
        signBitValue = 1 << int(psi_fix_size(self.shiftOutFmt) - 1)
        sigSftInt = np.where(sigSftUns >= signBitValue, sigSftUns - 2 * signBitValue, sigSftUns)
        sigSft = psi_fix_from_bits_as_int(sigSftInt, self.shiftOutFmt)

        # Gain Compensation
        if self.autoGainCorr:
            sigGcIn = psi_fix_resize(sigSft, self.shiftOutFmt, self.gcInFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
            sigGcOut = psi_fix_mult(sigGcIn, self.gcInFmt,
                                  self.gc, self.gcCoefFmt,
                                  self.outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
            return sigGcOut
        else:
            return psi_fix_resize(sigSft, self.shiftOutFmt, self.outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)










