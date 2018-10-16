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
def psi_fix_bin_div(num, numFmt : PsiFixFmt,
                    denom, denomFmt : PsiFixFmt,
                    outFmt : PsiFixFmt, rnd : PsiFixRnd, sat : PsiFixSat):
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
    firstShift = outFmt.I
    numAbsFmt = PsiFixFmt(0, numFmt.I + numFmt.S, numFmt.F)
    denomAbsFmt = PsiFixFmt(0, denomFmt.I + denomFmt.S, denomFmt.F)
    resultIntFmt = PsiFixFmt(1, outFmt.I+1, outFmt.F+1)
    denomCompFmt = PsiFixFmt(0, denomAbsFmt.I+firstShift, denomAbsFmt.F-firstShift)
    numCompFmt = PsiFixFmt(0, max(denomCompFmt.I, numAbsFmt.I), max(denomCompFmt.F, numAbsFmt.F))


    #Sign Handling
    numSign = np.where(num < 0, 1, 0)
    denomSign = np.where(denom < 0, 1, 0)
    numAbs = PsiFixAbs(num, numFmt, numAbsFmt)
    denomAbs = PsiFixAbs(denom, denomFmt, denomAbsFmt)

    #Initialization
    denomComp = PsiFixShiftLeft(denomAbs, denomAbsFmt, firstShift, firstShift, denomCompFmt)
    numComp = PsiFixResize(numAbs, numAbsFmt, numCompFmt)
    iterations = outFmt.I+outFmt.F+2
    resultInt = np.zeros(numComp.size)

    #Execution
    for i in range(iterations):
        resultInt *= 2
        numInDenomFmt = PsiFixResize(numComp, numCompFmt, denomCompFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        resultInt = np.where(denomComp <= numInDenomFmt, resultInt + 1, resultInt)
        numComp = np.where(denomComp <= numInDenomFmt, PsiFixSub(numComp, numCompFmt, denomComp, denomCompFmt, numCompFmt), numComp)
        numComp = PsiFixShiftLeft(numComp, numCompFmt, 1, 1 ,numCompFmt, PsiFixRnd.Trunc, PsiFixSat.Sat)

    #Output handling
    resSigned = PsiFixFromBitsAsInt(resultInt, resultIntFmt)
    res = np.where(numSign != denomSign, -resSigned, resSigned)
    return PsiFixResize(res, resultIntFmt, outFmt, rnd, sat)







