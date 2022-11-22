########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef, Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *

########################################################################################################################
# Complex Multiplication model
########################################################################################################################
class psi_fix_complex_mult:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, inAFmt: psi_fix_fmt_t,
                 inBFmt: psi_fix_fmt_t,
                 internalFmt : psi_fix_fmt_t,
                 outFmt : psi_fix_fmt_t,
                 rnd : psi_fix_rnd_t = psi_fix_rnd_t.round,
                 sat : psi_fix_sat_t = psi_fix_sat_t.sat):
        """
        Creation of a complex multiplication model
        :param inAFmt: Input A fixed point format
        :param inBFmt: Input B fixed point format
        :param internalFmt: Internal fixed point format (see documentatino for details)
        :param outFmt: Output fixed point format
        :param rnd: Rounding mode at the output
        :param sat: Saturation mode at the output
        """
        self.inAFmt = inAFmt
        self.inBFmt = inBFmt
        self.internalFmt = internalFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Process(self, ai, aq, bi, bq):
        """
        Process data using the complex multiplication model

        :param ai: Input A, real-part
        :param aq: Input A, imaginary-part
        :param bi: Input B, real-part
        :param bq: Input B, imaginary part
        :return: Result tuple (I, Q)
        """
        aif = psi_fix_from_real(ai, self.inAFmt)
        aqf = psi_fix_from_real(aq, self.inAFmt)
        bif = psi_fix_from_real(bi, self.inBFmt)
        bqf = psi_fix_from_real(bq, self.inBFmt)

        # Multiplications
        multIQ = psi_fix_mult(aif, self.inAFmt, bqf, self.inBFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        multQI = psi_fix_mult(aqf, self.inAFmt, bif, self.inBFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        multII = psi_fix_mult(aif, self.inAFmt, bif, self.inBFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        multQQ = psi_fix_mult(aqf, self.inAFmt, bqf, self.inBFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)

        #Summations
        sumI = psi_fix_sub(multII, self.internalFmt, multQQ, self.internalFmt, self.outFmt, self.rnd, self.sat)
        sumQ = psi_fix_add(multIQ, self.internalFmt, multQI, self.internalFmt, self.outFmt, self.rnd, self.sat)

        return sumI, sumQ
