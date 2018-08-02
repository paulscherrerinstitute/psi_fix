# =================================================================
#	Paul Scherrer Institut <PSI> Villigen, Schweiz
# 	Copyright ©, 2018, Benoit STEF, all rights reserved
# =================================================================
# Purpose   : Generate VHDL file out of this file
# Author    : Benoît STEF - SB82 DSV group 8221 @PSI WBBA/302
# Project   : PSI FIX Library
# Used in   : HIPA Upgrade Inj2 LLRF
# HDL file  :
# ==================================================================
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
import os
import numpy as np


class psi_fix_lut:
    """
            Constructor
    """
    def __init__(self,
                 inp        : np.ndarray,
                 coefFmt    : PsiFixFmt):
        # Direct parameters
        self.inp        = inp
        self.coefFmt    = coefFmt

        #transform value to PsiFix format from Real
        self.table      = PsiFixFromReal(self.inp, self.coefFmt, errSat=True)


    def Process(self, idx:np.array):
        """
           LUT function
        """
        self.idx = idx
        for i in self.idx:
            return self.table[idx]

    def Generate(self,
                 path       : str,
                 fileName   : str):
        """
           Generate vhdl code
        """
        self.path = path
        self.fileName = fileName

        # Get path of the fix python files
        filepath = os.path.realpath(__file__)
        dirpath  = os.path.dirname(filepath)

        #Read template
        # Read snipped
        with open(dirpath + "/snippets/psi_fix_lut_tmpl.vhd") as f:
            content = f.read()

        #Modify content
        content = content.replace("<ENTITY_NAME>",  self.fileName)
        content = content.replace("<OUT_FMT>", str(self.coefFmt))
        content = content.replace("<SIZE>", str(np.size(self.table)))

        #coef Strings
        conv = "to_unsigned"
        if self.coefFmt.S == 1:
            conv = "to_signed"

        coefStr = ["{}({},{})".format(conv,
                                      PsiFixGetBitsAsInt(v, self.coefFmt),
                                      PsiFixSize(self.coefFmt))
                   for v in self.table]
        #modify table (transposition)
        tableLines = ["std_logic_vector({}),".format(g) for g in coefStr]
        tableLines[-1] = tableLines[-1][:-1] #remove last comma
        content = content.replace("<TABLE_CONTENT>", "\n\t\t".join(tableLines))

        #write generated file
        with open(path + "/" + self.fileName + ".vhd", "w+") as f:
            f.write(content)