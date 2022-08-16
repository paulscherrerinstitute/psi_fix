########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Rafael Basso
########################################################################################################################

########################################################################################################################
##  Imports
########################################################################################################################

from psi_fix_pkg import *
from psi_fix_matrix_mult import psi_fix_matrix_mult

########################################################################################################################
##  psi_fix_ss_solver class
########################################################################################################################

class psi_fix_ss_solver:

    def __init__(self, InFmt : PsiFixFmt, CoefAFmt : PsiFixFmt, CoefBFmt : PsiFixFmt, OutFmt : PsiFixFmt, IntFmt : PsiFixFmt, Order: int):
        """
        Constructor for the psi fix matrix multilier object
        :param InFmt    : Input fix point format
        :param CoefAFmt : Input fix point format for matrix A
        :param CoefBFmt : Input fix point format for scalar B
        :param OutFmt   : Output fix point format
        :param IntFmt   : Internal fix point format
        :param Order    : State space order 
        """
        assert Order > 1, "###ERROR###: System order must be higher than 1"

        self.InFmt    = InFmt
        self.CoefAFmt = CoefAFmt
        self.CoefBFmt = CoefBFmt
        self.OutFmt   = OutFmt
        self.IntFmt   = IntFmt
        self.Order    = Order


    def process(self, dataIn, matA, scaB):
        """
        State space solver process
        X[n] = AX[n-1] x Bu[n-1]
        :param dataIn  : Array containning the input values
        :param matA    : Array containning the matrix A input values
        :param matB    : Array containning the scalar B input values
        :return matX   : Matrix X, result of X[n] = AX[n-1] x Bu[n-1]
        """

        assert len(dataIn) == self.Order, "###ERROR###: Input data with incompatible size"
        assert len(matA) == (self.Order**2), "###ERROR###: Input matrix A with incompatible size"

        samples = len(scaB[0])

        mult_Ax = psi_fix_matrix_mult( InAFmt = self.CoefAFmt, 
                                       InBFmt = self.IntFmt, 
                                       OutFmt = self.IntFmt, 
                                       IntFmt = self.IntFmt, 
                                       matA_row = self.Order, 
                                       matA_col = self.Order, 
                                       matB_row = self.Order, 
                                       matB_col = 1 )

        mult_Bu = psi_fix_matrix_mult( InAFmt = self.InFmt, 
                                       InBFmt = self.CoefBFmt, 
                                       OutFmt = self.IntFmt, 
                                       IntFmt = self.IntFmt, 
                                       matA_row = self.Order, 
                                       matA_col = 1, 
                                       matB_row = 1, 
                                       matB_col = 1 )

        matBu = mult_Bu.process(dataIn, scaB)

        matX = []
        matX.append(PsiFixFromReal(np.zeros(samples), self.IntFmt))
        matX.append(PsiFixFromReal(np.zeros(samples), self.IntFmt))

        for i in range(1, samples):
            matAx = mult_Ax.process(matA, matX)

            for j in range(0, 2):
                matX[j][i] = PsiFixAdd(matAx[j][i-1], self.IntFmt, matBu[j][i-1], self.IntFmt, self.IntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        return [ PsiFixResize(matX[i], self.IntFmt, self.OutFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap) for i in range(len(dataIn)) ]