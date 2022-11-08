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
# Vectoring CORDIC (Cartesian to Polar)
########################################################################################################################
class psi_fix_cordic_vect:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    ATAN_TABLE = np.arctan(2.0 **-np.arange(0, 32))/(2*np.pi)
    GAIN_COMP_FMT = psi_fix_fmt_t(0, 0, 17)

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  inFmt : psi_fix_fmt_t,
                        outFmt : psi_fix_fmt_t,
                        internalFmt : psi_fix_fmt_t,
                        angleFmt : psi_fix_fmt_t,
                        angleIntFmt : psi_fix_fmt_t,
                        iterations : int,
                        gainComp : bool,
                        round : psi_fix_rnd_t,
                        sat : psi_fix_sat_t):
        """
        Constructor of a vectoring CORDIC model.
        :param inFmt: Input fixed-point format
        :param outFmt: Output fixed-point format for the absolute value
        :param internalFmt: Internal fixed-point format for X/Y calculation
        :param angleFmt: Output fixed-point format for the angle
        :param angleIntFmt: Internal fixed-point format for the angle calculation
        :param iterations: Number of CORDIC iterations
        :param gainComp: True=CORDIC gain is compensated internally, False = CORDIC gain is not compensated
        :param round: Rounding mode at the output
        :param sat: Saturation mode at the output
        """
        #Checks
        if inFmt.s != 1:                raise ValueError("psi_fix_cordic_vect: InFmt_g must be signed")
        if outFmt.s != 0:               raise ValueError("psi_fix_cordic_vect: OutFmt_g must be unsigned")
        if internalFmt.s != 1:          raise ValueError("psi_fix_cordic_vect: InternalFmt_g must be signed")
        if internalFmt.i <= inFmt.i:    raise ValueError("psi_fix_cordic_vect: InternalFmt_g must have at least one more bit than InFmt_g")
        if angleFmt.s != 0:             raise ValueError("psi_fix_cordic_vect: AngleFmt_g must be unsigned")
        if angleIntFmt.s != 1:          raise ValueError("psi_fix_cordic_vect: AngleIntFmt_g must be signed")
        #Implementation
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.internalFmt = internalFmt
        self.iterations = iterations
        self.round = round
        self.sat = sat
        self.angleFmt = angleFmt
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

    def Process(self, inpI, inpQ) :
        """
        Run the bittrue model
        :param inpI: Real-part of the input
        :param inpQ: Imaginary-part of the input
        :return: Output as tuple (abs, angle)
        """
        #always map to quadrant one
        x = psi_fix_abs(psi_fix_from_real(inpI, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        y = psi_fix_abs(psi_fix_from_real(inpQ, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        z = 0
        for i in range(0, self.iterations):
            x_next = self._CordicStepX(x, y, i)
            y_next = self._CordicStepY(x, y, i)
            z_next = self._CordicStepZ(z, y, i)
            x = x_next
            y = y_next
            z = z_next
        zQ1 = psi_fix_resize(z, self.angleIntFmt, self.angleFmt, self.round, self.sat)
        zQ2 = psi_fix_sub(0.5, self.angleIntExtFmt, z, self.angleIntFmt, self.angleFmt, self.round, self.sat)
        zQ3 = psi_fix_add(0.5, self.angleIntExtFmt, z, self.angleIntFmt, self.angleFmt, self.round, self.sat)
        zQ4 = psi_fix_sub(1.0, self.angleIntExtFmt, z, self.angleIntFmt, self.angleFmt, self.round, self.sat)
        zOut = np.select([ np.logical_and(inpI >= 0, inpQ >= 0),
                        np.logical_and(inpI < 0, inpQ >= 0),
                        np.logical_and(inpI < 0, inpQ < 0),
                        np.logical_and(inpI >= 0, inpQ < 0)], [zQ1, zQ2, zQ3, zQ4])
        if self.gainComp:
            xOut = psi_fix_mult(x, self.internalFmt, self.gainCompCoef, self.GAIN_COMP_FMT, self.outFmt, self.round, self.sat)
        else:
            xOut = psi_fix_resize(x, self.internalFmt, self.outFmt, self.round, self.sat)
        return (xOut, zOut)

    ####################################################################################################################
    # Private Methods (do not call!)
    ####################################################################################################################
    def _CordicStepX(self, xLast, yLast, shift : int):
        yShifted = psi_fix_shift_right(yLast, self.internalFmt, shift, self.iterations-1, self.internalFmt)
        sub = psi_fix_sub(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        add = psi_fix_add(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        return np.where(yLast < 0, sub, add)

    def _CordicStepY(self, xLast, yLast, shift: int):
        xShifted = psi_fix_shift_right(xLast, self.internalFmt, shift, self.iterations - 1, self.internalFmt)
        add = psi_fix_add(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        sub = psi_fix_sub(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        out = np.where(yLast < 0, add, sub)
        return out

    def _CordicStepZ(self, zLast, yLast, iteration : int):
        add = psi_fix_add(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        sub = psi_fix_sub(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        return np.where(yLast < 0, sub, add)








