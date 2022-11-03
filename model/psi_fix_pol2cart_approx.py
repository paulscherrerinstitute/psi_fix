########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
from psi_fix_lin_approx import psi_fix_lin_approx
import numpy as np

########################################################################################################################
# Bittrue model of the Polar to Cartesian Conversion
########################################################################################################################
class psi_fix_pol2cart_approx:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    SIN_OUT_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.outFmt
    SIN_IN_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.inFmt

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, inAbsFmt : psi_fix_fmt_t,
                 inAngleFmt : psi_fix_fmt_t,
                 outFmt : psi_fix_fmt_t,
                 rnd : psi_fix_rnd_t = psi_fix_rnd_t.round,
                 sat : psi_fix_sat_t = psi_fix_sat_t.sat):
        """
        Constructor of the polar to cartesian model
        :param inAbsFmt: Input fixed-point format for absolute value
        :param inAngleFmt: Input fixed-point format for angle
        :param outFmt: Output fixed-point format
        :param rnd: Rounding mode at the output
        :param sat: Saturation mode at the output
        """
        #checks
        if inAngleFmt.s == 1:    raise ValueError("psi_fix_pol2cart_approx: InAngleFmt must be unsigned")
        if inAbsFmt.s == 1:      raise ValueError("psi_fix_pol2cart_approx: InAbsFmt must be unsigned")
        if inAngleFmt.i > 0 :    raise ValueError("psi_fix_pol2cart_approx: InAngleFmt_g must be (1,0,x)")
        #Implementation
        self.inAbsFmt = inAbsFmt
        self.inAngleFmt = inAngleFmt
        self.outFmt = outFmt
        self.rnd = rnd
        self.sat = sat
        self.sineApprox = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sin18Bit)

    ####################################################################################################################
    # Public Methods
    ####################################################################################################################
    def Process(self, inpAbs, inpAngle) :
        """
        Convert data from polar to cartesian representation
        :param inpAbs: Input absolute value(s)
        :param inpAngle: Input angle value(s)
        :return: Cartesian representation as tuple (I, Q)
        """
        phaseSin = psi_fix_resize(inpAngle, self.inAngleFmt, self.SIN_IN_FMT, self.rnd, psi_fix_sat_t.wrap)
        phaseCos = psi_fix_add(inpAngle, self.inAngleFmt, 0.25, self.SIN_IN_FMT, self.SIN_IN_FMT, self.rnd, psi_fix_sat_t.wrap)
        sinData = self.sineApprox.Approximate(phaseSin)
        cosData = self.sineApprox.Approximate(phaseCos)
        outI = psi_fix_mult(inpAbs, self.inAbsFmt, cosData, self.SIN_OUT_FMT, self.outFmt, self.rnd, self.sat)
        outQ = psi_fix_mult(inpAbs, self.inAbsFmt, sinData, self.SIN_OUT_FMT, self.outFmt, self.rnd, self.sat)
        return (outI, outQ)