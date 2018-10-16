########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Benoit Stef
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from psi_fix_pkg import *
import os
import numpy as np

########################################################################################################################
# LUT Generator Model
########################################################################################################################
class psi_fix_lut:

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self,
                 lut_content    : np.ndarray,
                 coefFmt        : PsiFixFmt):
        """
        Constructor for a bittrue model object of the LUT
        :param lut_content: LUT content
        :param coefFmt: Fixed-point format of the LUT content
        """
        # Direct parameters
        self.lut_content  = lut_content
        self.coefFmt      = coefFmt

        #transform value to PsiFix format from Real
        self.table      = PsiFixFromReal(self.lut_content, self.coefFmt, errSat=True)

    ####################################################################################################################
    # Public Methods
    ####################################################################################################################
    def Process(self, idx:np.array):
        """
        Simulate the LUT
        :param idx: LUT index input
        :return: LUT value output
        """
        return self.table[idx]

    def Generate(self,
                 path         : str,
                 entityName   : str):
        """
        Generate VHDL Code. The generated file has the same name as the entity.
        :param path: Folder to write the generated VHDL file into
        :param entityName: Entity name of the VHDL file to generate (also used as file-name)
        :return: None
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