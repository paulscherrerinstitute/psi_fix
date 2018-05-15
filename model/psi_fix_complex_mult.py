#=================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved 
#=================================================================
# Purpose   : Model using lib Psi_Fix for Matrix rotation 2D
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : Psi Fix library elemental 
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  : psi_fix_matrix_rotation_2D.vhd
#==================================================================
from psi_fix_pkg import *
import numpy as np

class psi_fix_complex_mult:

    def __init__(self,  inFmt : PsiFixFmt, outFmt : PsiFixFmt,
                        coefFmt : PsiFixFmt, internalFmt : PsiFixFmt,
                        round : PsiFixRnd, sat : PsiFixSat):
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.coefFmt = coefFmt
        self.internalFmt = internalFmt
        self.round = round
        self.sat = sat

    def Process(self,   data_ipath_i, data_qpath_i,
                        coef_i1_cmd_i, coef_i2_cmd_i, coef_q1_cmd_i, coef_q2_cmd_i):

        # resize real number to Fixed Point
        datInp = PsiFixFromReal(data_ipath_i, self.inFmt, errSat=True)
        datQua = PsiFixFromReal(data_qpath_i, self.inFmt, errSat=True)

        # resize real number to Fixed Point
        coefI1 = PsiFixFromReal(coef_i1_cmd_i, self.coefFmt, errSat=True)
        coefI2 = PsiFixFromReal(coef_i2_cmd_i, self.coefFmt, errSat=True)
        coefQ1 = PsiFixFromReal(coef_q1_cmd_i, self.coefFmt, errSat=True)
        coefQ2 = PsiFixFromReal(coef_q2_cmd_i, self.coefFmt, errSat=True)

        print(PsiFixGetBitsAsInt(coefI1, self.coefFmt))
        print(PsiFixGetBitsAsInt(coefI2, self.coefFmt))
        print(PsiFixGetBitsAsInt(coefQ1, self.coefFmt))
        print(PsiFixGetBitsAsInt(coefQ2, self.coefFmt))

        # process calculation
        rotInp1 = PsiFixMult(datInp, self.inFmt, coefI1, self.coefFmt,
                             self.internalFmt, self.round, self.sat)
        rotInp2 = PsiFixMult(datQua, self.inFmt, coefI2, self.coefFmt,
                             self.internalFmt, self.round, self.sat)

        rotQua1 = PsiFixMult(datInp, self.inFmt, coefQ1, self.coefFmt,
                             self.internalFmt, self.round, self.sat)
        rotQua2 = PsiFixMult(datQua, self.inFmt, coefQ2, self.coefFmt,
                             self.internalFmt, self.round, self.sat)

        sumInp  = PsiFixSub(rotInp1, self.internalFmt, rotInp2, self.internalFmt,
                            self.internalFmt, self.round, self.sat)

        sumQua  = PsiFixAdd(rotQua1, self.internalFmt, rotQua2, self.internalFmt,
                            self.internalFmt, self.round, self.sat)

        outInp = PsiFixResize(sumInp, self.internalFmt, self.outFmt, self.round, self.sat)
        outQua = PsiFixResize(sumQua, self.internalFmt, self.outFmt, self.round, self.sat)

        return outInp, outQua