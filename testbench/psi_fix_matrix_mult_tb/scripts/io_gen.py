########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Rafael Basso
########################################################################################################################

########################################################################################################################
##  Imports
########################################################################################################################

import os
import sys

import numpy as np

sys.path.append("../../../model")

from psi_fix_pkg import *
from psi_fix_matrix_mult import psi_fix_matrix_mult

STIM_DIR = os.path.dirname(os.path.abspath(__file__)) + "/../data"


try:
    os.mkdir(STIM_DIR)
except FileExistsError:
    pass

########################################################################################################################
##  Formats
########################################################################################################################

inAFmt   = PsiFixFmt(1, 2, 13)
inBFmt   = PsiFixFmt(1, 0, 15)
intFmt   = PsiFixFmt(1, 2, 29)
outFmt   = PsiFixFmt(1, 2, 14)

########################################################################################################################
##  Functions
########################################################################################################################

def matrix_gen(matA_row, matA_col, matB_row, matB_col, samples):

    if matA_col != matB_row:
        print("###ERROR###: Matrices have incompatible dimensions")
        exit(-1)

    print("Matrix A : ", matA_row, "x", matA_col)
    print("Matrix B : ", matB_row, "x", matB_col)
    print("----------------------")

    #############################################################
    ##  Matrix A
    #############################################################
    
    A = []
    for i in range(matA_row*matA_col):
        x = PsiFixFromReal(np.random.uniform(low=0.00001, high=0.999, size=1).astype(float)*np.ones(samples), inAFmt)
        A.append(x);
    
    #############################################################
    ##  Matrix B
    #############################################################
    
    B = []
    for i in range(matB_row*matB_col):
        x = PsiFixFromReal(np.random.uniform(low=0.00001, high=0.999, size=1).astype(float)*np.ones(samples), inBFmt)
        B.append(x);

    return A, B

def matrix_as_int(mat, matFmt):
    matInt = []
    for i in range(len(mat)):
        matInt.append(PsiFixGetBitsAsInt(mat[i], matFmt))
    return matInt

def main():

    #############################################################
    ##  Matrices generation
    #############################################################
    
    matrixIN_A_1, matrixIN_B_1 = matrix_gen(2, 2, 2, 2, 100)
    matrixIN_1 = np.concatenate( (matrix_as_int(matrixIN_A_1, inAFmt), matrix_as_int(matrixIN_B_1, inBFmt)) )

    
    matrixIN_A_2, matrixIN_B_2 = matrix_gen(2, 3, 3, 1, 100)
    matrixIN_2 = np.concatenate( (matrix_as_int(matrixIN_A_2, inAFmt), matrix_as_int(matrixIN_B_2, inBFmt)) )

    matrixIN_A_3, matrixIN_B_3 = matrix_gen(2, 3, 3, 1, 100)
    matrixIN_3 = np.concatenate( (matrix_as_int(matrixIN_A_3, inAFmt), matrix_as_int(matrixIN_B_3, inBFmt)) )


    matrixIN_A_4, matrixIN_B_4 = matrix_gen(5, 5, 5, 5, 100)
    matrixIN_4 = np.concatenate( (matrix_as_int(matrixIN_A_4, inAFmt), matrix_as_int(matrixIN_B_4, inBFmt)) )

    #############################################################
    ##  Multiplication
    #############################################################

    mult_1  = psi_fix_matrix_mult(InAFmt=inAFmt, InBFmt=inBFmt, OutFmt=outFmt, IntFmt=intFmt, matA_row=2, matA_col=2, matB_row=2, matB_col=2)
    mult_23 = psi_fix_matrix_mult(InAFmt=inAFmt, InBFmt=inBFmt, OutFmt=outFmt, IntFmt=intFmt, matA_row=2, matA_col=3, matB_row=3, matB_col=1)
    mult_4  = psi_fix_matrix_mult(InAFmt=inAFmt, InBFmt=inBFmt, OutFmt=outFmt, IntFmt=intFmt, matA_row=5, matA_col=5, matB_row=5, matB_col=5)

    matrixOUT_1 = mult_1.process(matrixIN_A_1, matrixIN_B_1)
    matrixOUT_1 = matrix_as_int(matrixOUT_1, outFmt)


    matrixOUT_2 = mult_23.process(matrixIN_A_2, matrixIN_B_2)
    matrixOUT_2 = matrix_as_int(matrixOUT_2, outFmt)

    matrixOUT_3 = mult_23.process(matrixIN_A_3, matrixIN_B_3)
    matrixOUT_3 = matrix_as_int(matrixOUT_3, outFmt)


    matrixOUT_4 = mult_4.process(matrixIN_A_4, matrixIN_B_4)
    matrixOUT_4 = matrix_as_int(matrixOUT_4, outFmt)

    #############################################################
    ##  Output files
    #############################################################
    
    np.savetxt(STIM_DIR + "/input_2x2_2x2.txt",
               np.column_stack( matrixIN_1 ),
               fmt="%i", header="a0 a1 a2 a3 b0 b1 b2 b3")
    
    np.savetxt(STIM_DIR + "/output_2x2_2x2.txt",
               np.column_stack( matrixOUT_1 ),
               fmt="%i", header="res0 res1 res2 res3")

    
    np.savetxt(STIM_DIR + "/input_2x3_3x1.txt",
               np.vstack( ([np.column_stack(matrixIN_2), np.column_stack(matrixIN_3)]) ),
               fmt="%i", header="a0 a1 a2 a3 a4 a5 b0 b1 b2")

    np.savetxt(STIM_DIR + "/output_2x3_3x1.txt",
               np.vstack( ([np.column_stack(matrixOUT_2), np.column_stack(matrixOUT_3)]) ),
               fmt="%i", header="res0 res1")


    np.savetxt(STIM_DIR + "/input_5x5_5x5.txt",
               np.column_stack( matrixIN_4 ),
               fmt="%i", header="a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 a21 a22 a23 a24 b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 b16 b17 b18 b19 b20 b21 b22 b23 b24")
    
    np.savetxt(STIM_DIR + "/output_5x5_5x5.txt",
               np.column_stack( matrixOUT_4 ),
               fmt="%i", header="res0 res1 res2 res3 res4 res5 res6 res7 res8 res9 res10 res11 res12 res13 res14 res15 res16 res17 res18 res19 res20 res21 res22 res23 res24")

########################################################################################################################
##  Main
########################################################################################################################

if __name__ == "__main__":
    main()
    exit(0)