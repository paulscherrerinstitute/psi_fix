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

########################################################################################################################
# White Noise Generator Model
########################################################################################################################
class psi_fix_white_noise:


    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, outFmt : psi_fix_fmt_t, seed : int = 0xA38E3C1D):
        if psi_fix_size(outFmt) > 32:
            raise Exception("psi_fix_white_noise: Output width cannot be larger than 32 bits")
        self.outFmt = outFmt
        self.seed = seed
        self.outBits = psi_fix_size(self.outFmt)
        self.outMask = (1 << self.outBits)-1

    ####################################################################################################################
    # Public functions
    ####################################################################################################################
    def Generate(self, samples : int) -> np.ndarray:

        #Calculate random for each bit and concatenate to number
        outVec = np.zeros(samples, dtype=np.int64)
        for bitNr in range(self.outBits):
            bitN = self._GenerateBit((self.seed + (1<<bitNr)) & 0xFFFFFFFF, samples)
            outVec += bitN << bitNr

        #Signed Conversion
        if self.outFmt.s == 1:
            outVec = np.where(outVec >= 2**(self.outBits-1), outVec - 2**self.outBits, outVec)

        #Output
        return psi_fix_from_bits_as_int(outVec, self.outFmt)


    ####################################################################################################################
    # Private functions
    ####################################################################################################################
    def _GenerateBit(self, seed : int, samples : int):
        lfsr = seed
        bitVec = np.empty(samples, dtype=np.int64)
        fbTaps = [31,20,26,25]
        for i in range(samples):
            bitVec[i] = lfsr & 0x01
            fbVals = np.array(lfsr & (2**np.array(fbTaps)), dtype=bool)
            fbBit = np.sum(fbVals) % 2
            lfsr = ((lfsr << 1) + fbBit) & 0xFFFFFFFF
        return bitVec






