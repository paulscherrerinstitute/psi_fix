########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Rafael Basso
########################################################################################################################
import os
import sys

import numpy as np
import scipy.signal as sps

sys.path.append("../../../model")

from psi_fix_pkg import *

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../data"


try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

#############################################################
#   Formats
#############################################################

inFmt    = PsiFixFmt(1, 0, 15)
intFmt   = PsiFixFmt(1, 1, 30)
outFmt   = PsiFixFmt(1, 0, 16)

#############################################################
#   Simulation
#############################################################

def matrix_gen(matA_row, matA_col, matB_row, matB_col, samples):

    if matA_col != matB_row:
        print("###ERROR###: Matrices have incompatible dimensions")
        exit(-1)

    print("Matrix A : ", matA_row, "x", matA_col)
    print("Matrix B : ", matB_row, "x", matB_col)
    ######################################
    #   Matrix A
    ######################################
    
    A = []
    Aint = []
    strg1 = ""
    for i in range(matA_row*matA_col):
        strg1 = strg1 + "a%i " % i
        x = PsiFixFromReal(np.random.uniform(low=0.00001, high=0.999, size=1).astype(float)*np.ones(samples), inFmt)
        A.append(x);
        Aint.append(PsiFixGetBitsAsInt(x, inFmt))
    
    ######################################
    #   Matrix B
    ######################################
    
    B = []
    Bint = []
    strg2 = ""
    for i in range(matB_row*matB_col):
        strg2 = strg2 + "b%i " % i
        x = PsiFixFromReal(np.random.uniform(low=0.00001, high=0.999, size=1).astype(float)*np.ones(samples), inFmt)
        B.append(x);
        Bint.append(PsiFixGetBitsAsInt(x, inFmt))
    
    Cint = np.concatenate((Aint, Bint), axis = 0)
    
    ######################################
    #   Process
    ######################################

    res = []
    resInt = []
    strg3 = ""
    for i in range(0, matA_row):
        for j in range(0, matB_col):
            strg3 = strg3 + "res%i " % (j+(i*matB_col))
            add = PsiFixFromReal(0, intFmt)
            for k in range(0, matB_row):
                mult = PsiFixMult(A[(i*matA_col)+k], inFmt, B[(k*matB_col)+j], inFmt, intFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
                add  = PsiFixAdd(add, intFmt, mult, intFmt, intFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

            resInt.append(PsiFixGetBitsAsInt(PsiFixResize(add, intFmt, outFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap), outFmt))
            res.append(add)

    return Cint, resInt, (strg1+strg2), strg3

def main():
    
    matrixIN_1, matrixOUT_1, strgIN_1, strgOUT_1 = matrix_gen(2, 2, 2, 2, 100)
    
    matrixIN_2, matrixOUT_2, strgIN_2, strgOUT_2 = matrix_gen(2, 3, 3, 1, 100)
    matrixIN_3, matrixOUT_3, strgIN_3, strgOUT_3 = matrix_gen(2, 3, 3, 1, 100)
    
    #############################################################
    #   Output files
    #############################################################
    
    np.savetxt(STIM_DIR + "/input_2x2_2x2.txt",
               np.column_stack( matrixIN_1 ),
               fmt="%i", header=strgIN_1)
    
    np.savetxt(STIM_DIR + "/output_2x2_2x2.txt",
               np.column_stack( matrixOUT_1 ),
               fmt="%i", header=strgOUT_1)
    
    np.savetxt(STIM_DIR + "/input_2x3_3x1.txt",
               np.vstack( ([np.column_stack(matrixIN_2), np.column_stack(matrixIN_3)]) ),
               fmt="%i", header=strgIN_2)

    np.savetxt(STIM_DIR + "/output_2x3_3x1.txt",
               np.vstack( ([np.column_stack(matrixOUT_2), np.column_stack(matrixOUT_3)]) ),
               fmt="%i", header=strgOUT_2)

if __name__ == "__main__":
    main()
    exit(0)