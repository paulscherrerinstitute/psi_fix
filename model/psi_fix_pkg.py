from enum import Enum
import numpy as np


class PsiFixFmt:
    def __init__(self, S : int, I : int, F : int):
        self.S = S
        self.I = I
        self.F = F

    def __str__(self):
        return "({}, {}, {})".format(self.S, self.I, self.F)

    def __eq__(self, other):
        return (self.S == other.S) and (self.I == other.I) and (self.F == other.F)

class PsiFixRnd(Enum):
    Round = 0
    Trunc = 1

class PsiFixSat(Enum):
    Wrap = 0
    Sat = 1


########################################################################################################################
# Bittrue available in VHDL
########################################################################################################################
def PsiFixSize(fmt : PsiFixFmt) -> int:
    return fmt.S+fmt.I+fmt.F

def PsiFixFromReal(a,
                   rFmt : PsiFixFmt,
                   errSat : bool = True):
    x = np.floor(a*(2**rFmt.F)+0.5)/2**rFmt.F
    if np.ndim(a) == 0:
        a = np.array(a, ndmin=1)
    if errSat:
        if np.max(a) > PsiFixUpperBound(rFmt):
            raise ValueError("PsiFixFromReal: Number {} could not be represented by format {}".format(max(a), rFmt))
        if np.min(a) < PsiFixLowerBound(rFmt):
            raise ValueError("PsiFixFromReal: Number {} could not be represented by format {}".format(min(a), rFmt))
    x = np.where(x > PsiFixUpperBound(rFmt), PsiFixUpperBound(rFmt), x)
    x = np.where(x < PsiFixLowerBound(rFmt), PsiFixLowerBound(rFmt), x)
    return x

def PsiFixFromBitsAsInt(a : int, aFmt : PsiFixFmt):
    return np.array(a/2**aFmt.F, np.float64)

def PsiFixResize(a, aFmt : PsiFixFmt,
                 rFmt : PsiFixFmt,
                 rnd : PsiFixRnd = PsiFixRnd.Trunc, sat : PsiFixSat = PsiFixSat.Wrap):
    x = a
    #Remove fractional bits if required
    if rFmt.F < aFmt.F:
        x = x*(2**rFmt.F)
        #Add rounding constant if required
        if rnd is PsiFixRnd.Round:
            x += 0.5
        x = np.floor(x)
        x  = x*(2**-rFmt.F)
    #Remove integer bits if required
    if sat is PsiFixSat.Sat:
        x = np.where(x > PsiFixUpperBound(rFmt), PsiFixUpperBound(rFmt), x)
        x = np.where(x < PsiFixLowerBound(rFmt), PsiFixLowerBound(rFmt), x)
    x = x % (2**(rFmt.I+1))
    if rFmt.S is 1:
        x = np.where(x >= 2**(rFmt.I), x - 2**(rFmt.I+1), x)
    else:
        x = x % 2**(rFmt.I)
    return x

def PsiFixAdd(a, aFmt : PsiFixFmt,
              b, bFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    fullFmt = PsiFixFmt(max(aFmt.S, bFmt.S), max(aFmt.I, bFmt.I)+1, max(aFmt.F, bFmt.F))
    fullA = PsiFixResize(a, aFmt, fullFmt)
    fullB = PsiFixResize(b, bFmt, fullFmt)
    return PsiFixResize(fullA+fullB, fullFmt, rFmt, rnd, sat)

def PsiFixSub(a, aFmt : PsiFixFmt,
              b, bFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    fullFmt = PsiFixFmt(1, max(aFmt.I, bFmt.I+bFmt.S), max(aFmt.F, bFmt.F))
    fullA = PsiFixResize(a, aFmt, fullFmt)
    fullB = PsiFixResize(b, bFmt, fullFmt)
    return PsiFixResize(fullA-fullB, fullFmt, rFmt, rnd, sat)

def PsiFixMult(a, aFmt : PsiFixFmt,
               b, bFmt : PsiFixFmt,
               rFmt : PsiFixFmt,
               rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    fullFmt = PsiFixFmt(1, aFmt.I+bFmt.I+1, aFmt.F+bFmt.F)
    return PsiFixResize(a * b, fullFmt, rFmt, rnd, sat)

def PsiFixAbs(a, aFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    fullFmt = PsiFixFmt(1, aFmt.I+aFmt.S, aFmt.F)
    fullA = PsiFixResize(a, aFmt, fullFmt)
    neg = np.where(fullA < 0, -fullA, fullA)
    return PsiFixResize(neg, fullFmt, rFmt, rnd, sat)

def PsiFixNeg(a, aFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    fullFmt = PsiFixFmt(1, aFmt.I+aFmt.S, aFmt.F)
    fullA = PsiFixResize(a, aFmt, fullFmt)
    neg = -fullA
    return PsiFixResize(neg, fullFmt, rFmt, rnd, sat)

def PsiFixShiftLeft(a, aFmt : PsiFixFmt,
                    shift : int, maxShift : int,
                    rFmt : PsiFixFmt,
                    rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    if shift > maxShift:
        raise ValueError("PsiFixShiftLeft: shift must be <= maxShift")
    if shift < 0:
        raise ValueError("PsiFixShiftLeft: shift must be > 0")
    fullFmt = PsiFixFmt(max(aFmt.S, rFmt.S), max(aFmt.I+maxShift, rFmt.I), max(aFmt.F, rFmt.F))
    fullA = PsiFixResize(a, aFmt, fullFmt)
    bitsIn = PsiFixGetBitsAsInt(fullA, fullFmt)
    pwr2 =  np.array(np.power(2.0,shift), int)
    mlt = np.floor(bitsIn * pwr2)
    bitsOut = np.array(mlt, int)
    fullOut = PsiFixFromBitsAsInt(bitsOut, fullFmt)
    return PsiFixResize(fullOut, fullFmt, rFmt, rnd, sat)

########################################################################################################################
# Python only (helpers)
########################################################################################################################
def PsiFixUpperBound(rFmt : PsiFixFmt):
    return 2**rFmt.I-2**(-rFmt.F)

def PsiFixLowerBound(rFmt : PsiFixFmt):
    if rFmt.S is 1:
        return -2**rFmt.I
    else:
        return 0

def PsiFixGetBitsAsInt(a, aFmt : PsiFixFmt):
    return np.array(np.round(a*2.0**aFmt.F),int)

def PsiFixToInt(a, aFmt : PsiFixFmt):
    return a*2**aFmt.F


