from psi_fix_pkg import *

class psi_fix_complex_addsub:
    def __init__(self, inAFmt: PsiFixFmt,
                 inBFmt : PsiFixFmt,
                 outFmt : PsiFixFmt,
                 rnd    : PsiFixRnd = PsiFixRnd.Round,
                 sat    : PsiFixSat = PsiFixSat.Sat):
        self.inAFmt = inAFmt
        self.inBFmt = inBFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat

    # Returns a tuple i, q
    def Process(self, ai, aq, bi, bq, addSub):
        # resize real number to Fixed Point
        aif = PsiFixFromReal(ai, self.inAFmt)
        aqf = PsiFixFromReal(aq, self.inAFmt)
        bif = PsiFixFromReal(bi, self.inBFmt)
        bqf = PsiFixFromReal(bq, self.inBFmt)

        #Summations
        if addSub==1:
            sumI = PsiFixAdd(aif, self.inAFmt, bif, self.inBFmt, self.outFmt, self.rnd, self.sat)
            sumQ = PsiFixAdd(aqf, self.inAFmt, bqf, self.inBFmt, self.outFmt, self.rnd, self.sat)
        else:
            sumI = PsiFixSub(aif, self.inAFmt, bif, self.inBFmt, self.outFmt, self.rnd, self.sat)
            sumQ = PsiFixSub(aqf, self.inAFmt, bqf, self.inBFmt, self.outFmt, self.rnd, self.sat)

        return sumI, sumQ
