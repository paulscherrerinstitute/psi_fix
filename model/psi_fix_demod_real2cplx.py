from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
from typing import Tuple, Union


class psi_fix_demod_real2cplx:
    def __init__(self, dataFmt: PsiFixFmt, ratio: int):
        self.dataFmt = dataFmt
        self.ratio = ratio
        self.subFmt = PsiFixFmt(dataFmt.S, dataFmt.I+1, dataFmt.F)

    def Process(self, inData : np.ndarray, phOffset : Union[np.ndarray,float]) -> Tuple[np.ndarray, np.ndarray]:
        # resize real number to Fixed Point
        dataFix = PsiFixFromReal(inData, self.dataFmt, errSat=True)

        #Limit the phase offset
        phaseOffset = np.minimum(phOffset, self.ratio-1).astype("int32")

        #ROM pointer
        #Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(inData.size,dtype=np.int64)
        phaseSteps[0] = 0 #start at zero
        cptInt = np.cumsum(phaseSteps,dtype=np.int64) % self.ratio
        cptIntOffs = cptInt + phaseOffset
        cpt = np.where(cptIntOffs > self.ratio-1, cptIntOffs - self.ratio, cptIntOffs)

        #Get Sin/Cos value
        scale = 1.0-2.0**-self.dataFmt.F
        sinTable = PsiFixFromReal(np.sin(2.0*np.pi*np.arange(0, self.ratio)/self.ratio)*scale, self.dataFmt)
        cosTable = PsiFixFromReal(np.cos(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.dataFmt)

        #I-Path
        multI = PsiFixMult(dataFix, self.dataFmt, sinTable[cpt], self.dataFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        delI = np.concatenate((np.zeros(self.ratio), multI[:-self.ratio]))
        subI = PsiFixSub(multI, self.dataFmt, delI, self.dataFmt, self.subFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        addI = PsiFixResize(np.cumsum(subI), self.subFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)

        #Q-Path
        multQ = PsiFixMult(dataFix, self.dataFmt, cosTable[cpt], self.dataFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        delQ = np.concatenate((np.zeros(self.ratio), multQ[:-self.ratio]))
        subQ = PsiFixSub(multQ, self.dataFmt, delQ, self.dataFmt, self.subFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        addQ = PsiFixResize(np.cumsum(subQ), self.subFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)


        return addI, addQ

