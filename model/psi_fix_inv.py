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
class psi_fix_inv:

    def __init__(self, inFmt : PsiFixFmt, outFmt : PsiFixFmt, rnd : PsiFixRnd = PsiFixRnd.Trunc, sat : PsiFixSat = PsiFixSat.Wrap):
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._absFmt = PsiFixFmt(0, inFmt.I, inFmt.F)
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = PsiFixFmt(0, 1, inFmt.I+inFmt.F)
        self._outFmtNorm = PsiFixFmt(0, 1+self._inFmt.F, outFmt.I+outFmt.F)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Invert18Bit)

    def Process(self, data : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param data: Input data
        :return: inversion (1/x) of input data
        """

        #Input quantization
        d_fix = PsiFixFromReal(data, self._inFmt)

        #Input normalization (to range 1.0 ... 2.0)
        d_abs = PsiFixAbs(d_fix, self._inFmt, self._absFmt, PsiFixRnd.Trunc, PsiFixSat.Sat)
        sign = d_fix < 0
        normSft = self._inFmt.I-1
        if normSft > 0:
            d_norm = PsiFixShiftRight(d_abs, self._absFmt, normSft, normSft, self._inFmtNorm)
        else:
            d_norm = PsiFixShiftLeft(d_abs, self._absFmt, -normSft, -normSft, self._inFmtNorm)

        #Calculate square-root
        sft = np.ceil(-np.log2(d_norm+1e-12))
        sft = np.minimum(sft, self._inFmtNorm.F)
        invIn = PsiFixShiftLeft(d_norm, self._inFmt, sft, self._inFmtNorm.F, psi_fix_lin_approx.CONFIGS.Invert18Bit.inFmt, PsiFixRnd.Trunc)
        resInv = self._sqrt.Approximate(invIn)
        sftIn = PsiFixResize(resInv, psi_fix_lin_approx.CONFIGS.Invert18Bit.outFmt, self._outFmtNorm)
        resSft = PsiFixShiftLeft(sftIn, self._outFmtNorm, sft, np.ceil(self._inFmtNorm.F + 1), self._outFmtNorm, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        if normSft > 0:
            denorm = PsiFixShiftRight(resSft, self._outFmtNorm, normSft, normSft, self._outFmt, self._rnd, self._sat)
        else:
            denorm = PsiFixShiftLeft(resSft, self._outFmtNorm, -normSft, -normSft, self._outFmt, self._rnd, self._sat)
        return np.where(sign,PsiFixNeg(denorm, self._outFmt, self._outFmt, PsiFixRnd.Trunc, self._sat),denorm)




