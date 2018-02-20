from psi_fix_pkg import *
import numpy as np
from scipy.signal import lfilter
from scipy.misc import derivative
import matplotlib.pyplot as plt


class psi_fix_fir:
    """
    General model of a fixed point FIR filter. The model represents any bittrue implementation of a FIR, independently
    of tis RTL implementation (multi-channel, serial/parallel, etc.).

    It is assumed that the accumulator never wraps ans rounding/saturatio only happens at the output (accumulator would wrap)
    """

    def __init__(self,  inFmt : PsiFixFmt,
                        outFmt : PsiFixFmt,
                        coefFmt : PsiFixFmt):
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.coefFmt = coefFmt
        self.accuFmt = PsiFixFmt(1, outFmt.I + 1, inFmt.F + coefFmt.F)
        self.roundFmt = PsiFixFmt(self.accuFmt.S, self.accuFmt.I, self.outFmt.F)

    def Filter(self, inp : np.ndarray, decimRate : int, coefficients : np.ndarray):
        sat, outp = self.FilterSatDetect(inp, decimRate, coefficients)
        return outp

    def FilterSatDetect(self, inp : np.ndarray, decimRate : int, coefficients : np.ndarray):
        #Force integer (MATLAB may pass 1.0 as float)
        decimRate = int(decimRate)
        #Make input fixed point
        inp = PsiFixFromReal(inp, self.inFmt)
        coefs = PsiFixFromReal(coefficients, self.coefFmt)
        #Filter and round
        res = lfilter(coefs, 1, inp)
        resRnd = PsiFixResize(res, self.accuFmt, self.roundFmt, PsiFixRnd.Round)
        #Decimate
        resDec = resRnd[::decimRate]
        #Check saturation
        sat = np.zeros(resDec.size)
        sat = np.where(resDec > PsiFixUpperBound(self.outFmt), 1, sat)
        sat = np.where(resDec < PsiFixUpperBound(self.outFmt), 1, sat)
        #output
        outp = PsiFixResize(resDec, self.roundFmt, self.outFmt, PsiFixRnd.Trunc, PsiFixSat.Sat)#No rounding since no fractional bits must be removed
        return (sat, outp)









