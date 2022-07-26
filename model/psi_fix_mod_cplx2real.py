########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef, Oliver Bründler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *

########################################################################################################################
# Bittrue model of the Modulator
########################################################################################################################
class psi_fix_mod_cplx2real:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,  InpFmt  : PsiFixFmt,
                        CoefFmt : PsiFixFmt,
                        IntFmt  : PsiFixFmt,
                        OutFmt  : PsiFixFmt,
                        ratio   : int,
                        offset  : int):
        """
        Constructor for the modulator model object
        :param InpFmt: Input fixed-point format
        :param CoefFmt: Modulation coefficient fixed-point format
        :param IntFmt: Internal format (see documentation)
        :param OutFmt: Output fixed-point format
        :param ratio: Ratio Fsample/Fcarrier (must be integer!)
        :param offset: NCO counter offset (must be integer!)
        """
        self.InpFmt     = InpFmt
        self.CoefFmt    = CoefFmt
        self.IntFmt     = IntFmt
        self.OutFmt     = OutFmt
        self.ratio      = ratio
        self.offset     = offset

    ####################################################################################################################
    # Public Methods
    ####################################################################################################################
    def Process(self, data_I_i: np.ndarray, data_Q_i : np.ndarray):
        """
        Modulate data
        :param data_I_i: Real-part of the input signal
        :param data_Q_i: Imaginary-part of the input signal
        :return: Real output signal
        """
        # resize real number to Fixed Point
        multFmt = PsiFixFmt(self.InpFmt.S, 1+self.InpFmt.I+self.CoefFmt.I, self.InpFmt.F+self.CoefFmt.F)
        addFmt = PsiFixFmt(self.IntFmt.S, self.IntFmt.I+1, self.IntFmt.F)
        datInp = PsiFixFromReal(data_I_i, self.InpFmt, errSat=True)
        datQua = PsiFixFromReal(data_Q_i, self.InpFmt, errSat=True)

        # ROM pointer
        # Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(data_I_i.size, dtype=np.int64)
        phaseSteps[0] = 1  # start at zero
        cptInt = np.cumsum(phaseSteps+self.offset-1, dtype=np.int64) % self.ratio
        cptIntOffs = cptInt
        print(cptInt)
        cpt = np.where(cptIntOffs > self.ratio - 1, cptIntOffs - self.ratio, cptIntOffs)
        print(cpt)
        # Get Sin/Cos value
        scale = 1.0 - 2.0 ** -self.CoefFmt.F
        sinTable = PsiFixFromReal(np.sin(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.CoefFmt)
        cosTable = PsiFixFromReal(np.cos(2.0 * np.pi * np.arange(0, self.ratio) / self.ratio) * scale, self.CoefFmt)

        # process calculation
        mult_i_s = PsiFixMult(datInp, self.InpFmt, sinTable[cpt], self.CoefFmt, multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        mult_q_s = PsiFixMult(datQua, self.InpFmt, cosTable[cpt], self.CoefFmt, multFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        #resize internal before add
        mult_i_dff_s = PsiFixResize(mult_i_s, multFmt, self.IntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        mult_q_dff_s = PsiFixResize(mult_q_s, multFmt, self.IntFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        # adder
        sum_s = PsiFixAdd(mult_i_dff_s, self.IntFmt, mult_q_dff_s, self.IntFmt, addFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)

        #resize output
        rf_s = PsiFixResize(sum_s, addFmt, self.OutFmt, PsiFixRnd.Round, PsiFixSat.Sat)

        rf_o = rf_s
        return rf_o

