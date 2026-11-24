########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Rafael Basso
########################################################################################################################
import os
import sys

import numpy as np

sys.path.append("../../../model")

from psi_fix_pkg import *
from psi_fix_ss_solver import psi_fix_ss_solver


STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../data"


try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
#   Formats
#############################################################

inFmt    = PsiFixFmt(1, 0, 15)

coefAFmt  = PsiFixFmt(1, 0, 31)
coefBFmt  = PsiFixFmt(1, 29, 2)



intFmt   = PsiFixFmt(1, 29, 2)
outFmt   = PsiFixFmt(1, 29, 2)

#############################################################
#   Simulation
#############################################################

PLOT_ON = False

samples = 2048
factor  = 1e4

t = np.arange(samples) * 1e-6
sig = np.zeros(samples)

 
sig[0:512]    = 16e-3
sig[512:1300] = 8e-3


fs = 100e6
#Ts = 1/fs
Ts = 1e-6

f0  = 1.3e9
rQ  = 1036.
Ql  = 3.0e6

dw_ratio = 0.0

w0 = 2 * np.pi * f0
Rl = 0.5 * rQ * Ql

whb = w0 / (2 * Ql)
dw  = dw_ratio * whb

######################################
#   Matrix A
######################################

a1 = 1 - (whb*Ts)
a2 = -Ts*dw

a3 = Ts*dw
a4 = 1 - (whb*Ts)

a1Fix = PsiFixFromReal(a1, coefAFmt) * np.ones(samples)
a2Fix = PsiFixFromReal(a2, coefAFmt) * np.ones(samples)
a3Fix = PsiFixFromReal(a3, coefAFmt) * np.ones(samples)
a4Fix = PsiFixFromReal(a4, coefAFmt) * np.ones(samples)

matA = []
matA.append(a1Fix)
matA.append(a2Fix)
matA.append(a3Fix)
matA.append(a4Fix)

######################################
#   Matrix B
######################################

b1 = (Ts * whb * Rl)

b1Fix = PsiFixFromReal(b1, coefBFmt) * np.ones(samples)

matB = []
matB.append(b1Fix)

######################################
#   Input signal
######################################

data_IFix = PsiFixFromReal(sig, inFmt) 
data_QFix = PsiFixFromReal(sig, inFmt)

dataFix = []
dataFix.append(data_IFix)
dataFix.append(data_QFix)

######################################
#   Process
######################################

sss = psi_fix_ss_solver(InFmt=inFmt , CoefAFmt=coefAFmt , CoefBFmt=coefBFmt , OutFmt=outFmt , IntFmt=intFmt , Order=2)

matX = sss.process(dataIn=dataFix, matA=matA, scaB=matB)

if PLOT_ON:
    plt.figure()
    plt.plot(t, matX[0])
    plt.grid()

    plt.show()

#############################################################
##  Output files
#############################################################

matIN = np.concatenate( ([ PsiFixGetBitsAsInt(dataFix[i], inFmt) for i in range(len(dataFix)) ], 
                         [ PsiFixGetBitsAsInt(matA[i], coefAFmt) for i in range(len(matA)) ], 
                         [ PsiFixGetBitsAsInt(matB[i], coefBFmt) for i in range(len(matB)) ] ) )

matOUT = []
matOUT.append(np.delete(matX[0], 0));
matOUT.append(np.delete(matX[1], 0));
    
np.savetxt(STIM_DIR + "/input.txt",
           np.column_stack( matIN ),
           fmt="%i", header="data_I data_Q a0 a1 a2 a3 b0")

np.savetxt(STIM_DIR + "/output.txt",
           np.column_stack( [ PsiFixGetBitsAsInt(matOUT[i], outFmt) for i in range(len(matOUT)) ] ),
           fmt="%i", header="data_I data_Q")