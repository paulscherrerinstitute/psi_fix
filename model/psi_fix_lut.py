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

    def __init__(self,
                 lut_content    : np.ndarray,
                 coefFmt        : PsiFixFmt):
        """
        Constructor
        """
        # Direct parameters
        self.lut_content  = lut_content
        self.coefFmt      = coefFmt

        #transform value to PsiFix format from Real
        self.table      = PsiFixFromReal(self.lut_content, self.coefFmt, errSat=True)


    def Process(self, idx:np.array):
        """
           LUT function
        """
        return self.table[idx]

    def Generate(self,
                 path         : str,
                 entityName   : str):
        """
           Generate vhdl code
        """

        # Get path of the fix python files
        filepath = os.path.realpath(__file__)
        dirpath  = os.path.dirname(filepath)

        #Read template
        # Read snipped
        with open(dirpath + "/snippets/psi_fix_lut_tmpl.vhd") as f:
            content = f.read()

        #Modify content
        content = content.replace("<ENTITY_NAME>",  entityName)
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
        with open(path + "/" + entityName + ".vhd", "w+") as f:
            f.write(content)