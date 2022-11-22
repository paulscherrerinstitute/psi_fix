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

    def __init__(self, inFmt : psi_fix_fmt_t, outFmt : psi_fix_fmt_t, rnd : psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat : psi_fix_sat_t = psi_fix_sat_t.wrap):
        self._inFmt = inFmt
        self._outFmt = outFmt
        self._absFmt = psi_fix_fmt_t(0, inFmt.i, inFmt.f)
        self._sat = sat
        self._rnd = rnd
        self._inFmtNorm = psi_fix_fmt_t(0, 1, inFmt.i+inFmt.f)
        self._outFmtNorm = psi_fix_fmt_t(0, 1+self._inFmt.f, outFmt.i+outFmt.f)
        self._sqrt = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Invert18Bit)

    def Process(self, data : np.ndarray) -> np.ndarray:
        """
        Processing function
        :param data: Input data
        :return: inversion (1/x) of input data
        """

        #Input quantization
        d_fix = psi_fix_from_real(data, self._inFmt)

        #Input normalization (to range 1.0 ... 2.0)
        d_abs = psi_fix_abs(d_fix, self._inFmt, self._absFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)
        sign = d_fix < 0
        normSft = self._inFmt.i-1
        if normSft > 0:
            d_norm = psi_fix_shift_right(d_abs, self._absFmt, normSft, normSft, self._inFmtNorm)
        else:
            d_norm = psi_fix_shift_left(d_abs, self._absFmt, -normSft, -normSft, self._inFmtNorm)

        #Calculate square-root
        sft = np.ceil(-np.log2(d_norm+1e-12))
        sft = np.minimum(sft, self._inFmtNorm.f)
        invIn = psi_fix_shift_left(d_norm, self._inFmt, sft, self._inFmtNorm.f, psi_fix_lin_approx.CONFIGS.Invert18Bit.inFmt, psi_fix_rnd_t.trunc)
        resInv = self._sqrt.Approximate(invIn)
        sftIn = psi_fix_resize(resInv, psi_fix_lin_approx.CONFIGS.Invert18Bit.outFmt, self._outFmtNorm)
        resSft = psi_fix_shift_left(sftIn, self._outFmtNorm, sft, np.ceil(self._inFmtNorm.f + 1), self._outFmtNorm, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        if normSft > 0:
            denorm = psi_fix_shift_right(resSft, self._outFmtNorm, normSft, normSft, self._outFmt, self._rnd, self._sat)
        else:
            denorm = psi_fix_shift_left(resSft, self._outFmtNorm, -normSft, -normSft, self._outFmt, self._rnd, self._sat)
        return np.where(sign,psi_fix_neg(denorm, self._outFmt, self._outFmt, psi_fix_rnd_t.trunc, self._sat),denorm)




