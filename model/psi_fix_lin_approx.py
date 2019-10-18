########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################

########################################################################################################################
# Imports
########################################################################################################################
from psi_fix_pkg import *
import numpy as np
from scipy.misc import derivative
from scipy import stats
import matplotlib.pyplot as plt
import os

########################################################################################################################
# Helper class for describing configurations of the linear-approximation
########################################################################################################################
class psi_fix_lin_cfg_settings:


    def __init__(self, function,
                 inFmt: PsiFixFmt,
                 outFmt: PsiFixFmt,
                 offsFmt: PsiFixFmt,
                 gradFmt: PsiFixFmt,
                 points: int,
                 name : str,
                 validRange : tuple = (0, np.inf)):
        """
        Data container class containing the configuration of a linear approximation function

        :param function:    Function to approximate over the full range of inFmt. Lambdas like lambda x: np.sin(x * np.pi) can
                            be used to scale the X/Y axes.
        :param inFmt:       Format of the input to the approximation
        :param outFmt:      Format of the output of the approximation
        :param offsFmt:     Format of the offset table
        :param gradFmt:     Format of the gradient table
        :param points:      Number of points in the offset/gradient table
        :param name:        Name suffix of the approximator generated (used for code generation)
        :param validRange:  Range in which the approximation is valid
        """
        self.validRange = (max(validRange[0], PsiFixLowerBound(inFmt)),
                           min(validRange[1], PsiFixUpperBound(inFmt)))
        self.function = function
        self.inFmt = inFmt
        self.outFmt = outFmt
        self.offsFmt = offsFmt
        self.gradFmt = gradFmt
        self.points = points
        self.name = name

