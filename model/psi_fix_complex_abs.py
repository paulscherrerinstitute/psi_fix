########################################################################################################################
# Import Statements
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from psi_fix_lin_approx import psi_fix_lin_approx

from matplotlib import pyplot as plt

########################################################################################################################
# Model Definition
########################################################################################################################
class psi_fix_complex_abs:

    def __init__(self, inFmt : PsiFixFmt, outFmt : PsiFixFmt, rnd : PsiFixRnd = PsiFixRnd.Trunc, sat : PsiFixSat = PsiFixSat.Wrap):
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = PsiFixFmt(inFmt.S, 0, inFmt.I+inFmt.F)
        self._outFmtNorm = PsiFixFmt(outFmt.S, 0, outFmt.I+outFmt.F+1) #rounding bit is kept (used for output rounding)
        self._sqrFmt = PsiFixFmt(0, self._inFmtNorm.I + 1, self._inFmtNorm.F * 2)
        self._addFmt = PsiFixFmt(0, self._sqrFmt.I + 1, self._sqrFmt.F)
        self._limFmt = PsiFixFmt(0, 0, self._addFmt.F)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sqrt18Bit)

    def Process(self, dataI : np.ndarray, dataQ : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param dataI: Input data (I-part)
        :param dataQ: Input data (Q-part)
        :return: absolute value
        """

        #Input quantization
        i_fix = PsiFixFromReal(dataI, self._inFmt)
        q_fix = PsiFixFromReal(dataQ, self._inFmt)

        #Input normalization (to range +/- 1.0)
        i_norm = PsiFixShiftRight(i_fix, self._inFmt, self._inFmt.I, self._inFmt.I, self._inFmtNorm)
        q_norm = PsiFixShiftRight(q_fix, self._inFmt, self._inFmt.I, self._inFmt.I, self._inFmtNorm)

        #Squaring
        i_sqr = PsiFixMult(i_norm, self._inFmtNorm,
                           i_norm, self._inFmtNorm,
                           self._sqrFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)   #full output format supported
        q_sqr = PsiFixMult(q_norm, self._inFmtNorm,
                           q_norm, self._inFmtNorm,
                           self._sqrFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)   #full output format supported

        #Add
        sum = PsiFixAdd(i_sqr, self._sqrFmt,
                        q_sqr, self._sqrFmt,
                        self._addFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)   #full output format supported

        #Limit to 1
        lim = PsiFixResize(sum, self._addFmt, self._limFmt, PsiFixRnd.Trunc, PsiFixSat.Sat)

        #Calculate square-root
        sft = (np.ceil(-np.log2(lim+1e-12)/2)-1)*2
        sft = np.minimum(sft, self._limFmt.F)
        sqrtIn = PsiFixShiftLeft(lim, self._limFmt, sft, self._limFmt.F, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.inFmt, PsiFixRnd.Trunc)
        resSqrt = self._sqrt.Approximate(sqrtIn)
        sftIn = PsiFixResize(resSqrt, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.outFmt, self._outFmtNorm)
        resSft = PsiFixShiftRight(sftIn, self._outFmtNorm, sft / 2, self._limFmt.F / 2 + 1, self._outFmtNorm)
        return PsiFixShiftLeft(resSft, self._outFmtNorm, self._inFmt.I, self._inFmt.I, self._outFmt, self._rnd, self._sat)




