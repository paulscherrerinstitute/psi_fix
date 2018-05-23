from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
from typing import Tuple, Union
from psi_fix_mov_avg import psi_fix_mov_avg


class psi_fix_demod_real2cplx:
    def __init__(self, dataFmt: PsiFixFmt, ratio: int):
        self.dataFmt = dataFmt
        self.ratio = ratio
        self.subFmt = PsiFixFmt(dataFmt.S, dataFmt.I+1, dataFmt.F)
        self.movAvg = psi_fix_mov_avg(dataFmt, dataFmt, ratio, psi_fix_mov_avg.GAINCORR_NONE, PsiFixRnd.Round, PsiFixSat.Sat)


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
        scale = (1.0-2.0**-self.dataFmt.F)/self.ratio
        sinTable = PsiFixFromReal(np.sin(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.dataFmt)
        cosTable = PsiFixFromReal(np.cos(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.dataFmt)

        #I-Path
        multI = PsiFixMult(dataFix, self.dataFmt, sinTable[cpt], self.dataFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        resI = self.movAvg.Process(multI)

        #Q-Path
        multQ = PsiFixMult(dataFix, self.dataFmt, cosTable[cpt], self.dataFmt, self.dataFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        resQ = self.movAvg.Process(multQ)

        return resI, resQ

