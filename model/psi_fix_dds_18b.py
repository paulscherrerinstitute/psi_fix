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
from typing import Tuple

########################################################################################################################
# DDS Model
########################################################################################################################
class psi_fix_dds_18b:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    OUT_FMT = psi_fix_lin_approx.CONFIGS.Sin18Bit.outFmt

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, phaseFmt : psi_fix_fmt_t):
        """
        Constructor for the DDS model object
        :param phaseFmt: Format of the phase accumulator
        """
        #check out Fmt
        if phaseFmt.s == 1:
            raise ValueError("psi_fix_dds_18b currently only supports unsigned phase formats, got {}".format(phaseFmt))
        self.phaseFmt = phaseFmt
        self.sineApprox = psi_fix_lin_approx(psi_fix_lin_approx.CONFIGS.Sin18Bit)

    ####################################################################################################################
    # Public Methods and Properties
    ####################################################################################################################
    def Synthesize(self, phaseStep : float, numOfSamples : int , phaseOffset = 0.0) -> Tuple[np.ndarray, np.ndarray]:
        """
        Synthesize signal
        :param phaseStep: Phase step betwee two samples
        :param numOfSamples: Number of samples to synthesize
        :param phaseOffset: Phase offset to start at
        :return: Synthesized signals as tuple (sin, cos)
        """
        return self.Process(np.repeat(phaseStep, numOfSamples), np.repeat(phaseOffset, numOfSamples))

    def Process(self, phaseStep : np.ndarray, phaseOffset : np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Synthesize a signal from phase-step/phase-offset arrays

        :param phaseStep: Array with phase step value for each sample
        :param phaseOffset: Array with phase offset value for each sample
        :return: Synthesized signals as tuple (sin, cos)
        """
        if phaseStep.size != phaseOffset.size:
            raise ValueError("psi_fix_dds_18b: Process() phaserStep and phaseOffset arrays must be of same size")
        #Calculate inputs
        phaseStepFix = psi_fix_from_real(phaseStep, self.phaseFmt)
        phaseOffsetFix = psi_fix_from_real(phaseOffset, self.phaseFmt)
        numOfSamples = phaseStepFix.size
        #Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(numOfSamples,dtype=np.int64)*psi_fix_get_bits_as_int(phaseStepFix, self.phaseFmt)
        phaseSteps[0] = 0 #start at zero
        accumulator = np.cumsum(phaseSteps,dtype=np.int64) + psi_fix_get_bits_as_int(phaseOffsetFix, self.phaseFmt)
        accuWrapped = accumulator % 2**psi_fix_size(self.phaseFmt)
        accuPhase = psi_fix_from_bits_as_int(accuWrapped, self.phaseFmt)
        #Generate sine wave
        phaseQuantSin = psi_fix_resize(accuPhase, self.phaseFmt, self.sineApprox.cfg.inFmt)
        phaseQuantCos = psi_fix_resize(accuPhase+0.25, self.phaseFmt, self.sineApprox.cfg.inFmt)
        outSin = self.sineApprox.Approximate(phaseQuantSin)
        outCos = self.sineApprox.Approximate(phaseQuantCos)
        return (outSin, outCos)
