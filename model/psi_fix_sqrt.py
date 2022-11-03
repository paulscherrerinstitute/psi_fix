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
class psi_fix_sqrt:

    def __init__(self, inFmt : psi_fix_fmt_t, outFmt : psi_fix_fmt_t, rnd : psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat : psi_fix_sat_t = psi_fix_sat_t.wrap):
        assert inFmt.s == 0, "class psi_fix_sqrt: inFmt must be unsigned, square root for negative numbers is not defined"
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = psi_fix_fmt_t(inFmt.s, 0, inFmt.i+inFmt.f)
        self._outFmtNorm = psi_fix_fmt_t(outFmt.s, 0, outFmt.i+outFmt.f+1) #rounding bit is kept (used for output rounding)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sqrt18Bit)

    def Process(self, data : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param data: Input data
        :return: square root of input data
        """

        #Input quantization
        d_fix = psi_fix_from_real(data, self._inFmt)

        #Input normalization (to range +/- 1.0)
        normSft = np.ceil(self._inFmt.i/2)*2
        d_norm = psi_fix_shift_right(d_fix, self._inFmt, normSft, normSft, self._inFmtNorm)

        #Calculate square-root
        sft = (np.ceil(-np.log2(d_norm+1e-12)/2)-1)*2
        sft = np.minimum(sft, self._inFmt.f)
        sqrtIn = psi_fix_shift_left(d_norm, self._inFmt, sft, self._inFmt.f, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.inFmt, psi_fix_rnd_t.trunc)
        resSqrt = self._sqrt.Approximate(sqrtIn)
        sftIn = psi_fix_resize(resSqrt, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.outFmt, self._outFmtNorm)
        resSft = psi_fix_shift_right(sftIn, self._outFmtNorm, sft / 2, np.ceil(self._inFmt.f / 2 + 1), self._outFmtNorm, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        denorm = psi_fix_shift_left(resSft, self._outFmtNorm, normSft/2, normSft/2, self._outFmt, self._rnd, self._sat)
        return np.where(data==0,0,denorm)




