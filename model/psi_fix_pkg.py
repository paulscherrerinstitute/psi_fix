########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from enum import Enum
import numpy as np
import os
import sys
#Iimport en_cl_fix package
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + "/../../en_cl_fix/python/src")
from en_cl_fix_pkg import *

########################################################################################################################
# Helper Classes
########################################################################################################################
class BittruenessNotGuaranteed(Exception): pass

class PsiFixFmt:
    def __init__(self, S : int, I : int, F : int, suppressRangeCheck : bool = False):
        self.S = S
        self.I = I
        self.F = F
        if PsiFixSize(self) > 53 and not suppressRangeCheck:
            raise BittruenessNotGuaranteed("PsiFixFmt: Format exceeding 53 bits (double range), bittrueness is not guaranteed!")

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
# PsiFix <-> ClFix conversion functions
########################################################################################################################
def PsiFix2ClFix(arg):
    if type(arg) is PsiFixFmt:
        return FixFormat(arg.S == 1, arg.I, arg.F)
    elif type(arg) is PsiFixRnd:
        if arg == PsiFixRnd.Round: return FixRound.NonSymPos_s
        elif arg == PsiFixRnd.Trunc: return FixRound.Trunc_s
        else: raise Exception("PsiFix2ClFix(): unsupported rounding mode")
    elif type(arg) is PsiFixSat:
        if arg == PsiFixSat.Wrap: return FixSaturate.None_s
        elif arg == PsiFixSat.Sat: return FixSaturate.Sat_s
        else: raise Exception("PsiFix2ClFix(): unsupported saturation mode")
    else:
        raise Exception("PsiFix2ClFix(): unsupported argument type")

def ClFix2PsiFix(arg):
    if type(arg) is FixFormat:
        signBits = 0
        if arg.Signed:
            signBits = 1
        return PsiFixFmt(signBits, arg.IntBits, arg.FracBits)
    elif type(arg) is FixRound:
        if arg == FixRound.NonSymPos_s: return PsiFixRnd.Round
        elif arg == FixRound.Trunc_s: return PsiFixRnd.Trunc
        else: raise Exception("PsiFix2ClFix(): unsupported rounding mode")
    elif type(arg) is FixSaturate:
        if arg == FixSaturate.None_s: return PsiFixSat.Wrap
        elif arg == FixSaturate.Sat_s: return PsiFixSat.Sat
        else: raise Exception("PsiFix2ClFix(): unsupported saturation mode")
    else:
        raise Exception("PsiFix2ClFix(): unsupported argument type")


########################################################################################################################
# Bittrue available in VHDL
########################################################################################################################
def PsiFixSize(fmt : PsiFixFmt) -> int:
    return cl_fix_width(PsiFix2ClFix(fmt))

def PsiFixFromReal(a,
                   rFmt : PsiFixFmt,
                   errSat : bool = True):
    # PsiFix specific implementation because of the errSat parameter that does not exist in cl_fix
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
    return cl_fix_from_bits_as_int(a, PsiFix2ClFix(aFmt))

def PsiFixGetBitsAsInt(a, aFmt : PsiFixFmt):
    return cl_fix_get_bits_as_int(a, PsiFix2ClFix(aFmt))

def PsiFixResize(a, aFmt : PsiFixFmt,
                 rFmt : PsiFixFmt,
                 rnd : PsiFixRnd = PsiFixRnd.Trunc, sat : PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_resize(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def PsiFixAdd(a, aFmt : PsiFixFmt,
              b, bFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_add(a, PsiFix2ClFix(aFmt),
                      b, PsiFix2ClFix(bFmt),
                      PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def PsiFixSub(a, aFmt : PsiFixFmt,
              b, bFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_sub(a, PsiFix2ClFix(aFmt),
                      b, PsiFix2ClFix(bFmt),
                      PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))


def PsiFixMult(a, aFmt : PsiFixFmt,
               b, bFmt : PsiFixFmt,
               rFmt : PsiFixFmt,
               rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_mult(a, PsiFix2ClFix(aFmt),
                       b, PsiFix2ClFix(bFmt),
                       PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def PsiFixAbs(a, aFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_abs(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def PsiFixNeg(a, aFmt : PsiFixFmt,
              rFmt : PsiFixFmt,
              rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    return cl_fix_neg(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd),PsiFix2ClFix(sat))

def PsiFixShiftLeft(a, aFmt : PsiFixFmt,
                    shift : int, maxShift : int,
                    rFmt : PsiFixFmt,
                    rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    # PsiFix specific implementation because of slightly different signature (related to synthesis issues)
    if np.any(shift > maxShift):
        raise ValueError("PsiFixShiftLeft: shift must be <= maxShift")
    if np.any(shift < 0):
        raise ValueError("PsiFixShiftLeft: shift must be > 0")
    fullFmt = PsiFixFmt(max(aFmt.S, rFmt.S), max(aFmt.I+maxShift, rFmt.I), max(aFmt.F, rFmt.F))
    fullA = PsiFixResize(a, aFmt, fullFmt)
    fullOut = fullA*2**shift
    return PsiFixResize(fullOut, fullFmt, rFmt, rnd, sat)

def PsiFixShiftRight(a, aFmt : PsiFixFmt,
                     shift : int, maxShift : int,
                     rFmt : PsiFixFmt,
                     rnd: PsiFixRnd = PsiFixRnd.Trunc, sat: PsiFixSat = PsiFixSat.Wrap):
    # PsiFix specific implementation because of slightly different signature (related to synthesis issues)
    if np.any(shift > maxShift):
        raise ValueError("PsiFixShiftRight: shift must be <= maxShift")
    if np.any(shift < 0):
        raise ValueError("PsiFixShiftRight: shift must be > 0")
    fullFmt = PsiFixFmt(max(aFmt.S, rFmt.S), max(aFmt.I, rFmt.I), max(aFmt.F+maxShift, rFmt.F+1))   #Additional bit for rounding
    fullA = PsiFixResize(a, aFmt, fullFmt)
    fullOut = fullA * 2**-shift
    return PsiFixResize(fullOut, fullFmt, rFmt, rnd, sat)

def PsiFixUpperBound(rFmt : PsiFixFmt):
    return cl_fix_max_value(PsiFix2ClFix(rFmt))

def PsiFixLowerBound(rFmt : PsiFixFmt):
    return cl_fix_min_value(PsiFix2ClFix(rFmt))

def PsiFixInRange(a, aFmt : PsiFixFmt,
                  rFmt : PsiFixFmt,
                  rnd: PsiFixRnd = PsiFixRnd.Trunc):
    return cl_fix_in_range(a, PsiFix2ClFix(aFmt), PsiFix2ClFix(rFmt), PsiFix2ClFix(rnd))

########################################################################################################################
# Python only (helpers)
########################################################################################################################
# Currently none




