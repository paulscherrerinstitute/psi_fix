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

    def __init__(self, inFmt : psi_fix_fmt_t, outFmt : psi_fix_fmt_t, rnd : psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat : psi_fix_sat_t = psi_fix_sat_t.wrap):
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = psi_fix_fmt_t(inFmt.s, 0, inFmt.i+inFmt.f)
        self._outFmtNorm = psi_fix_fmt_t(outFmt.s, 0, outFmt.i+outFmt.f+1) #rounding bit is kept (used for output rounding)
        self._sqrFmt = psi_fix_fmt_t(0, self._inFmtNorm.i + 1, self._inFmtNorm.f * 2)
        self._addFmt = psi_fix_fmt_t(0, self._sqrFmt.i + 1, self._sqrFmt.f)
        self._limFmt = psi_fix_fmt_t(0, 0, self._addFmt.f)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sqrt18Bit)

    def Process(self, dataI : np.ndarray, dataQ : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param dataI: Input data (I-part)
        :param dataQ: Input data (Q-part)
        :return: absolute value
        """

        #Input quantization
        i_fix = psi_fix_from_real(dataI, self._inFmt)
        q_fix = psi_fix_from_real(dataQ, self._inFmt)

        #Input normalization (to range +/- 1.0)
        i_norm = psi_fix_shift_right(i_fix, self._inFmt, self._inFmt.i, self._inFmt.i, self._inFmtNorm)
        q_norm = psi_fix_shift_right(q_fix, self._inFmt, self._inFmt.i, self._inFmt.i, self._inFmtNorm)

        #Squaring
        i_sqr = psi_fix_mult(i_norm, self._inFmtNorm,
                           i_norm, self._inFmtNorm,
                           self._sqrFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)   #full output format supported
        q_sqr = psi_fix_mult(q_norm, self._inFmtNorm,
                           q_norm, self._inFmtNorm,
                           self._sqrFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)   #full output format supported

        #Add
        sum = psi_fix_add(i_sqr, self._sqrFmt,
                        q_sqr, self._sqrFmt,
                        self._addFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)   #full output format supported

        #Limit to 1
        lim = psi_fix_resize(sum, self._addFmt, self._limFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)

        #Calculate square-root
        sft = (np.ceil(-np.log2(lim+1e-12)/2)-1)*2
        sft = np.minimum(sft, self._limFmt.f)
        sqrtIn = psi_fix_shift_left(lim, self._limFmt, sft, self._limFmt.f, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.inFmt, psi_fix_rnd_t.trunc)
        resSqrt = self._sqrt.Approximate(sqrtIn)
        sftIn = psi_fix_resize(resSqrt, psi_fix_lin_approx.CONFIGS.Sqrt18Bit.outFmt, self._outFmtNorm)
        resSft = psi_fix_shift_right(sftIn, self._outFmtNorm, sft / 2, np.ceil(self._limFmt.f / 2 + 1), self._outFmtNorm)
        return psi_fix_shift_left(resSft, self._outFmtNorm, self._inFmt.i, self._inFmt.i, self._outFmt, self._rnd, self._sat)




