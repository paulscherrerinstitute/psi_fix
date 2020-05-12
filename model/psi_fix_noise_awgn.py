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
from psi_fix_white_noise import psi_fix_white_noise
from psi_fix_lin_approx import psi_fix_lin_approx

########################################################################################################################
# White Noise Generator Model
########################################################################################################################
class psi_fix_noise_awgn:


    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, outFmt : PsiFixFmt, seed : int = 0xA38E3C1D):
        if (outFmt.S == 0) or (outFmt.I > 0):
            raise Exception("psi_fix_noise_awgn: Output format must be [1,0,x]")
        if (outFmt.F > 19):
            raise Exception("psi_fix_noise_awgn: Maximum number of fractional bits is 19")
        self.intFmt = PsiFixFmt(1,0,19)
        self.whiteNoiseGen = psi_fix_white_noise(self.intFmt, seed)
        self.gaussifyApprox = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Gaussify20Bit)
        self.outFmt = outFmt

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Generate(self, samples : int) -> np.ndarray:

        #Calculate random for each bit and concatenate to number
        noiseUniform = self.whiteNoiseGen.Generate(samples)

        #Convert to gaussian distribution
        noiseNormal = self.gaussifyApprox.Approximate(noiseUniform)

        return PsiFixResize(noiseNormal, self.intFmt, self.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)








