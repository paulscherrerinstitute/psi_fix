########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler, Radoslaw Rybaniec
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from enum import Enum
import numpy as np
import os
import sys
import contextlib
#Iimport en_cl_fix package
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + "/../../en_cl_fix/python/src")
from en_cl_fix_pkg import *

########################################################################################################################
# Helper Classes
########################################################################################################################


class BittruenessNotGuaranteed(Exception): pass

class psi_fix_fmt_t:

    __enable_range_check = False

    def __init__(self, s : int, i : int, f : int):
        self.s = s
        self.i = i
        self.f = f
        if psi_fix_size(self) > 53 and self.__enable_range_check:
            raise BittruenessNotGuaranteed("psi_fix_fmt_t: Format exceeding 53 bits (double range), bittrueness is not guaranteed!")

    def __str__(self):
        return "({}, {}, {})".format(self.s, self.i, self.f)

    def __eq__(self, other):
        return (self.s == other.s) and (self.i == other.i) and (self.f == other.f)

    @classmethod
    def enable_range_check(cls, ena : bool):
        cls.__enable_range_check = ena

    @classmethod
    @contextlib.contextmanager
    def with_range_check_disabled(cls):
        enaBefore = cls.__enable_range_check
        cls.enable_range_check(False)
        yield
        cls.enable_range_check(enaBefore)

class psi_fix_rnd_t(Enum):
    round = 0
    trunc = 1

class psi_fix_sat_t(Enum):
    wrap = 0
    sat = 1

########################################################################################################################
# psi_fix <-> ClFix conversion functions
########################################################################################################################
def PsiFix2ClFix(arg):
    if type(arg) is psi_fix_fmt_t:
        return FixFormat(arg.s == 1, arg.i, arg.f)
    elif type(arg) is psi_fix_rnd_t:
        if arg == psi_fix_rnd_t.round: return FixRound.NonSymPos_s
        elif arg == psi_fix_rnd_t.trunc: return FixRound.Trunc_s
        else: raise Exception("PsiFix2ClFix(): unsupported rounding mode")
    elif type(arg) is psi_fix_sat_t:
        if arg == psi_fix_sat_t.wrap: return FixSaturate.None_s
        elif arg == psi_fix_sat_t.sat: return FixSaturate.Sat_s
        else: raise Exception("PsiFix2ClFix(): unsupported saturation mode")
    else:
        raise Exception("PsiFix2ClFix(): unsupported argument type")

def ClFix2PsiFix(arg):
    if type(arg) is FixFormat:
        signBits = 0
        if arg.Signed:
            signBits = 1
        return psi_fix_fmt_t(signBits, arg.IntBits, arg.FracBits)
    elif type(arg) is FixRound:
        if arg == FixRound.NonSymPos_s: return psi_fix_rnd_t.round
        elif arg == FixRound.trunc_s: return psi_fix_rnd_t.trunc
        else: raise Exception("PsiFix2ClFix(): unsupported rounding mode")
    elif type(arg) is FixSaturate:
        if arg == FixSaturate.None_s: return psi_fix_sat_t.wrap
        elif arg == FixSaturate.sat_s: return psi_fix_sat_t.sat
        else: raise Exception("PsiFix2ClFix(): unsupported saturation mode")
    else:
        raise Exception("PsiFix2ClFix(): unsupported argument type")


########################################################################################################################
# Bittrue available in VHDL
########################################################################################################################
def psi_fix_size(fmt : psi_fix_fmt_t) -> int:
    return cl_fix_width(PsiFix2ClFix(fmt))

def psi_fix_from_real(a,
                      r_fmt : psi_fix_fmt_t,
                      err_sat : bool = True):
    # psi_fix specific implementation because of the err_sat parameter that does not exist in cl_fix
    if err_sat:
        if np.max(a) > psi_fix_upper_bound(r_fmt):
            raise ValueError("psi_fix_from_real: Number {} could not be represented by format {}".format(np.max(a), r_fmt))
        if np.min(a) < psi_fix_lower_bound(r_fmt):
            raise ValueError("psi_fix_from_real: Number {} could not be represented by format {}".format(np.min(a), r_fmt))
    return cl_fix_from_real(a, PsiFix2ClFix(r_fmt), FixSaturate.Sat_s)

