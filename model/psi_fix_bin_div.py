########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np

########################################################################################################################
# Public Functions
########################################################################################################################
def psi_fix_bin_div(num, numFmt : psi_fix_fmt_t,
                    denom, denomFmt : psi_fix_fmt_t,
                    outFmt : psi_fix_fmt_t, rnd : psi_fix_rnd_t, sat : psi_fix_sat_t):
    """
    Model of the binary division.
    :param num: Numerator value
    :param numFmt: Numerator format
    :param denom: Denominator value
    :param denomFmt: Denominator format
    :param outFmt: Output format
    :param rnd: Rounding mode
    :param sat: Saturation mode
    :return: Result of the binary division
    """

    #Formats
    firstShift = outFmt.i
    numAbsFmt = psi_fix_fmt_t(0, numFmt.i + numFmt.s, numFmt.f)
    denomAbsFmt = psi_fix_fmt_t(0, denomFmt.i + denomFmt.s, denomFmt.f)
    resultIntFmt = psi_fix_fmt_t(1, outFmt.i+1, outFmt.f+1)
    denomCompFmt = psi_fix_fmt_t(0, denomAbsFmt.i+firstShift, denomAbsFmt.f-firstShift)
    numCompFmt = psi_fix_fmt_t(0, max(denomCompFmt.i, numAbsFmt.i), max(denomCompFmt.f, numAbsFmt.f))


    #Sign Handling
    numSign = np.where(num < 0, 1, 0)
    denomSign = np.where(denom < 0, 1, 0)
    numAbs = psi_fix_abs(num, numFmt, numAbsFmt)
    denomAbs = psi_fix_abs(denom, denomFmt, denomAbsFmt)

    #Initialization
    denomComp = psi_fix_shift_left(denomAbs, denomAbsFmt, firstShift, firstShift, denomCompFmt)
    numComp = psi_fix_resize(numAbs, numAbsFmt, numCompFmt)
    iterations = outFmt.i+outFmt.f+2
    resultInt = np.zeros(numComp.size)

    #Execution
    for i in range(iterations):
        resultInt *= 2
        numInDenomFmt = psi_fix_resize(numComp, numCompFmt, denomCompFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        resultInt = np.where(denomComp <= numInDenomFmt, resultInt + 1, resultInt)
        numComp = np.where(denomComp <= numInDenomFmt, psi_fix_sub(numComp, numCompFmt, denomComp, denomCompFmt, numCompFmt), numComp)
        numComp = psi_fix_shift_left(numComp, numCompFmt, 1, 1 ,numCompFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)

    #Output handling
    resSigned = psi_fix_from_bits_as_int(resultInt, resultIntFmt)
    res = np.where(numSign != denomSign, -resSigned, resSigned)
    return psi_fix_resize(res, resultIntFmt, outFmt, rnd, sat)







