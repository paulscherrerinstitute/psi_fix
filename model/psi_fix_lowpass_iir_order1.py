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

########################################################################################################################
# Bittrue model if the First-Order IIR low-pass filter
########################################################################################################################
class psi_fix_lowpass_iir_order1:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  fSampleHz : float,
                        fCutoffHz : float,
                        inFmt : psi_fix_fmt_t,
                        outFmt : psi_fix_fmt_t,
                        intFmt : psi_fix_fmt_t,
                        coefFmt : psi_fix_fmt_t,
                        rnd : psi_fix_rnd_t = psi_fix_rnd_t.round,
                        sat : psi_fix_sat_t = psi_fix_sat_t.sat):
        """
        Constructor for the IIR model
        :param fSampleHz: Sample frequency in Hz
        :param fCutoffHz: Cutoff frequency in Hz
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format
        :param intFmt: Internal fixed-point format (see documentation)
        :param coefFmt: Coefficient format
        :param rnd: Rounding mode
        :param sat: Saturation Mode
        """
        #Save formats
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.intFmt = intFmt
        self.coefFmt = coefFmt
        self.rnd = rnd
        self.sat = sat

        #Coefficient calculation
        alpha = self.CoefAlphaCalc(fSampleHz, fCutoffHz)
        self.alpha = psi_fix_from_real(alpha, coefFmt)
        self.beta = psi_fix_from_real(1.0-alpha, coefFmt)

    ####################################################################################################################
    # Public Methods
    ####################################################################################################################
    def Filter(self, data : np.ndarray):
        """
        Filter data using the model object
        :param data: Input data
        :return: Output data
        """
        dataFix = psi_fix_from_real(data, self.inFmt)
        mulIn = psi_fix_mult(dataFix, self.inFmt, self.beta, self.coefFmt, self.intFmt, self.rnd, self.sat)

        #Looping is not avoidable for a recorsive filter...
        out = np.empty_like(data)
        fb = 0
        for i, mulIn_i in enumerate(mulIn):
            add = psi_fix_add(mulIn_i, self.intFmt, fb, self.intFmt, self.intFmt, sat=self.sat) #Rounding not required since fractional bits are not changed
            fb = psi_fix_mult(add, self.intFmt, self.alpha, self.coefFmt, self.intFmt, self.rnd, self.sat)
            out[i] = psi_fix_resize(add, self.intFmt, self.outFmt, self.rnd, self.sat)
        return out

    ####################################################################################################################
    # Private Methods (do not call!)
    ####################################################################################################################
    @classmethod
    def CoefAlphaCalc(cls, fSampleHz : float, fCutoffHz):
        tau = 1.0/(2*np.pi*fCutoffHz)
        return np.exp(-(1.0/fSampleHz)/tau)










