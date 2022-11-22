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
# Rotating CORDIC (Polar to Cartesian)
########################################################################################################################
class psi_fix_cordic_rot:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    ATAN_TABLE = np.arctan(2.0 **-np.arange(0, 32))/(2*np.pi)
    GAIN_COMP_FMT = psi_fix_fmt_t(0, 0, 17)
    QUAD_FMT = psi_fix_fmt_t(0, 0, 2)

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  inAbsFmt : psi_fix_fmt_t,
                        inAngleFmt : psi_fix_fmt_t,
                        outFmt : psi_fix_fmt_t,
                        internalFmt : psi_fix_fmt_t,
                        angleIntFmt : psi_fix_fmt_t,
                        iterations : int,
                        gainComp : bool,
                        round : psi_fix_rnd_t,
                        sat : psi_fix_sat_t):
        """
        Constructor of a rotating CORDIC model.

        Various formats must be passed. Especially for the number of iterations and the internal formats, it is
        sometimes difficult to find an optimal solution. The suggested approach is to run this bittrue model and
        try different settings to find a parameter-set that is optimal for a given application.

        :param inAbsFmt: Input fixed-point format for the absolute value
        :param inAngleFmt: Input fixed-point format for the angle value
        :param outFmt: Output fixed-point format
        :param internalFmt: Internal format for X/Y values
        :param angleIntFmt: Internal format for the angle calculation
        :param iterations: Number of CORDIC iterations
        :param gainComp: True=CORDIC gain is compensated internally, False = CORDIC gain is not compensated
        :param round: Rounding mode at the output
        :param sat: Saturation mode at the output
        """
        #Checks
        if inAngleFmt.s == 1:           raise ValueError("psi_fix_cordic_rot: InAngleFmt_g must be unsigned")
        if angleIntFmt.s != 1:          raise ValueError("psi_fix_cordic_rot: AngleIntFmt_g must be signed")
        if angleIntFmt.i != -2:         raise ValueError("psi_fix_cordic_rot: AngleIntFmt_g must be (1,-2,x)")
        if inAbsFmt.s == 1:             raise ValueError("psi_fix_cordic_rot: InAbsFmt_g must be unsigned")
        if internalFmt.s != 1:          raise ValueError("psi_fix_cordic_rot: InternalFmt_g must be signed")
        if internalFmt.i <= inAbsFmt.i: raise ValueError("psi_fix_cordic_rot: InternalFmt_g must have at least one more bit than InAbsFmt_g")
        #Implementation
        self.inAbsFmt = inAbsFmt
        self.inAngleFmt = inAngleFmt
        self.outFmt = outFmt
        self.internalFmt = internalFmt
        self.iterations = iterations
        self.round = round
        self.sat = sat
        self.angleIntFmt = angleIntFmt
        self.gainComp = gainComp
        self.gainCompCoef = psi_fix_from_real(1/self.CordicGain, self.GAIN_COMP_FMT)
        self.angleIntExtFmt = psi_fix_fmt_t(angleIntFmt.s, max(angleIntFmt.i, 1), angleIntFmt.f)
        #Angle table for up to 32 iterations
        self.angleTable = psi_fix_from_real(self.ATAN_TABLE, angleIntFmt)

    ####################################################################################################################
    # Public Methods and Properties
    ####################################################################################################################

    @property
    def CordicGain(self):
        """
        Get the CORDIC gain of the model (can be used if external compensation is required)
        :return: CORDIC gain
        """
        g = 1
        for i in range(self.iterations):
            g *= np.sqrt(1+2**(-2*i))
        return g

    def Process(self, inpAbs, inpAngle) :
        """
        Run the bittre model
        :param inpAbs: Absolute value input
        :param inpAngle: Angle input
        :return: CORDIC output as Tuple (I, Q)
        """

        #Initialization - always map to quadrant one
        x = psi_fix_resize(inpAbs, self.inAbsFmt, self.internalFmt, self.round, self.sat)
        y = 0
        z = psi_fix_resize(inpAngle, self.inAngleFmt, self.angleIntFmt, self.round, psi_fix_sat_t.wrap)
        quad = psi_fix_resize(inpAngle, self.inAngleFmt, self.QUAD_FMT, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)

        #Cordic Algorithm
        for i in range(0, self.iterations):
            x_next = self._CordicStepX(x, y, z, i)
            y_next = self._CordicStepY(x, y, z, i)
            z_next = self._CordicStepZ(z, i)
            x = x_next
            y = y_next
            z = z_next

        #Quadrant correction
        yInv = psi_fix_neg(y, self.internalFmt, self.internalFmt, self.round, self.sat)
        yCorr = np.select([quad == 0, quad==0.25, quad==0.5, quad==0.75], [y, yInv, yInv, y])
        xInv = psi_fix_neg(x, self.internalFmt, self.internalFmt, self.round, self.sat)
        xCorr = np.select([quad == 0, quad == 0.25, quad == 0.5, quad == 0.75], [x, xInv, xInv, x])

        #Gain correction
        if self.gainComp:
            xOut = psi_fix_mult(xCorr, self.internalFmt, self.gainCompCoef, self.GAIN_COMP_FMT, self.outFmt, self.round, self.sat)
            yOut = psi_fix_mult(yCorr, self.internalFmt, self.gainCompCoef, self.GAIN_COMP_FMT, self.outFmt, self.round, self.sat)
        else:
            xOut = psi_fix_resize(xCorr, self.internalFmt, self.outFmt, self.round, self.sat)
            yOut = psi_fix_resize(yCorr, self.internalFmt, self.outFmt, self.round, self.sat)

        return xOut, yOut

    ####################################################################################################################
    # Private Methods (do not call!)
    ####################################################################################################################
    def _CordicStepX(self, xLast, yLast, zLast, shift : int):
        yShifted = psi_fix_shift_right(yLast, self.internalFmt, shift, self.iterations-1, self.internalFmt)
        sub = psi_fix_sub(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        add = psi_fix_add(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        return np.where(zLast > 0, sub, add)

    def _CordicStepY(self, xLast, yLast, zLast, shift: int):
        xShifted = psi_fix_shift_right(xLast, self.internalFmt, shift, self.iterations - 1, self.internalFmt)
        add = psi_fix_add(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        sub = psi_fix_sub(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        out = np.where(zLast > 0, add, sub)
        return out

    def _CordicStepZ(self, zLast, iteration : int):
        add = psi_fix_add(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        sub = psi_fix_sub(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        return np.where(zLast > 0, sub, add)









