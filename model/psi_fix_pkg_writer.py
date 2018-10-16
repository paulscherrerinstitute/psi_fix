########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
import numpy as np
from typing import Union, Iterable
from enum import Enum
import os

########################################################################################################################
# Types
########################################################################################################################
class VhdlType(Enum):
    INTEGER = 0
    REAL = 1

########################################################################################################################
# Main Class
########################################################################################################################
class psi_fix_pkg_writer:
    """
    This class implements a simple VHDL package writer to easily exchange values between python an VHDL.

    Currently only the following types are supported:
    - Integer
    - Float (Real in VHDL)

    Usage example:
    w = psi_fix_pkg_writer()
    w.AddConstant("AnyConstant_c", 3, VhdlType.INTEGER)
    w.WritePkg("my_pkg", "../hdl")
    """

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self):
        """
        Construcctor
        """
        self._arrays = {}
        self._constants = {}
        self._allNames = []


    ####################################################################################################################
    # Public Functions
    ####################################################################################################################
    def AddConstant(self, name : str, value : Union[float, int], type : VhdlType) -> None:
        """
        Add a constant to the package
        :param name: Name of the VHDL constant
        :param value: Value of the constant
        :param type: VHDL Type of the constant
        """
        self._checkName(name)
        if type is VhdlType.INTEGER:
            self._checkInt(value)
        self._constants[name] = (type, value)

    def AddArray(self, name : str, value : Union[Iterable, np.ndarray], type : VhdlType) -> None:
        """
        Add an array constant to the package
        :param name: Name of the VHDL constant
        :param value: Value of the constant (pass an array, even for size 1 arrays)
        :param type: VHDL Type of the constant
        """
        self._checkName(name)
        if not isinstance(value, np.ndarray):
            value = np.array(value)
        if type is VhdlType.INTEGER:
            self._checkInt(value)
        self._arrays[name] = (type, value)

    def WritePkg(self, pkg_name : str, directory : str, psi_common_lib : str = "work") -> None:
        """
        Generate the VHDL package
        :param pkg_name: VHDL package name (used as file name too)
        :param directory: Target directory
        :param psi_common_lib: Name of the VHDL library psi_common_array_pkg is compiled into. This argumet is optional
                               and the default library is "work".
        """
        #Get path of the fix python files
        filepath = os.path.realpath(__file__)
        dirpath = os.path.dirname(filepath)

        #Read snipped
        with open(dirpath + "/snippets/psi_fix_pkg_writer_tmpl.vhd") as f:
            content = f.read()

        #Replace Package name
        content = content.replace("<PACKAGE_NAME>", pkg_name)
        content = content.replace("<PSI_COMMON_LIB>", psi_common_lib)

        pkgDecl = ""
        #Write constants
        for name, (vhType, value) in self._constants.items():
            if vhType == VhdlType.INTEGER:
                t = "integer"
            elif vhType == VhdlType.REAL:
                t = "real"
                value = self._convReal(value)
            else:
                raise ValueError("Illegel type for Constant {}".format(name))
            pkgDecl += "\n\tconstant {} : {} := {};\n".format(name, t, value)

        #Write arrays
        for name, (vhType, value) in self._arrays.items():
            if vhType == VhdlType.INTEGER:
                t = "t_ainteger(0 to {})".format(len(value)-1)
            elif vhType == VhdlType.REAL:
                t = "t_areal(0 to {})".format(len(value)-1)
                value = self._convReal(value)
            else:
                raise ValueError("Illegel type for Array {}".format(name))
            pkgDecl += "\n\tconstant {} : {} := (\n".format(name, t)
            for v in value[:-1]:
                pkgDecl += "\t\t{},\n".format(v)
            pkgDecl += "\t\t{});\n".format(value[-1])
        content = content.replace("<PACKAGE_DECLARATION>", pkgDecl)

        #Write File
        with open(directory + "/" + pkg_name + ".vhd", "w+") as f:
            f.write(content)

    ####################################################################################################################
    # Private Functions
    ####################################################################################################################
    def _checkInt(self, value):
        if isinstance(value, Iterable):
            for v in value:
                self._checkInt(v)
        else:
            if np.mod(value, 1) != 0:
                raise ValueError("For VhdlType.INTEGER an integer value must be passed, got {}".format(value))

    def _convReal(self, value) -> float:
        if isinstance(value, Iterable):
            return np.array(value, dtype=float)
        else:
            return float(value)

    def _checkName(self, name : str):
        if name.lower() in self._allNames:
            raise ValueError("Name {} already exists in package".format(name))
        self._allNames.append(name.lower())





