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
    def __init__(self, inAFmt: PsiFixFmt,
                 inBFmt: PsiFixFmt,
                 internalFmt : PsiFixFmt,
                 outFmt : PsiFixFmt,
                 rnd : PsiFixRnd = PsiFixRnd.Round,
                 sat : PsiFixSat = PsiFixSat.Sat):
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
        aif = PsiFixFromReal(ai, self.inAFmt)
        aqf = PsiFixFromReal(aq, self.inAFmt)
        bif = PsiFixFromReal(bi, self.inBFmt)
        bqf = PsiFixFromReal(bq, self.inBFmt)

        # Multiplications
        multIQ = PsiFixMult(aif, self.inAFmt, bqf, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multQI = PsiFixMult(aqf, self.inAFmt, bif, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multII = PsiFixMult(aif, self.inAFmt, bif, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multQQ = PsiFixMult(aqf, self.inAFmt, bqf, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        #Summations
        sumI = PsiFixSub(multII, self.internalFmt, multQQ, self.internalFmt, self.outFmt, self.rnd, self.sat)
        sumQ = PsiFixAdd(multIQ, self.internalFmt, multQI, self.internalFmt, self.outFmt, self.rnd, self.sat)

        return sumI, sumQ
