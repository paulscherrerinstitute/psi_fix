########################################################################################################################
#  Copyright (c) 2026 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Radoslaw Rybaniec
########################################################################################################################
import sys
sys.path.append("../../../model")
import numpy as np
from psi_fix_pkg import *
import os

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
PLOT_ON = False

try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
# Formats (must match the testbench)
#############################################################
inFmt = psi_fix_fmt_t(1, 0, 15)
outFmt = psi_fix_fmt_t(1, 0, 14)
intFmt = psi_fix_fmt_t(1, 0, 24)
coefFmt = psi_fix_fmt_t(1, 0, 17)
fSample = 100e6

#############################################################
# Bit-true model of psi_fix_lowpass_iir_order1_conf
# Takes the configuration register pipeline into account:
# - cfg_alpha_i is registered into alpha_r
# - beta_r is calculated from alpha_r (1 clock delay)
# - beta_rr registers beta_r (2 clock delays from cfg_alpha_i)
# - mulIn uses beta_rr; feedback multiply uses alpha_r
# When streamed at MaxStrbRate (>= 3 clk/spl), beta_rr for sample k
# receives beta of alpha[k-1] (or reset default 1.0 for sample 0),
# while alpha_r for feedback of sample k has settled to alpha[k].
#############################################################
class psi_fix_lowpass_iir_order1_conf:
    def __init__(self, inFmt, outFmt, intFmt, coefFmt,
                 rnd=psi_fix_rnd_t.round, sat=psi_fix_sat_t.sat):
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.intFmt = intFmt
        self.coefFmt = coefFmt
        self.rnd = rnd
        self.sat = sat
        self.oneFmt = psi_fix_fmt_t(1, coefFmt.i + 1, coefFmt.f)
        self.one = psi_fix_from_real(1.0, self.oneFmt)

    def Filter(self, data, alpha):
        dataFix = psi_fix_from_real(data, self.inFmt)
        alphaFix = psi_fix_from_real(alpha, self.coefFmt)

        # Initial beta before first sample (alpha=0.0 in reset -> beta=1.0 - 2^-F)
        beta_0 = psi_fix_sub(self.one, self.oneFmt, psi_fix_from_real(0.0, self.coefFmt),
                             self.coefFmt, self.coefFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)
        beta_from_alpha = psi_fix_sub(self.one, self.oneFmt, alphaFix, self.coefFmt,
                                      self.coefFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.sat)

        # Due to beta_r -> beta_rr register delay, sample k uses beta from alpha[k-1]
        beta_applied = np.empty_like(beta_from_alpha)
        beta_applied[0] = beta_0
        beta_applied[1:] = beta_from_alpha[:-1]

        out = np.empty_like(dataFix)
        fb = 0
        for i in range(len(dataFix)):
            d = dataFix[i]
            b = beta_applied[i]
            a = alphaFix[i]
            mulIn = psi_fix_mult(d, self.inFmt, b, self.coefFmt, self.intFmt, self.rnd, self.sat)
            add = psi_fix_add(mulIn, self.intFmt, fb, self.intFmt, self.intFmt, sat=self.sat)
            fb = psi_fix_mult(add, self.intFmt, a, self.coefFmt, self.intFmt, self.rnd, self.sat)
            out[i] = psi_fix_resize(add, self.intFmt, self.outFmt, self.rnd, self.sat)
        return out

#############################################################
# Stimulus: continuous stream with online alpha changes (no resets)
#############################################################
def alpha_from_fcut(fCutoff):
    if fCutoff == 0:
        return 0.0
    tau = 1.0 / (2.0 * np.pi * fCutoff)
    return np.exp(-(1.0 / fSample) / tau)

segments = [
    (0.5,   alpha_from_fcut(1.0e6)),   # high cutoff
    (-0.25, alpha_from_fcut(30.0e3)),  # low cutoff (online change)
    (0.125, 0.0),                      # alpha = 0 (passthrough, online change)
]
NSPL = 700

sig = np.concatenate([val * np.ones(NSPL) for val, _ in segments])
alp = np.concatenate([alpha * np.ones(NSPL) for _, alpha in segments])

iir = psi_fix_lowpass_iir_order1_conf(inFmt, outFmt, intFmt, coefFmt)
res = iir.Filter(sig, alp)

#############################################################
# Plot (if required)
#############################################################
if PLOT_ON:
    from matplotlib import pyplot as plt
    plt.plot(res, 'r')
    plt.show()

#############################################################
# Write Files for Co-simulation
#############################################################
inData = psi_fix_get_bits_as_int(psi_fix_from_real(sig, inFmt), inFmt)
inAlpha = psi_fix_get_bits_as_int(psi_fix_from_real(alp, coefFmt), coefFmt)
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack((inData, inAlpha)), fmt="%i", header="input")
np.savetxt(STIM_DIR + "/output.txt",
           psi_fix_get_bits_as_int(res, outFmt), fmt="%i", header="output")
