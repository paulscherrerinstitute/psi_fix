from psi_fix_pkg import *
from psi_fix_lin_approx import psi_fix_lin_approx
import numpy as np

class psi_fix_pol2cart_approx:

    SIN_OUT_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.outFmt
    SIN_IN_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.inFmt

    def __init__(self, inAbsFmt : PsiFixFmt,
                 inAngleFmt : PsiFixFmt,
                 outFmt : PsiFixFmt,
                 rnd : PsiFixRnd = PsiFixRnd.Round,
                 sat : PsiFixSat = PsiFixSat.Sat):
        #checks
        if inAngleFmt.S == 1:    raise ValueError("psi_fix_pol2cart_approx: InAngleFmt must be unsigned")
        if inAbsFmt.S == 1:      raise ValueError("psi_fix_pol2cart_approx: InAbsFmt must be unsigned")
        if inAngleFmt.I > 0 :    raise ValueError("psi_fix_pol2cart_approx: InAngleFmt_g must be (1,0,x)")
        #Implementation
        self.inAbsFmt = inAbsFmt
        self.inAngleFmt = inAngleFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat
        self.sineApprox = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sin18Bit)

    #returns (I, Q)
    def Process(self, inpAbs, inpAngle) :
        phaseSin = PsiFixResize(inpAngle, self.inAngleFmt, self.SIN_IN_FMT, self.rnd, PsiFixSat.Wrap)
        phaseCos = PsiFixAdd(inpAngle, self.inAngleFmt, 0.25, self.SIN_IN_FMT, self.SIN_IN_FMT, self.rnd, PsiFixSat.Wrap)
        sinData = self.sineApprox.Approximate(phaseSin)
        cosData = self.sineApprox.Approximate(phaseCos)
        outI = PsiFixMult(inpAbs, self.inAbsFmt, cosData, self.SIN_OUT_FMT, self.outFmt, self.rnd, self.sat)
        outQ = PsiFixMult(inpAbs, self.inAbsFmt, sinData, self.SIN_OUT_FMT, self.outFmt, self.rnd, self.sat)
        return (outI, outQ)