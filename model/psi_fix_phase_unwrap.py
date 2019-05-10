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
    def __init__(self, inFmt : PsiFixFmt, outFmt : PsiFixFmt, round : PsiFixRnd):
        """
        Constructor for a CORDIC based absolute value calculation
        :param inFmt: Input fixed point format for the phase in Pi
        :param outFmt: Output fixed point format for the phase in Pi.
        :param round: Rounding mode at the output
        """
        #Checks
        if outFmt.S != 1:
            raise Exception("psi_fix_phase_unwrap: output format must be signed!")
        if outFmt.I < 1:
            raise Exception("psi_fix_phase_unwrap: output format must at least have one integer bit")
        #Implementation
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.sumFmt = PsiFixFmt(1, max(outFmt.I+1, 1), inFmt.F)
        self.diffFmt = PsiFixFmt(1, 0, inFmt.F) #only covers +/- 180°
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
        diff = PsiFixSub(inPhase, self.inFmt,
                         inShifted, self.inFmt,
                         self.diffFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap) #Must wrap (to +/- 180°)
        outVal = np.empty_like(diff, inPhase.dtype)
        outWrap = np.empty_like(diff, dtype=bool)
        val = 0
        for idx, (d, i) in enumerate(zip(diff, inPhase)):
            val = PsiFixAdd(val, self.sumFmt, d, self.diffFmt, self.sumFmt)
            wrap = False
            if not PsiFixInRange(val, self.sumFmt, self.outFmt, self.round):
                val = PsiFixResize(i, self.inFmt, self.sumFmt)
                wrap = True
            outVal[idx] = PsiFixResize(val, self.sumFmt, self.outFmt, self.round);
            outWrap[idx] = wrap
        return (outVal, outWrap)








