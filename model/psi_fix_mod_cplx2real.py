# =================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved
# =================================================================
# Purpose   : Model using lib Psi_Fix for Complex Modulator
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : Psi Fix library elemental
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  : psi_fix_mod_cplx2real.vhd
# ==================================================================
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *

class psi_fix_mod_cplx2real:
    def __init__(self,  InpFmt  : PsiFixFmt,
                        CoefFmt : PsiFixFmt,
                        IntFmt  : PsiFixFmt,
                        OutFmt  : PsiFixFmt,
                 ratio: int):
        self.InpFmt = InpFmt
        self.OutFmt = OutFmt
        self.CoefFmt = CoefFmt
        self.IntFmt = IntFmt
        self.ratio = ratio

    def Process(self, data_I_i: np.ndarray, data_Q_i : np.ndarray):
        # resize real number to Fixed Point
        multFmt = PsiFixFmt(self.InpFmt.S, self.InpFmt.I+self.CoefFmt.I,self.InpFmt.F+self.CoefFmt.F)
        addFmt = PsiFixFmt(multFmt.S, multFmt.I+multFmt.I,multFmt.F)
        datInp = PsiFixFromReal(data_I_i, self.InpFmt, errSat=True)
        datQua = PsiFixFromReal(data_Q_i, self.InpFmt, errSat=True)

        # ROM pointer
        # Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(data_I_i.size, dtype=np.int64)
        phaseSteps[0] = 0  # start at zero
        cptInt = np.cumsum(phaseSteps, dtype=np.int64) % self.ratio
        cptIntOffs = cptInt + 1
        cpt = np.where(cptIntOffs > self.ratio - 1, cptIntOffs - self.ratio, cptIntOffs)

        # Get Sin/Cos value
        scale = 1.0 - 2.0 ** -self.CoefFmt.F
        sinTable = PsiFixFromReal(np.sin(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.CoefFmt)
        cosTable = PsiFixFromReal(np.cos(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.CoefFmt)

        # process calculation
        mult_i_s = PsiFixMult(datInp, self.InpFmt, sinTable[cpt], self.CoefFmt, multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        mult_q_s = PsiFixMult(datQua, self.InpFmt, cosTable[cpt], self.CoefFmt, multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        sum_s = PsiFixAdd(mult_i_s, multFmt, mult_q_s, multFmt, addFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        rf_s = PsiFixResize(sum_s, addFmt, self.OutFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        rf_o = rf_s
        return rf_o

