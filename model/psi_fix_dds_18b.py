from psi_fix_pkg import *
from psi_fix_lin_approx import psi_fix_lin_approx
import numpy as np

class psi_fix_dds_18b:

    OUT_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.outFmt

    def __init__(self, phaseFmt : PsiFixFmt):
        #check out Fmt
        if phaseFmt.S is 1:
            raise ValueError("DwcDdsModel currently only supports unsigned phase formats, got {}".format(phaseFmt))
        self.phaseFmt = phaseFmt
        self.sineApprox = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sin18Bit)

    def Synthesize(self, phaseStep : float, numOfSamples : int , phaseOffset = 0.0):
        #Calculate inputs
        phaseStepFix = PsiFixFromReal(phaseStep, self.phaseFmt)
        phaseOffsetFix = PsiFixFromReal(phaseOffset, self.phaseFmt)
        #Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(numOfSamples,dtype=np.int64)*PsiFixGetBitsAsInt(phaseStepFix, self.phaseFmt)
        phaseSteps[0] = 0 #start at zero
        accumulator = np.cumsum(phaseSteps,dtype=np.int64) + PsiFixGetBitsAsInt(phaseOffsetFix, self.phaseFmt)
        accuWrapped = accumulator % 2**PsiFixSize(self.phaseFmt)
        accuPhase = PsiFixFromBitsAsInt(accuWrapped, self.phaseFmt)
        #Generate sine wave
        phaseQuantSin = PsiFixResize(accuPhase, self.phaseFmt, self.sineApprox.cfg.inFmt)
        phaseQuantCos = PsiFixResize(accuPhase+0.25, self.phaseFmt, self.sineApprox.cfg.inFmt)
        outSin = self.sineApprox.Approximate(phaseQuantSin)
        outCos = self.sineApprox.Approximate(phaseQuantCos)
        return (outSin, outCos)