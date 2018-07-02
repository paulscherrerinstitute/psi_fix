import sys
sys.path.append("../../../model")
import numpy as np
import scipy.signal as sps
from psi_fix_pkg import *
from psi_fix_cic_dec import psi_fix_cic_dec
from typing import NamedTuple
import matplotlib.pyplot as plt
import os

PLOT_ON = False
STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 10000
FREQ_SAMPLE = 100e6
TEND = (SAMPLES-1)/FREQ_SAMPLE
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
# Functions
#############################################################

def WriteFile(signal, filePath, fracBits):
    # Scale to fixed point
    signal = (signal * pow(2, fracBits)).round()

    # Write to File
    with open(filePath, "w+") as f:
        f.writelines(["{}\n".format(int(val)) for val in signal])

#############################################################
# Data Generation
#############################################################
inFmt = PsiFixFmt(1, 0, 16)
outFmt = PsiFixFmt(1, 0, 17)

np.random.seed(0)
t = np.linspace(0,TEND,SAMPLES)

CfgInfo = NamedTuple("CfgInfo", [("order", int), ("ratio", int), ("diffDel", int), ("gainCorr", bool)])
configs = []
configs.append(CfgInfo(order=3, ratio=10, diffDel=1, gainCorr=True))
configs.append(CfgInfo(order=4, ratio=9, diffDel=2, gainCorr=True))
configs.append(CfgInfo(order=4, ratio=6, diffDel=2, gainCorr=False))

inSig = []
outSig = []
for cfg in configs:
    inSig0 = sps.chirp(t, 0, TEND, FREQ_SAMPLE / cfg.ratio)
    inSig0 = PsiFixFromReal(inSig0, inFmt, errSat=False)
    inSig1 = np.zeros_like(inSig0)
    inSig1[10] = PsiFixFromReal(0.5, inFmt, errSat=False)
    inSig2 = np.ones_like(inSig0)
    inSig2 = PsiFixFromReal(inSig2, inFmt, errSat=False)
    model = psi_fix_cic_dec(cfg.order, cfg.ratio, cfg.diffDel, inFmt, outFmt, cfg.gainCorr)
    outp0 = model.Process(inSig0)
    outp1 = model.Process(inSig1)
    outp2 = model.Process(inSig2)
    if PLOT_ON:
        plt.plot(20*np.log10(abs(outp0)))
        plt.show()
    outSig.append((outp0, outp1, outp2))
    inSig.append((inSig0, inSig1, inSig2))


#############################################################
# Write files
#############################################################
for nr, sig in enumerate(inSig):
    cfg = configs[nr]
    with open(STIM_DIR + "/input_o{}_r{}_dd{}_gc{}.txt".format(cfg.order, cfg.ratio, cfg.diffDel, cfg.gainCorr), "w+") as f:
        for spl in zip(sig[0], sig[1], sig[2]):
            f.write("{} {} {}\n".format(PsiFixGetBitsAsInt(spl[0], inFmt),
                                        PsiFixGetBitsAsInt(spl[1], inFmt),
                                        PsiFixGetBitsAsInt(spl[2], inFmt)))

for nr, sig in enumerate(outSig):
    cfg = configs[nr]
    with open(STIM_DIR + "/output_o{}_r{}_dd{}_gc{}.txt".format(cfg.order, cfg.ratio, cfg.diffDel, cfg.gainCorr), "w+") as f:
        for spl in zip(sig[0], sig[1], sig[2]):
            f.write("{} {} {}\n".format(PsiFixGetBitsAsInt(spl[0], outFmt),
                                        PsiFixGetBitsAsInt(spl[1], outFmt),
                                        PsiFixGetBitsAsInt(spl[2], outFmt)))


