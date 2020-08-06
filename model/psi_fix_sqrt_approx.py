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
class psi_fix_sqrt_approx:

    def __init__(self, inFmt : PsiFixFmt, outFmt : PsiFixFmt, rnd : PsiFixRnd = PsiFixRnd.Trunc, sat : PsiFixSat = PsiFixSat.Wrap):
        assert inFmt.S == 0, "class psi_fix_sqrt_approx: inFmt must be unsigned, square root for negative numbers is not defined"
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = PsiFixFmt(inFmt.S, 0, inFmt.I+inFmt.F)
        self._outFmtNorm = PsiFixFmt(outFmt.S, 0, outFmt.I+outFmt.F+1) #rounding bit is kept (used for output rounding)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sqrt18Bit)

    def Process(self, data : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param data: Input data
        :return: square root of input data
        """

        #Input quantization
        d_fix = PsiFixFromReal(data, self._inFmt)

        #Input normalization (to range +/- 1.0)
        normSft = np.ceil(self._inFmt.I/2)*2
        d_norm = PsiFixShiftRight(d_fix, self._inFmt, normSft, normSft, self._inFmtNorm)

        #Calculate square-root
        sft = (np.ceil(-np.log2(d_norm+1e-12)/2)-1)*2
        sft = np.minimum(sft, self._inFmt.F)
        sqrtIn = PsiFixShiftLeft(d_norm, self._inFmt, sft, self._inFmt.F, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.inFmt, PsiFixRnd.Trunc)
        resSqrt = self._sqrt.Approximate(sqrtIn)
        sftIn = PsiFixResize(resSqrt, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.outFmt, self._outFmtNorm)
        resSft = PsiFixShiftRight(sftIn, self._outFmtNorm, sft / 2, self._inFmt.F / 2 + 1, self._outFmtNorm)
        denorm = PsiFixShiftLeft(resSft, self._outFmtNorm, normSft/2, normSft/2, self._outFmt, self._rnd, self._sat)
        return denorm




