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
    def __init__(self, outFmt : psi_fix_fmt_t, seed : int = 0xA38E3C1D):
        if (outFmt.s == 0) or (outFmt.i > 0):
            raise Exception("psi_fix_noise_awgn: Output format must be [1,0,x]")
        if (outFmt.f > 19):
            raise Exception("psi_fix_noise_awgn: Maximum number of fractional bits is 19")
        self.intFmt = psi_fix_fmt_t(1,0,19)
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

        return psi_fix_resize(noiseNormal, self.intFmt, self.outFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)