########################################################################################################################
# Linear Approximation Bittrue Model and Code Generator
########################################################################################################################
class psi_fix_lin_approx:

    ####################################################################################################################
    # Constants
    ####################################################################################################################
    SNIPPETS_PATH = os.path.dirname(__file__) + "/snippets"

    #Function Definitions
    GAUSSIFY_TABLE = stats.norm.ppf(np.linspace(0.001,0.999,1025))/3
    GAUSSIFY_TABLE = np.maximum(-1, GAUSSIFY_TABLE)
    GAUSSIFY_TABLE = np.minimum(1, GAUSSIFY_TABLE)

    @classmethod
    def _Gaussify(cls, values):
        idxExact = (values / 2 + 0.5) * 1024
        idx = np.array(idxExact, dtype=np.int)
        offset = idxExact - idx
        return cls.GAUSSIFY_TABLE[idx] + offset * (cls.GAUSSIFY_TABLE[idx + 1] - cls.GAUSSIFY_TABLE[idx])


    #Standard configurations of the approximation
    class CONFIGS:
        Sin18Bit = psi_fix_lin_cfg_settings(
                        function=lambda x: np.sin(x * 2 * np.pi)*(1-1/2**17), #Prevent +1 from occurring
                        inFmt=PsiFixFmt(0,0,20),
                        outFmt=PsiFixFmt(1,0,17),
                        offsFmt=PsiFixFmt(1,0,19),
                        gradFmt=PsiFixFmt(1,3,8),
                        points=2048,
                        name="sin18b")
        Sqrt18Bit = psi_fix_lin_cfg_settings(
                        function=lambda x: np.sqrt(x), #Prevent +1 from occurring
                        inFmt=PsiFixFmt(0,0,20),
                        outFmt=PsiFixFmt(0,0,17),
                        offsFmt=PsiFixFmt(0,0,19),
                        gradFmt=PsiFixFmt(0,0,10),
                        points=512,
                        name="sqrt18b",
                        validRange=(0.25,(1-(2**-17))**2))
        Gaussify20Bit = psi_fix_lin_cfg_settings(
                        function=lambda x: psi_fix_lin_approx._Gaussify(x),
                        inFmt=PsiFixFmt(1,0,19),
                        outFmt=PsiFixFmt(1,0,19),
                        offsFmt=PsiFixFmt(1,0,21),
                        gradFmt=PsiFixFmt(0,5,9),
                        points=1024,
                        name="gaussify20b",
                        validRange=(-1,1))
        all = [Sin18Bit, Sqrt18Bit, Gaussify20Bit]

    ####################################################################################################################
    # Static Methods
    ####################################################################################################################
    #Config Methods for MATLAB Compatibility (MATLAB does not support nested classes)
    @classmethod
    def ConfigSin18Bit(cls):
        return psi_fix_lin_approx.CONFIGS.Sin18Bit

    @classmethod
    def ConfigSqrt18Bit(cls):
        return psi_fix_lin_approx.CONFIGS.Sqrt18Bit

    @classmethod
    def ConfigGaussify20Bit(cls):
        return psi_fix_lin_approx.CONFIGS.Gaussify20Bit

    @classmethod
    def Design(cls, cfg : psi_fix_lin_cfg_settings, simPoints : int = 100000, simRange : tuple = None):
        """
        Design a psi fix linear approximation. This function evaluates the behavior of a linear approximation
        according to the settings passed and plots performance characteristics.
        If a new configuration of the liear approximator is required, this function shall be used to choose
        propper configuration settings iteratively.

        :param cfg:         Configuration of the approximation
        :param simPoints:   Points to simulate for analysis
        :param simRange:    Range to run the simulation for
        :return:            Approximation object created
        """
        #Create Approximation in design mode
        app = cls(cfg, designMode=True)
        app.Analyze(simPoints, simRange)

    ####################################################################################################################
    # Constructor
    ####################################################################################################################
    def __init__(self, cfg : psi_fix_lin_cfg_settings,
                 designMode : bool = False):
        """
        Create a linear approximation instance

        :param cfg:         Configuration of the approximation
        :param designMode:  In design mode, the ranges of offset/gradient are printed
        """
        #Direct parameters
        self.cfg = cfg
        self.indexBits =  np.log2(cfg.points)
        #Formats
        offsBits = PsiFixSize(self.cfg.inFmt) - self.indexBits
        self.remFmt = PsiFixFmt(0, offsBits - self.cfg.inFmt.F, self.cfg.inFmt.F)
        self.idxFmt = PsiFixFmt(0, self.cfg.inFmt.S + self.cfg.inFmt.I,
                                self.cfg.inFmt.F - self.remFmt.F - self.remFmt.I)
        self.intFmt = PsiFixFmt(1, self.remFmt.I + self.cfg.gradFmt.I + 1,
                                self.remFmt.F + self.cfg.gradFmt.F)
        self.addFmt = PsiFixFmt(max(self.intFmt.S, self.cfg.offsFmt.S), max(self.intFmt.I, self.cfg.offsFmt.I)+1, max(self.intFmt.F, self.cfg.offsFmt.F))
        #Calculate tables
        inputRange = [PsiFixLowerBound(self.cfg.inFmt), 2 ** self.cfg.inFmt.I]
        fullRange = inputRange[1] - inputRange[0]
        step = fullRange / self.cfg.points
        centers = np.arange(inputRange[0] + step / 2, inputRange[1], step)
        if self.cfg.inFmt.S is 1:
            centers = np.concatenate((centers[int(centers.size / 2):], centers[0:int(centers.size / 2)]))
        gradients = derivative(self.cfg.function, centers, dx=1e-6)
        offsets = self.cfg.function(centers)
        if designMode:
            minIdx = self._GetTblIdx(cfg.validRange[0])
            maxIdx = self._GetTblIdx(cfg.validRange[1])
            #For input containing negativ numbers, the negative numbers are stored in the upper half of the table.
            if minIdx < maxIdx:
                usedIdx = range(minIdx, maxIdx+1)
            else:
                usedIdx = list(range(0,minIdx+1)) + list(range(maxIdx,len(gradients)))
            print("gradients: {} ... {}".format(min(gradients[usedIdx]), max(gradients[usedIdx])))
            print("offsets: {} ... {}".format(min(offsets[usedIdx]), max(offsets[usedIdx])))
            print("table memory width: {}".format(PsiFixSize(self.cfg.offsFmt)+PsiFixSize(self.cfg.gradFmt)))
        self.gradTable = PsiFixFromReal(gradients, self.cfg.gradFmt, errSat=False)
        self.offsTable = PsiFixFromReal(offsets, self.cfg.offsFmt, errSat=False)

    ####################################################################################################################
    # Public Methods and Properties
    ####################################################################################################################
    def Approximate(self, inp):
        """
        Execute the approximation
        :param inp: Input to the approximation
        :return:    Output from the approximation
        """
        inp = PsiFixFromReal(inp, self.cfg.inFmt)
        tblIdx = self._GetTblIdx(inp)
        tblRem = PsiFixResize(inp, self.cfg.inFmt, self.remFmt)-2**(self.remFmt.I-1) #Invert MSB to have signed offset
        offsVal = self.offsTable[tblIdx]
        grad = self.gradTable[tblIdx]
        gradVal= PsiFixMult(grad, self.cfg.gradFmt,
                            tblRem, self.remFmt,
                            self.intFmt)
        addVal = PsiFixAdd(offsVal, self.cfg.offsFmt,
                           gradVal, self.intFmt,
                           self.addFmt, PsiFixRnd.Trunc, PsiFixSat.Wrap)
        output = PsiFixResize(addVal, self.addFmt,
                              self.cfg.outFmt, PsiFixRnd.Round, PsiFixSat.Sat)
        return output

    def Analyze(self, simPoints,
                simRange : tuple = None):
        """
        Analyze the performance of an approximation

        :param simPoints: Number of points to simulate
        :param simRange: Range of the values to simulate
        """
        #Run test
        if simRange is None:
            simRange = self.cfg.validRange
        input = PsiFixFromReal(np.linspace(simRange[0], simRange[1], simPoints), self.cfg.inFmt)
        actualOut = self.Approximate(input)
        expectedOut = self.cfg.function(input)
        #Analyze
        error = actualOut-expectedOut
        errorLSb = error*2**self.cfg.outFmt.F
        maxerr = max(abs(error))
        maxerrLsb = max(abs(errorLSb))
        print("maximum error: {} = {} LSB".format(maxerr, maxerrLsb))
        plt.figure(1)
        plt.subplot(211)
        plt.title("Output")
        plt.plot(input, expectedOut, 'b', label="expected")
        plt.plot(input, actualOut, 'r', label="actual")
        plt.legend()
        plt.subplot(212)
        plt.title("Error in LSB")
        plt.plot(input, errorLSb)
        plt.ylabel("Error [LSB]")
        plt.tight_layout(pad=2.0)
        plt.show()

    def GenerateEntity(self, path : str):
        """
        Generate VHDL implementation

        :param path: Path to write the generate code into
        """
        #Get values
        entityName = "psi_fix_lin_approx_" + self.cfg.name

        #Read template
        with open(self.SNIPPETS_PATH + "/psi_fix_lin_approx_tmpl.vhd", "r") as f:
            content = f.read()

        #Modify content
        content = content.replace("<ENTITY_NAME>", entityName)
        content = content.replace("<IN_WIDTH>", str(PsiFixSize(self.cfg.inFmt)))
        content = content.replace("<OUT_WIDTH>", str(PsiFixSize(self.cfg.outFmt)))
        content = content.replace("<IN_FMT>", str(self.cfg.inFmt))
        content = content.replace("<OUT_FMT>", str(self.cfg.outFmt))
        content = content.replace("<GRAD_FMT>", str(self.cfg.gradFmt))
        content = content.replace("<OFFS_FMT>", str(self.cfg.offsFmt))
        content = content.replace("<TABLE_SIZE>", str(self.cfg.points))
        content = content.replace("<TABLE_WIDTH>", str(PsiFixSize(self.cfg.gradFmt)+PsiFixSize(self.cfg.offsFmt)))

        #Offset Strings
        conv = "to_unsigned"
        if self.cfg.offsFmt.S == 1:
            conv = "to_signed"
        offsStr = ["{}({}, {})".format(conv,
                                       PsiFixGetBitsAsInt(v, self.cfg.offsFmt),
                                       PsiFixSize(self.cfg.offsFmt))
                   for v in self.offsTable]
        #Gradient Strings
        if self.cfg.gradFmt.S == 1:
            conv = "to_signed"
        gradStr = ["{}({}, {})".format(conv,
                                       PsiFixGetBitsAsInt(v, self.cfg.gradFmt),
                                       PsiFixSize(self.cfg.gradFmt))
                   for v in self.gradTable]
        tableLines = ["\t\tstd_logic_vector({} & {}),".format(g, o) for g, o in zip(gradStr, offsStr)]
        tableLines[-1] = tableLines[-1][:-1] #remove last comma
        tableLinesAll = "\n".join(tableLines)
        content = content.replace("<TABLE_CONTENT>", tableLinesAll)

        #write generated file
        with open(path + "/" + entityName + ".vhd", "w+") as f:
            f.write(content)

    def GenerateTb(self,    path : str,
                            simPoints : int = 10000,
                            simRange: tuple = None):
            """
            Generate a testbench for the approximation

            :param path: Path to write the TB and stimuli/response files to
            :param simPoints: Number of points to simulate
            :param simRange: Range of the values to simulate
            """
            # Get values
            entityName = "psi_fix_lin_approx_" + self.cfg.name

            # Run test
            if simRange is None:
                simRange = self.cfg.validRange
            input = PsiFixFromReal(np.linspace(simRange[0], simRange[1], simPoints), self.cfg.inFmt)
            actualOut = self.Approximate(input)

            # Read template
            with open(self.SNIPPETS_PATH + "/psi_fix_lin_approx_tb_tmpl.vhd", "r") as f:
                content = f.read()

            #Modify content
            content = content.replace("<ENTITY_NAME>", entityName)
            content = content.replace("<IN_FMT>", str(self.cfg.inFmt))
            content = content.replace("<OUT_FMT>", str(self.cfg.outFmt))

            # os
            try:
                os.mkdir(path)
            except FileExistsError:
                pass

            # write generated file
            with open(path + "/" + entityName + "_tb.vhd", "w+") as f:
                f.write(content)

            # write stimuli/response
            with open(path + "/" + "stimuli.txt", "w+") as f:
                f.writelines([str(i) + "\n" for i in PsiFixGetBitsAsInt(input, self.cfg.inFmt)])
            with open(path + "/" + "response.txt", "w+") as f:
                f.writelines([str(i) + "\n" for i in PsiFixGetBitsAsInt(actualOut, self.cfg.outFmt)])

    ####################################################################################################################
    # Private Methods (do not call!)
    ####################################################################################################################

    # Helper function to get the table index for a given input value
    def _GetTblIdx(self, inp):
        return PsiFixGetBitsAsInt(PsiFixResize(inp, self.cfg.inFmt, self.idxFmt), self.idxFmt)

########################################################################################################################
# Code to design a new filter
########################################################################################################################

#To design a new filter, uncomment the code below, replace the configuration with the new one to be optimized and run
#this file as script.

#psi_fix_lin_approx.Design(psi_fix_lin_approx.CONFIGS.Gaussify20Bit,simRange=(-0.99,0.99))
#exit()

########################################################################################################################
# Linear Approximation Bittrue Model and Code Generator
########################################################################################################################
#Generate all Code if executed as Main
if __name__ == "__main__":
    for cfg in psi_fix_lin_approx.CONFIGS.all:
        print("Generate HDL for: {}".format(cfg.name))
        app = psi_fix_lin_approx(cfg)
        app.GenerateEntity("../hdl")
        app.GenerateTb("../testbench/psi_fix_lin_approx_tb/" + cfg.name)







