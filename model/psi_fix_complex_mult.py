from psi_fix_pkg import *

class psi_fix_complex_mult:
    def __init__(self, inAFmt: PsiFixFmt,
                 inBFmt: PsiFixFmt,
                 internalFmt : PsiFixFmt,
                 outFmt : PsiFixFmt,
                 rnd : PsiFixRnd = PsiFixRnd.Round,
                 sat : PsiFixSat = PsiFixSat.Sat):
        self.inAFmt = inAFmt
        self.inBFmt = inBFmt
        self.internalFmt = internalFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat

    # Returns a tuple i, q
    def Process(self, ai, aq, bi, bq):
        # resize real number to Fixed Point
        aif = PsiFixFromReal(ai, self.inAFmt)
        aqf = PsiFixFromReal(aq, self.inAFmt)
        bif = PsiFixFromReal(bi, self.inBFmt)
        bqf = PsiFixFromReal(bq, self.inBFmt)

        # Multiplications
        multIQ = PsiFixMult(aif, self.inAFmt, bqf, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multQI = PsiFixMult(aqf, self.inAFmt, bif, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multII = PsiFixMult(aif, self.inAFmt, bif, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        multQQ = PsiFixMult(aqf, self.inAFmt, bqf, self.inBFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        #Summations
        sumI = PsiFixSub(multII, self.internalFmt, multQQ, self.internalFmt, self.outFmt, self.rnd, self.sat)
        sumQ = PsiFixAdd(multIQ, self.internalFmt, multQI, self.internalFmt, self.outFmt, self.rnd, self.sat)

        return sumI, sumQ
