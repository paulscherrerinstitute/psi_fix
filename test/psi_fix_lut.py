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

class psi_fix_lut_cfg_settings:
    def __init__(self,
                 coefFmt : PsiFixFmt,
                 rstPol  : int,
                 fileName: str,
                 romStyle: str):
        self.coefFmt    = coefFmt
        self.rstPol     = rstPol
        self.fileName   = fileName
        self.romStyle   = romStyle

class psi_fix_lut:

    def __init__(self, cfg: psi_fix_lut_cfg_settings,
                 inp: np.ndarray, path : str):
        # Direct parameters
        self.cfg  = cfg
        self.inp  = inp
        self.path = path

        #Get values
        table = PsiFixFromReal(self.inp, self.cfg.coefFmt, errSat=True)

        #Read template
        with open("../model/snippets/psi_fix_lut_tmpl.vhd", "r") as f:
            content = f.read()

        #Modify content
        content = content.replace("<ENTITY_NAME>",  self.cfg.fileName)
        content = content.replace("<RST_POL>", str(self.cfg.rstPol))
        content = content.replace("<OUT_FMT>", str(self.cfg.coefFmt))
        content = content.replace("<ROM_STYLE>", str(self.cfg.romStyle))
        content = content.replace("<SIZE>", str(np.size(table)))

        #coef Strings
        conv = "to_unsigned"
        if self.cfg.coefFmt.S == 1:
            conv = "to_signed"

        coefStr = ["{}({},{})".format(conv,
                                      PsiFixGetBitsAsInt(v, self.cfg.coefFmt),
                                      PsiFixSize(self.cfg.coefFmt))
                   for v in table]
        #modify table (transposition)
        tableLines = ["std_logic_vector({}),".format(g) for g in coefStr]
        tableLines[-1] = tableLines[-1][:-1] #remove last comma
        content = content.replace("<TABLE_CONTENT>", "\n\t\t".join(tableLines))

        #write generated file
        with open(path + "/" + self.cfg.fileName + ".vhd", "w+") as f:
            f.write(content)