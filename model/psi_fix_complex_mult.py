# =================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved 
# =================================================================
# Purpose   : Model using lib Psi_Fix for Complex multiplication
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : Psi Fix library elemental 
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  : psi_fix_matrix_rotation_2D.vhd
# ==================================================================
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *


class psi_fix_complex_mult:
    def __init__(self, inFmt: PsiFixFmt, outFmt: PsiFixFmt,
                 coefFmt: PsiFixFmt, internalFmt: PsiFixFmt):
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.coefFmt = coefFmt
        self.internalFmt = internalFmt

    def Process(self, ipath_i, qpath_i,
                i1_i, i2_i, q1_i, q2_i):
        # resize real number to Fixed Point
        datInp = PsiFixFromReal(ipath_i, self.inFmt, errSat=True)
        datQua = PsiFixFromReal(qpath_i, self.inFmt, errSat=True)

        # resize real number to Fixed Point
        coefI1 = PsiFixFromReal(i1_i, self.coefFmt, errSat=True)
        coefI2 = PsiFixFromReal(i2_i, self.coefFmt, errSat=True)
        coefQ1 = PsiFixFromReal(q1_i, self.coefFmt, errSat=True)
        coefQ2 = PsiFixFromReal(q2_i, self.coefFmt, errSat=True)

        # process calculation
        rotInp1 = PsiFixMult(datInp, self.inFmt, coefI1, self.coefFmt,
                             self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        rotInp2 = PsiFixMult(datQua, self.inFmt, coefI2, self.coefFmt,
                             self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        rotQua1 = PsiFixMult(datInp, self.inFmt, coefQ1, self.coefFmt,
                             self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        rotQua2 = PsiFixMult(datQua, self.inFmt, coefQ2, self.coefFmt,
                             self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        sumInp = PsiFixSub(rotInp1, self.internalFmt, rotInp2, self.internalFmt,
                           self.internalFmt, PsiFixRnd.Round, PsiFixSat.Sat)

        sumQua = PsiFixAdd(rotQua1, self.internalFmt, rotQua2, self.internalFmt,
                           self.internalFmt, PsiFixRnd.Round, PsiFixSat.Sat)

        outInp = PsiFixResize(sumInp, self.internalFmt, self.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        outQua = PsiFixResize(sumQua, self.internalFmt, self.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)

        return outInp, outQua
