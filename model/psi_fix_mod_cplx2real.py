########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef, Oliver Bründler, Radoslaw Rybaniec
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
    def __init__(self,  InpFmt         : psi_fix_fmt_t,
                        CoefFmt        : psi_fix_fmt_t,
                        IntFmt         : psi_fix_fmt_t,
                        OutFmt         : psi_fix_fmt_t,
                        ratio_num      : int,
                        ratio_den      : int):
        """
        Constructor for the modulator model object
        :param InpFmt: Input fixed-point format
        :param CoefFmt: Modulation coefficient fixed-point format
        :param IntFmt: Internal format (see documentation)
        :param OutFmt: Output fixed-point format
        :param ratio_num: Ratio Fsample/Fcarrier (must be integer!)
        :param ratio_den: NCO counter offset (must be integer!)
        """
        self.InpFmt     = InpFmt
        self.CoefFmt    = CoefFmt
        self.IntFmt     = IntFmt
        self.OutFmt     = OutFmt
        self.ratio_num  = ratio_num
        self.ratio_den  = ratio_den

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
        multFmt = psi_fix_fmt_t(self.InpFmt.s, 1+self.InpFmt.i+self.CoefFmt.i, self.InpFmt.f+self.CoefFmt.f)
        addFmt = psi_fix_fmt_t(self.IntFmt.s, self.IntFmt.i+1, self.IntFmt.f)
        datInp = psi_fix_from_real(data_I_i, self.InpFmt, err_sat=True)
        datQua = psi_fix_from_real(data_Q_i, self.InpFmt, err_sat=True)

        # ROM pointer
        # Generate phases (use integer to prevent floating point precision errors)
        phaseSteps = np.ones(data_I_i.size, dtype=np.int64)
        phaseSteps[0] = 1  # start at zero
        cptInt = np.cumsum(phaseSteps+self.ratio_den-1, dtype=np.int64) % self.ratio_num
        cptIntOffs = cptInt
        print(cptInt)
        cpt = np.where(cptIntOffs > self.ratio_num - 1, cptIntOffs - self.ratio_num, cptIntOffs)
        print(cpt)
        # Get Sin/Cos value
        scale = 1.0 - 2.0 ** -self.CoefFmt.f
        sinTable = psi_fix_from_real(np.sin(2.0 * np.pi * np.arange(0, self.ratio_num) / self.ratio_num) * scale, self.CoefFmt)
        cosTable = psi_fix_from_real(np.cos(2.0 * np.pi * np.arange(0, self.ratio_num) / self.ratio_num) * scale, self.CoefFmt)

        # process calculation
        mult_i_s = psi_fix_mult(datInp, self.InpFmt, sinTable[cpt], self.CoefFmt, multFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        mult_q_s = psi_fix_mult(datQua, self.InpFmt, cosTable[cpt], self.CoefFmt, multFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)

        #resize internal before add
        mult_i_dff_s = psi_fix_resize(mult_i_s, multFmt, self.IntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)
        mult_q_dff_s = psi_fix_resize(mult_q_s, multFmt, self.IntFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)

        # adder
        sum_s = psi_fix_add(mult_i_dff_s, self.IntFmt, mult_q_dff_s, self.IntFmt, addFmt, psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap)

        #resize output
        rf_s = psi_fix_resize(sum_s, addFmt, self.OutFmt, psi_fix_rnd_t.round, psi_fix_sat_t.sat)

        rf_o = rf_s
        return rf_o