def psi_fix_from_bits_as_int(a : int, a_fmt : psi_fix_fmt_t):
    return cl_fix_from_bits_as_int(a, PsiFix2ClFix(a_fmt))

def psi_fix_get_bits_as_int(a, a_fmt : psi_fix_fmt_t):
    return cl_fix_get_bits_as_int(a, PsiFix2ClFix(a_fmt))

def psi_fix_resize(a, a_fmt : psi_fix_fmt_t,
                   r_fmt : psi_fix_fmt_t,
                   rnd : psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat : psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_resize(a, PsiFix2ClFix(a_fmt), PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_add(a, a_fmt : psi_fix_fmt_t,
                b, b_fmt : psi_fix_fmt_t,
                r_fmt : psi_fix_fmt_t,
                rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_add(a, PsiFix2ClFix(a_fmt),
                      b, PsiFix2ClFix(b_fmt),
                      PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_sub(a, a_fmt : psi_fix_fmt_t,
                b, b_fmt : psi_fix_fmt_t,
                r_fmt : psi_fix_fmt_t,
                rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_sub(a, PsiFix2ClFix(a_fmt),
                      b, PsiFix2ClFix(b_fmt),
                      PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))


def psi_fix_mult(a, a_fmt : psi_fix_fmt_t,
                 b, b_fmt : psi_fix_fmt_t,
                 r_fmt : psi_fix_fmt_t,
                 rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_mult(a, PsiFix2ClFix(a_fmt),
                       b, PsiFix2ClFix(b_fmt),
                       PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_abs(a, a_fmt : psi_fix_fmt_t,
                r_fmt : psi_fix_fmt_t,
                rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_abs(a, PsiFix2ClFix(a_fmt), PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_neg(a, a_fmt : psi_fix_fmt_t,
                r_fmt : psi_fix_fmt_t,
                rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    return cl_fix_neg(a, PsiFix2ClFix(a_fmt), PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd),PsiFix2ClFix(sat))

def psi_fix_shift_left(a, a_fmt : psi_fix_fmt_t,
                       shift : int, max_shift : int,
                       r_fmt : psi_fix_fmt_t,
                       rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    # psi_fix specific implementation because of slightly different signature (related to synthesis issues)
    if np.any(shift > max_shift):
        raise ValueError("psi_fix_shift_left: shift must be <= max_shift")
    if np.any(shift < 0):
        raise ValueError("psi_fix_shift_left: shift must be > 0")
    return cl_fix_shift(a, PsiFix2ClFix(a_fmt), shift, PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_shift_right(a, a_fmt : psi_fix_fmt_t,
                        shift : int, max_shift : int,
                        r_fmt : psi_fix_fmt_t,
                        rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc, sat: psi_fix_sat_t = psi_fix_sat_t.wrap):
    # psi_fix specific implementation because of slightly different signature (related to synthesis issues)
    if np.any(shift > max_shift):
        raise ValueError("psi_fix_shift_right: shift must be <= max_shift")
    if np.any(shift < 0):
        raise ValueError("psi_fix_shift_right: shift must be > 0")
    return cl_fix_shift(a, PsiFix2ClFix(a_fmt), -shift, PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd), PsiFix2ClFix(sat))

def psi_fix_upper_bound(r_fmt : psi_fix_fmt_t):
    return cl_fix_max_value(PsiFix2ClFix(r_fmt))

def psi_fix_lower_bound(r_fmt : psi_fix_fmt_t):
    return cl_fix_min_value(PsiFix2ClFix(r_fmt))

def psi_fix_in_range(a, a_fmt : psi_fix_fmt_t,
                     r_fmt : psi_fix_fmt_t,
                     rnd: psi_fix_rnd_t = psi_fix_rnd_t.trunc):
    return cl_fix_in_range(a, PsiFix2ClFix(a_fmt), PsiFix2ClFix(r_fmt), PsiFix2ClFix(rnd))

########################################################################################################################
# Python only (helpers)
########################################################################################################################

def psi_fix_write_formats(fmts, names, filename):
    # Note: Do not convert to FixFormat. Rely on psi_fix_fmt_t.__str__ to format the string correctly.
    cl_fix_write_formats(fmts, names, filename)
