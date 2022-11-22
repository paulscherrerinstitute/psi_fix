from psi_fix_pkg import *

class psi_fix_complex_addsub:
    def __init__(self, inAFmt: psi_fix_fmt_t,
                 inBFmt : psi_fix_fmt_t,
                 outFmt : psi_fix_fmt_t,
                 rnd    : psi_fix_rnd_t = psi_fix_rnd_t.round,
                 sat    : psi_fix_sat_t = psi_fix_sat_t.sat):
        self.inAFmt = inAFmt
        self.inBFmt = inBFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat

    # Returns a tuple i, q
    def Process(self, ai, aq, bi, bq, addSub):
        # resize real number to Fixed Point
        aif = psi_fix_from_real(ai, self.inAFmt)
        aqf = psi_fix_from_real(aq, self.inAFmt)
        bif = psi_fix_from_real(bi, self.inBFmt)
        bqf = psi_fix_from_real(bq, self.inBFmt)

        #Summations
        if addSub==1:
            sumI = psi_fix_add(aif, self.inAFmt, bif, self.inBFmt, self.outFmt, self.rnd, self.sat)
            sumQ = psi_fix_add(aqf, self.inAFmt, bqf, self.inBFmt, self.outFmt, self.rnd, self.sat)
        else:
            sumI = psi_fix_sub(aif, self.inAFmt, bif, self.inBFmt, self.outFmt, self.rnd, self.sat)
            sumQ = psi_fix_sub(aqf, self.inAFmt, bqf, self.inBFmt, self.outFmt, self.rnd, self.sat)

        return sumI, sumQ
