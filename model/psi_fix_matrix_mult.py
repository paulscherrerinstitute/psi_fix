########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Rafael Basso
########################################################################################################################

########################################################################################################################
##  Imports
########################################################################################################################

from psi_fix_pkg import *

########################################################################################################################
##  psi_fix_matrix_mult class
########################################################################################################################

class psi_fix_matrix_mult:

    def __init__(self, InAFmt : PsiFixFmt, InBFmt : PsiFixFmt, OutFmt : PsiFixFmt, IntFmt : PsiFixFmt, matA_row : int, matA_col: int, matB_row: int, matB_col: int):
        """
        Constructor for the psi fix matrix multilier object
        :param InAFmt   : Input fix point format for matrix A
        :param InBFmt   : Input fix point format for matrix B
        :param OutFmt   : Output fix point format
        :param IntFmt   : Internal fix point format
        :param matA_row : Number of rows on matrix A 
        :param matA_col : Number of columns on matrix A
        :param matB_row : Number of rows on matrix B
        :param matB_col : Number of columns on matrix B
        """
        self.InAFmt = InAFmt
        self.InBFmt = InBFmt
        self.OutFmt = OutFmt
        self.IntFmt = IntFmt

        assert matA_col == matB_row, "###ERROR###: Matrices have incompatible dimensions"

        self.matA_row = matA_row
        self.matA_col = matA_col

        self.matB_row = matB_row
        self.matB_col = matB_col

    def process(self, matA, matB):
        """
        Matrices multiplication process
        C = A x B
        :param matA    : Matrix A (matA_row x matA_col)
        :param matB    : Matrix B (matB_row x matB_col)
        :return matC   : Matrix C, result of A x B
        """
        matC = []

        for i in range(0, self.matA_row):
            for j in range(0, self.matB_col):

                add = PsiFixFromReal(0, self.IntFmt)
                for k in range(0, self.matB_row):
                    mult = PsiFixMult(matA[(i*self.matA_col)+k], self.InAFmt, matB[(k*self.matB_col)+j], self.InBFmt, self.IntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
                    add  = PsiFixAdd(add, self.IntFmt, mult, self.IntFmt, self.IntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
    
                matC.append(PsiFixResize(add, self.IntFmt, self.OutFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap))

        return matC