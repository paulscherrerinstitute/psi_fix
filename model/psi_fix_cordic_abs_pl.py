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
# Cordic based absolute value calculation model
########################################################################################################################
class psi_fix_cordic_abs_pl:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, inFmt : psi_fix_fmt_t, outFmt : psi_fix_fmt_t, internalFmt : psi_fix_fmt_t, iterations : int, round : psi_fix_rnd_t, sat : psi_fix_sat_t):
        """
        Constructor for a CORDIC based absolute value calculation
        :param inFmt: Input fixed point format
        :param outFmt: Output fixed point format
        :param internalFmt: Internal format (see documentation)
        :param iterations: Number of CORDIC iterations
        :param round: Rounding mode at the output
        :param sat: Saturation mode at the output
        """
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.internalFmt = internalFmt
        self.iterations = iterations
        self.round = round
        self.sat = sat

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Process(self, inpI, inpQ):
        """
        Process data using the model object
        :param inpI: Real-part of the input
        :param inpQ: Imaginary-part of the input
        :return: Result (absolute value)
        """
        x = psi_fix_abs(psi_fix_from_real(inpI, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        y = psi_fix_resize(psi_fix_from_real(inpQ, self.inFmt), self.inFmt, self.internalFmt, self.round, self.sat)
        for i in range(0, self.iterations):
            sftFmt = psi_fix_fmt_t(1, self.internalFmt.i-i, self.internalFmt.f+i)
            x_sft = psi_fix_from_real(x / 2 ** i, sftFmt)
            y_sft = psi_fix_from_real(y / 2 ** i, sftFmt)
            x_sub = psi_fix_sub(x, self.internalFmt, y_sft, sftFmt, self.internalFmt, self.round, self.sat)
            x_add = psi_fix_add(x, self.internalFmt, y_sft, sftFmt, self.internalFmt, self.round, self.sat)
            x_next = np.where(y < 0, x_sub, x_add)
            y_sub = psi_fix_sub(y, self.internalFmt, x_sft, sftFmt, self.internalFmt, self.round, self.sat)
            y_add = psi_fix_add(y, self.internalFmt, x_sft, sftFmt, self.internalFmt, self.round, self.sat)
            y_next = np.where(y < 0, y_add, y_sub)
            x = x_next
            y = y_next
        return psi_fix_resize(x, self.internalFmt, self.outFmt, self.round, self.sat)






