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
    GAIN_COMP_FMT = PsiFixFmt(0, 0, 17)
    QUAD_FMT = PsiFixFmt(0, 0, 2)

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  inAbsFmt : PsiFixFmt,
                        inAngleFmt : PsiFixFmt,
                        outFmt : PsiFixFmt,
                        internalFmt : PsiFixFmt,
                        angleIntFmt : PsiFixFmt,
                        iterations : int,
                        gainComp : bool,
                        round : PsiFixRnd,
                        sat : PsiFixSat):
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
        if inAngleFmt.S == 1:           raise ValueError("psi_fix_cordic_rot: InAngleFmt_g must be unsigned")
        if angleIntFmt.S != 1:          raise ValueError("psi_fix_cordic_rot: AngleIntFmt_g must be signed")
        if angleIntFmt.I != -2:         raise ValueError("psi_fix_cordic_rot: AngleIntFmt_g must be (1,-2,x)")
        if inAbsFmt.S == 1:             raise ValueError("psi_fix_cordic_rot: InAbsFmt_g must be unsigned")
        if internalFmt.S != 1:          raise ValueError("psi_fix_cordic_rot: InternalFmt_g must be signed")
        if internalFmt.I <= inAbsFmt.I: raise ValueError("psi_fix_cordic_rot: InternalFmt_g must have at least one more bit than InAbsFmt_g")
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
        self.gainCompCoef = PsiFixFromReal(1/self.CordicGain, self.GAIN_COMP_FMT)
        self.angleIntExtFmt = PsiFixFmt(angleIntFmt.S, max(angleIntFmt.I, 1), angleIntFmt.F)
        #Angle table for up to 32 iterations
        self.angleTable = PsiFixFromReal(self.ATAN_TABLE, angleIntFmt)

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
        x = PsiFixResize(inpAbs, self.inAbsFmt, self.internalFmt, self.round, self.sat)
        y = 0
        z = PsiFixResize(inpAngle, self.inAngleFmt, self.angleIntFmt, self.round, PsiFixSat.Wrap)
        quad = PsiFixResize(inpAngle, self.inAngleFmt, self.QUAD_FMT, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        #Cordic Algorithm
        for i in range(0, self.iterations):
            x_next = self._CordicStepX(x, y, z, i)
            y_next = self._CordicStepY(x, y, z, i)
            z_next = self._CordicStepZ(z, i)
            x = x_next
            y = y_next
            z = z_next

        #Quadrant correction
        yInv = PsiFixNeg(y, self.internalFmt, self.internalFmt, self.round, self.sat)
        yCorr = np.select([quad == 0, quad==0.25, quad==0.5, quad==0.75], [y, yInv, yInv, y])
        xInv = PsiFixNeg(x, self.internalFmt, self.internalFmt, self.round, self.sat)
        xCorr = np.select([quad == 0, quad == 0.25, quad == 0.5, quad == 0.75], [x, xInv, xInv, x])

        #Gain correction
        if self.gainComp:
            xOut = PsiFixMult(xCorr, self.internalFmt, self.gainCompCoef, self.GAIN_COMP_FMT, self.outFmt, self.round, self.sat)
            yOut = PsiFixMult(yCorr, self.internalFmt, self.gainCompCoef, self.GAIN_COMP_FMT, self.outFmt, self.round, self.sat)
        else:
            xOut = PsiFixResize(xCorr, self.internalFmt, self.outFmt, self.round, self.sat)
            yOut = PsiFixResize(yCorr, self.internalFmt, self.outFmt, self.round, self.sat)

        return xOut, yOut

    ####################################################################################################################
    # Private Methods (do not call!)
    ####################################################################################################################
    def _CordicStepX(self, xLast, yLast, zLast, shift : int):
        yShifted = PsiFixShiftRight(yLast, self.internalFmt, shift, self.iterations-1, self.internalFmt)
        sub = PsiFixSub(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        add = PsiFixAdd(xLast, self.internalFmt, yShifted, self.internalFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        return np.where(zLast > 0, sub, add)

    def _CordicStepY(self, xLast, yLast, zLast, shift: int):
        xShifted = PsiFixShiftRight(xLast, self.internalFmt, shift, self.iterations - 1, self.internalFmt)
        add = PsiFixAdd(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        sub = PsiFixSub(yLast, self.internalFmt, xShifted, self.internalFmt, self.internalFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        out = np.where(zLast > 0, add, sub)
        return out

    def _CordicStepZ(self, zLast, iteration : int):
        add = PsiFixAdd(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        sub = PsiFixSub(zLast, self.angleIntFmt, self.angleTable[iteration], self.angleIntFmt, self.angleIntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        return np.where(zLast > 0, sub, add)









