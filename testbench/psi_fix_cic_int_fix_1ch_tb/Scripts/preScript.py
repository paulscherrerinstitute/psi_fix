import sys
sys.path.append("../../../model")
import numpy as np
import scipy.signal as sps
from psi_fix_pkg import *
from psi_fix_cic_int import psi_fix_cic_int
from typing import NamedTuple
import matplotlib.pyplot as plt
import os

PLOT_ON = False
STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../Data"
SAMPLES = 1000
FREQ_SAMPLE = 10e6
TEND = (SAMPLES-1)/FREQ_SAMPLE
try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
# Data Generation
#############################################################
inFmt = PsiFixFmt(1, 0, 16)
outFmt = PsiFixFmt(1, 0, 17)

np.random.seed(0)
t = np.linspace(0,TEND,SAMPLES)
inSig = sps.chirp(t, 0, TEND, FREQ_SAMPLE/2)
inSig = PsiFixFromReal(inSig, inFmt, errSat=False)

CfgInfo = NamedTuple("CfgInfo", [("order", int), ("ratio", int), ("diffDel", int), ("gainCorr", bool)])
configs = []
configs.append(CfgInfo(order=3, ratio=10, diffDel=1, gainCorr=True))
configs.append(CfgInfo(order=4, ratio=9, diffDel=2, gainCorr=True))
configs.append(CfgInfo(order=4, ratio=6, diffDel=2, gainCorr=False))

outSig = []
for cfg in configs:
    model = psi_fix_cic_int(cfg.order, cfg.ratio, cfg.diffDel, inFmt, outFmt, cfg.gainCorr)
    outp = model.Process(inSig)
    if PLOT_ON:
        plt.plot(20*np.log10(abs(outp)+1e-10))
        plt.show()
    outSig.append(outp)


#############################################################
# Write files
#############################################################
with open(STIM_DIR + "/input.txt", "w+") as f:
    for spl in inSig:
        f.write("{}\n".format(PsiFixGetBitsAsInt(spl, inFmt)))

for nr, sig in enumerate(outSig):
    cfg = configs[nr]
    with open(STIM_DIR + "/output_o{}_r{}_dd{}_gc{}.txt".format(cfg.order, cfg.ratio, cfg.diffDel, cfg.gainCorr), "w+") as f:
        for spl in sig:
            f.write("{}\n".format(PsiFixGetBitsAsInt(spl, outFmt)))


