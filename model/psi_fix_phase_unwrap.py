########################################################################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from typing import Tuple

########################################################################################################################
# Phase unwrapping engine
########################################################################################################################
#
# Because the unwrapped phase can accumulate, there is no theoretically sufficient output format. If the output overflows,
# The unwrapping engine recovers by just outputting the sample as is (i.e. wrap to the input phase) and continues unwrapping
# from there. If this happens, this is signalled at the output. See documentation for details.
class psi_fix_phase_unwrap:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, inFmt : psi_fix_fmt_t, outFmt : psi_fix_fmt_t, round : psi_fix_rnd_t):
        """
        Constructor for a CORDIC based absolute value calculation
        :param inFmt: Input fixed point format for the phase in Pi
        :param outFmt: Output fixed point format for the phase in Pi.
        :param round: Rounding mode at the output
        """
        #Checks
        if outFmt.s != 1:
            raise Exception("psi_fix_phase_unwrap: output format must be signed!")
        if outFmt.i < 1:
            raise Exception("psi_fix_phase_unwrap: output format must at least have one integer bit")
        #Implementation
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.sumFmt = psi_fix_fmt_t(1, max(outFmt.i+1, 1), inFmt.f)
        self.diffFmt = psi_fix_fmt_t(1, 0, inFmt.f) #only covers +/- 180°
        self.round = round

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Process(self, inPhase : np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Process data using the model object
        :param inPhase: input phase in Pi (1.0 = 180°)
        :return: (r, w)
                 r: Result unwrapped phase
                 w = boolean array containing True if output overflowed
        """
        inShifted = np.roll(inPhase, 1)
        inShifted[0] = 0
        diff = psi_fix_sub(inPhase, self.inFmt,
                         inShifted, self.inFmt,
                         self.diffFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap) #Must wrap (to +/- 180°)
        outVal = np.empty_like(diff, inPhase.dtype)
        outWrap = np.empty_like(diff, dtype=bool)
        val = 0
        for idx, (d, i) in enumerate(zip(diff, inPhase)):
            val = psi_fix_add(val, self.sumFmt, d, self.diffFmt, self.sumFmt)
            wrap = False
            if not psi_fix_in_range(val, self.sumFmt, self.outFmt, self.round):
                val = psi_fix_resize(i, self.inFmt, self.sumFmt)
                wrap = True
            outVal[idx] = psi_fix_resize(val, self.sumFmt, self.outFmt, self.round);
            outWrap[idx] = wrap
        return (outVal, outWrap)








