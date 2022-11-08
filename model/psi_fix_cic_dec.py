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
# Decimating CIC model
########################################################################################################################
class psi_fix_cic_dec:
    """
    General model of a fixed point CIC decimator. The model represents any bittrue implementation of a CIC decimator, independently
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
        Creation of a decimating CIC model
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
        self.cicGain = (ratio*diffDelay)**order
        self.cicAddBits = ceil(log2(self.cicGain))
        self.shift = self.cicAddBits
        # CIC implementation does not rely on double-precision numbers for accumulators because they tend to
        # be quite large.
        with psi_fix_fmt_t.with_range_check_disabled():
            self.accuFmt = psi_fix_fmt_t(inFmt.s, inFmt.i+self.cicAddBits, inFmt.f)
        self.diffFmt = psi_fix_fmt_t(outFmt.s, inFmt.i, outFmt.f+order+1)
        self.gcInFmt = psi_fix_fmt_t(1, outFmt.i, min(24-outFmt.i, self.diffFmt.f))
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

        # Do integration in integer to avoid fixed point precision problems
        sigInt = []
        sigInt.append(np.array(psi_fix_get_bits_as_int(sig, self.inFmt), dtype=object))
        for stage in range(self.order):
            stageOut = np.zeros(sig.size, dtype=object)
            integrator = int(0)
            for i in range(sig.size):
                integrator = (integrator + sigInt[stage][i]) % (1 << int(psi_fix_size(self.accuFmt)))
                stageOut[i] = integrator
            sigInt.append(stageOut)

        # Do decimation and shift
        sigDecFull = np.array(sigInt[self.order][::self.ratio], dtype=object)
        addFracPlaces = self.diffFmt.f - self.accuFmt.f
        if self.shift - addFracPlaces > 0:
            sigDecSft = (sigDecFull >> (self.shift - addFracPlaces)) % (1 << int(psi_fix_size(self.diffFmt)))
        else:
            sigDecSft = (sigDecFull << (addFracPlaces - self.shift)) % (1 << int(psi_fix_size(self.diffFmt)))
        signBitValue = 1 << int(psi_fix_size(self.diffFmt) - 1)
        sigDecSft = np.where(sigDecSft >= signBitValue, sigDecSft - 2 * signBitValue, sigDecSft)
        sigDec = psi_fix_from_bits_as_int(sigDecSft, self.diffFmt)
        # Do differentiation
        sigDiff = []
        sigDiff.append(sigDec)
        for stage in range(self.order):
            last = np.concatenate((np.zeros([self.diffDelay]), sigDiff[stage][0:-self.diffDelay]))
            stageOut = psi_fix_sub(sigDiff[stage], self.diffFmt,
                                 last, self.diffFmt, self.diffFmt)
            sigDiff.append(stageOut)
        # Gain Compensation
        if self.autoGainCorr:
            sigGcIn = psi_fix_resize(sigDiff[self.order], self.diffFmt, self.gcInFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
            sigGcOut = psi_fix_mult(sigGcIn, self.gcInFmt,
                                  self.gc, self.gcCoefFmt,
                                  self.outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)
            return sigGcOut
        else:
            return psi_fix_resize(sigDiff[self.order], self.diffFmt, self.outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)










