from psi_fix_pkg import *
import numpy as np

class psi_fix_cordic_abs_pl:

    def __init__(self, inFmt : PsiFixFmt, outFmt : PsiFixFmt, internalFmt : PsiFixFmt, iterations : int, round : PsiFixRnd, sat : PsiFixSat):
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.internalFmt = internalFmt
        self.iterations = iterations
        self.round = round
        self.sat = sat

    def Process(self, inpI, inpQ):
        x = PsiFixAbs(PsiFixFromReal(inpI, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        y = PsiFixResize(PsiFixFromReal(inpQ, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        for i in range(0, self.iterations):
            sftFmt = PsiFixFmt(1, self.internalFmt.I-i, self.internalFmt.F+i)
            x_sft = PsiFixFromReal(x / 2 ** i, sftFmt)
            y_sft = PsiFixFromReal(y / 2 ** i, sftFmt)
            x_sub = PsiFixSub(x, self.internalFmt, y_sft, sftFmt, self.internalFmt, self.round, self.sat)
            x_add = PsiFixAdd(x, self.internalFmt, y_sft, sftFmt, self.internalFmt, self.round, self.sat)
            x_next = np.where(y < 0, x_sub, x_add)
            y_sub = PsiFixSub(y, self.internalFmt, x_sft, sftFmt, self.internalFmt, self.round, self.sat)
            y_add = PsiFixAdd(y, self.internalFmt, x_sft, sftFmt, self.internalFmt, self.round, self.sat)
            y_next = np.where(y < 0, y_add, y_sub)
            x = x_next
            y = y_next
        return PsiFixResize(x, self.internalFmt, self.outFmt, self.round, self.sat)






