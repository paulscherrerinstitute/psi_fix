########################################################################################################################
#  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
########################################################################################################################
import sys
sys.path.append("../model")
from psi_fix_pkg import *

import unittest

########################################################################################################################
# Test Cases
########################################################################################################################

### PsiFixSize ###
class PsiFixSizeTest(unittest.TestCase):

    def test_IntOnly_Unsiged_NoFractionalBits(self):
        self.assertEqual(3, PsiFixSize(PsiFixFmt(0, 3, 0)))

    def test_IntOnly_Signed_NoFractionalBits(self):
        self.assertEqual(4, PsiFixSize(PsiFixFmt(1, 3, 0)))

    def test_FractionalOnly_Unsigned_NoIntegerBits(self):
        self.assertEqual(3, PsiFixSize(PsiFixFmt(0, 0, 3)))

    def test_FractionalOnly_Signed_NoIntegerBits(self):
        self.assertEqual(4, PsiFixSize(PsiFixFmt(1, 0, 3)))

    def test_IntAndFract(self):
        self.assertEqual(7, PsiFixSize(PsiFixFmt(1, 3, 3)))

    def test_NegativeInt(self):
        self.assertEqual(2, PsiFixSize(PsiFixFmt(1, -2, 3)))

    def test_NegativeFract(self):
        self.assertEqual(2, PsiFixSize(PsiFixFmt(1, 3, -2)))

### PsiFixFromReal ###
class PsiFixFromRealTest(unittest.TestCase):

    def test_Rounding(self):
        self.assertEqual(1.25, PsiFixFromReal(1.2, PsiFixFmt(0, 2, 2)))
        self.assertEqual(-0.5, PsiFixFromReal(-0.52, PsiFixFmt(1, 2, 2)))

    def test_OutOfRangeError(self):
        with self.assertRaises(ValueError):
            PsiFixFromReal(4.2, PsiFixFmt(0, 2, 2))
        with self.assertRaises(ValueError):
            PsiFixFromReal(-0.5, PsiFixFmt(0, 2, 2))
        with self.assertRaises(ValueError):
            PsiFixFromReal(-4.2, PsiFixFmt(1, 2, 2))

    def test_OutOfRangeNoError(self):
        self.assertEqual(3.75, PsiFixFromReal(4.2, PsiFixFmt(0, 2, 2), False))
        self.assertEqual(0.0, PsiFixFromReal(-0.5, PsiFixFmt(0, 2, 2), False))
        self.assertEqual(-4.0, PsiFixFromReal(-4.2, PsiFixFmt(1, 2, 2), False))

    def test_LimitDueToRounding(self):
        with self.assertRaises(ValueError):
            PsiFixFromReal(3.9, PsiFixFmt(0, 2, 2))

### PsiFixFromBitsAsInt ###
class PsiFixFromBitsAsIntTest(unittest.TestCase):

    def test_Unsigned_Positive(self):
        self.assertEqual(1.5, PsiFixFromBitsAsInt(3, PsiFixFmt(0,3,1)))

    def test_Signed_Positive(self):
        self.assertEqual(1.5, PsiFixFromBitsAsInt(3, PsiFixFmt(1, 2, 1)))

    def test_Signed_Negative(self):
        self.assertEqual(-1.5, PsiFixFromBitsAsInt(-3, PsiFixFmt(1, 2, 1)))

    def test_Wrap_Unsigned(self):
        with self.assertRaises(ValueError):
            self.assertEqual(1, PsiFixFromBitsAsInt(17, PsiFixFmt(0, 4, 0)))

### PsiFixGetBitsAsInt ###
class PsiFixGetBitsAsIntTest(unittest.TestCase):

    def test_Unsigned_Positive(self):
        self.assertEqual(3, PsiFixGetBitsAsInt(1.5, PsiFixFmt(0, 3, 1)), PsiFixFmt(0, 3, 1))

    def test_Signed_Positive(self):
        self.assertEqual(3, PsiFixGetBitsAsInt(1.5, PsiFixFmt(1, 2, 1)), PsiFixFmt(1, 2, 1))

    def test_Signed_Negative(self):
        self.assertEqual(-3, PsiFixGetBitsAsInt(-1.5, PsiFixFmt(1, 2, 1)), PsiFixFmt(1, 2, 1))

### PsiFixResize ###
class PsiFixResizeTest(unittest.TestCase):

    def test_NoFormatChange(self):
        self.assertEqual(2.5, PsiFixResize(2.5, PsiFixFmt(1,2,1), PsiFixFmt(1,2,1)))

    def test_RemoveFracBit1_Trunc(self):
        self.assertEqual(2.0, PsiFixResize(2.5, PsiFixFmt(1,2,1), PsiFixFmt(1,2,0), PsiFixRnd.Trunc))

    def test_RemoveFracBit1_Round(self):
        self.assertEqual(3.0, PsiFixResize(2.5, PsiFixFmt(1, 2, 1), PsiFixFmt(1, 2, 0), PsiFixRnd.Round))

    def test_RemoveFracBit0_Trunc(self):
        self.assertEqual(2.0, PsiFixResize(2.0, PsiFixFmt(1,2,1), PsiFixFmt(1,2,0), PsiFixRnd.Trunc))

    def test_RemoveFracBit0_Round(self):
        self.assertEqual(2.0, PsiFixResize(2.0, PsiFixFmt(1,2,1), PsiFixFmt(1,2,0), PsiFixRnd.Round))

    def test_AddFracBit_Signed(self):
        self.assertEqual(2.0, PsiFixResize(2.0, PsiFixFmt(1,2,1), PsiFixFmt(1,2,2), PsiFixRnd.Round))

    def test_AddFracBit_Unsigned(self):
        self.assertEqual(2.0, PsiFixResize(2.0, PsiFixFmt(0,2,1), PsiFixFmt(0,2,2), PsiFixRnd.Round))

    def test_RemoveInterBit_Signed_NoSat_Positive(self):
        self.assertEqual(3.5, PsiFixResize(3.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveInterBit_Signed_NoSat_Negative(self):
        self.assertEqual(-3.5, PsiFixResize(-3.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_RemoveInterBit_Signed_Wrap_Positive(self):
        self.assertEqual(-2.5, PsiFixResize(5.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveInterBit_Signed_Wrap_Negative(self):
        self.assertEqual(1.5, PsiFixResize(-6.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveInterBit_Signed_Sat_Positive(self):
        self.assertEqual(3.5, PsiFixResize(5.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_RemoveInterBit_Signed_Sat_Negative(self):
        self.assertEqual(-4.0, PsiFixResize(-6.5, PsiFixFmt(1,3,1), PsiFixFmt(1,2,1), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_RemoveInterBit_Unsigned_NoSat_Positive(self):
        self.assertEqual(2.5, PsiFixResize(2.5, PsiFixFmt(0,3,1), PsiFixFmt(0,2,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveInterBit_Unsigned_Wrap_Positive(self):
        self.assertEqual(1.5, PsiFixResize(5.5, PsiFixFmt(0,3,1), PsiFixFmt(0,2,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveInterBit_Unsigned_Sat_Positive(self):
        self.assertEqual(3.5, PsiFixResize(5.5, PsiFixFmt(0,3,1), PsiFixFmt(0,2,1), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_RemoveSignBit_Signed_NoSat_Positive(self):
        self.assertEqual(3.5, PsiFixResize(3.5, PsiFixFmt(1,3,1), PsiFixFmt(0,3,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveSignBit_Signed_Wrap_Negative(self):
        self.assertEqual(1.5, PsiFixResize(-6.5, PsiFixFmt(1,3,1), PsiFixFmt(0,3,1), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_RemoveSignBit_Signed_Sat_Negative(self):
        self.assertEqual(0.0, PsiFixResize(-6.5, PsiFixFmt(1,3,1), PsiFixFmt(0,3,1), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_OverflowDueRounding_Signed_Wrap(self):
        self.assertEqual(-8.0, PsiFixResize(7.5, PsiFixFmt(1,3,1), PsiFixFmt(1,3,0), PsiFixRnd.Round, PsiFixSat.Wrap))

    def test_OverflowDueRounding_Signed_Sat(self):
        self.assertEqual(7.0, PsiFixResize(7.5, PsiFixFmt(1,3,1), PsiFixFmt(1,3,0), PsiFixRnd.Round, PsiFixSat.Sat))

    def test_OverflowDueRounding_Unsigned_Wrap(self):
        self.assertEqual(0.0, PsiFixResize(7.5, PsiFixFmt(0,3,1), PsiFixFmt(0,3,0), PsiFixRnd.Round, PsiFixSat.Wrap))

    def test_OverflowDueRounding_Unsigned_Sat(self):
        self.assertEqual(7.0, PsiFixResize(7.5, PsiFixFmt(0,3,1), PsiFixFmt(0,3,0), PsiFixRnd.Round, PsiFixSat.Sat))

### PsiFixAdd ###
class PsiFixAddTest(unittest.TestCase):

    def test_SameFmt_Signed(self):
        self.assertEqual(
            -2.5+1.25,
            PsiFixAdd(  -2.5, PsiFixFmt(1,5,3),
                        1.25, PsiFixFmt(1,5,3),
                        PsiFixFmt(1,5,3)))

    def test_SameFmt_Unigned(self):
        self.assertEqual(
            2.5 + 1.25,
            PsiFixAdd(2.5, PsiFixFmt(0, 5, 3),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffIntBits_Signed(self):
        self.assertEqual(
            -2.5 + 1.25,
            PsiFixAdd(-2.5, PsiFixFmt(1, 6, 3),
                      1.25, PsiFixFmt(1, 5, 3),
                      PsiFixFmt(1, 5, 3)))

    def test_DiffIntBits_Unsigned(self):
        self.assertEqual(
            2.5 + 1.25,
            PsiFixAdd(2.5, PsiFixFmt(0, 6, 3),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffFracBits_Signed(self):
        self.assertEqual(
            -2.5 + 1.25,
            PsiFixAdd(-2.5, PsiFixFmt(1, 5, 4),
                      1.25, PsiFixFmt(1, 5, 3),
                      PsiFixFmt(1, 5, 3)))

    def test_DiffFracBits_Unsigned(self):
        self.assertEqual(
            2.5 + 1.25,
            PsiFixAdd(2.5, PsiFixFmt(0, 5, 4),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffRanges_Unsigned(self):
        self.assertEqual(
            0.75 + 4.0,
            PsiFixAdd(0.75, PsiFixFmt(0, 0, 4),
                      4.0, PsiFixFmt(0, 4, -1),
                      PsiFixFmt(0, 5, 5)))

    def test_Round(self):
        self.assertEqual(
            5.0,
            PsiFixAdd(0.75, PsiFixFmt(0, 0, 4),
                      4.0, PsiFixFmt(0, 4, -1),
                      PsiFixFmt(0, 5, 0), PsiFixRnd.Round))

    def test_Saturate(self):
        self.assertEqual(
            15.0,
            PsiFixAdd(0.75, PsiFixFmt(0, 0, 4),
                      15.0, PsiFixFmt(0, 4, 0),
                      PsiFixFmt(0, 4, 0), PsiFixRnd.Round, PsiFixSat.Sat))

### PsiFixSub ###
class PsiFixSubTest(unittest.TestCase):
    def test_SameFmt_Signed(self):
        self.assertEqual(
            -2.5-1.25,
            PsiFixSub(-2.5, PsiFixFmt(1,5,3),
                      1.25, PsiFixFmt(1,5,3),
                      PsiFixFmt(1,5,3)))

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            PsiFixSub(2.5, PsiFixFmt(0, 5, 3),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffIntBits_Signed(self):
        self.assertEqual(
            -2.5 - 1.25,
            PsiFixSub(-2.5, PsiFixFmt(1, 6, 3),
                      1.25, PsiFixFmt(1, 5, 3),
                      PsiFixFmt(1, 5, 3)))

    def test_DiffIntBits_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            PsiFixSub(2.5, PsiFixFmt(0, 6, 3),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffFracBits_Signed(self):
        self.assertEqual(
            -2.5 - 1.25,
            PsiFixSub(-2.5, PsiFixFmt(1, 5, 4),
                      1.25, PsiFixFmt(1, 5, 3),
                      PsiFixFmt(1, 5, 3)))

    def test_DiffFracBits_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            PsiFixSub(2.5, PsiFixFmt(0, 5, 4),
                      1.25, PsiFixFmt(0, 5, 3),
                      PsiFixFmt(0, 5, 3)))

    def test_DiffRanges_Unsigned(self):
        self.assertEqual(
            4.0 - 0.75,
            PsiFixSub(4.0, PsiFixFmt(0, 4, -1),
                      0.75, PsiFixFmt(0, 0, 4),
                      PsiFixFmt(0, 5, 5)))

    def test_Round(self):
        self.assertEqual(
            4.0,
            PsiFixSub(4.0, PsiFixFmt(0, 4, -1),
                      0.25, PsiFixFmt(0, 0, 4),
                      PsiFixFmt(0, 5, 0), PsiFixRnd.Round))

    def test_Saturate(self):
        self.assertEqual(
            0.0,
            PsiFixSub(0.75, PsiFixFmt(0, 0, 4),
                      5.0, PsiFixFmt(0, 4, 0),
                      PsiFixFmt(0, 4, 0), PsiFixRnd.Round, PsiFixSat.Sat))

    def test_InvertMostNegative_Signed_NoSat(self):
        self.assertEqual(
            -16.0,
            PsiFixSub(0.0, PsiFixFmt(1, 4, 0),
                      -16, PsiFixFmt(1, 4, 0),
                      PsiFixFmt(1, 4, 0), PsiFixRnd.Round, PsiFixSat.Wrap))

    def test_InvertMostNegative_Signed_Sat(self):
        self.assertEqual(
            15.0,
            PsiFixSub(0.0, PsiFixFmt(1, 4, 0),
                      -16, PsiFixFmt(1, 4, 0),
                      PsiFixFmt(1, 4, 0), PsiFixRnd.Round, PsiFixSat.Sat))

    def test_InvertMostNegative_Unsigned_NoSat(self):
        self.assertEqual(
            0.0,
            PsiFixSub(0.0, PsiFixFmt(0, 4, 0),
                      -16, PsiFixFmt(0, 4, 0),
                      PsiFixFmt(0, 4, 0), PsiFixRnd.Round, PsiFixSat.Wrap))

    def test_InvertUnsigned_Sat(self):
        self.assertEqual(
            0.0,
            PsiFixSub(0.0, PsiFixFmt(0, 4, 0),
                      15.0, PsiFixFmt(0, 4, 0),
                      PsiFixFmt(0, 4, 0), PsiFixRnd.Round, PsiFixSat.Sat))

### PsiFixMult ###
class PsiFixMultTest(unittest.TestCase):
    def test_AUnsignedPos_BUnsignedPos(self):
        self.assertEqual(
            2.5*1.25,
            PsiFixMult(2.5, PsiFixFmt(0, 5, 1),
                      1.25, PsiFixFmt(0, 5, 2),
                      PsiFixFmt(0, 5, 5)))

    def test_ASignedPos_BSignedPos(self):
        self.assertEqual(
            2.5 * 1.25,
            PsiFixMult(2.5, PsiFixFmt(1, 2, 1),
                       1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_ASignedPos_BSignedNeg(self):
        self.assertEqual(
            2.5 * (-1.25),
            PsiFixMult(2.5, PsiFixFmt(1, 2, 1),
                       -1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_ASignedNeg_BSignedPos(self):
        self.assertEqual(
            (-2.5) * 1.25,
            PsiFixMult(-2.5, PsiFixFmt(1, 2, 1),
                       1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_ASignedNeg_BSignedNeg(self):
        self.assertEqual(
            (-2.5) * (-1.25),
            PsiFixMult(-2.5, PsiFixFmt(1, 2, 1),
                       -1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_AUnsignedPos_BSignedPos(self):
        self.assertEqual(
            2.5 * 1.25,
            PsiFixMult(2.5, PsiFixFmt(0, 2, 1),
                       1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_AUnsignedPos_BSignedNeg(self):
        self.assertEqual(
            2.5 * (-1.25),
            PsiFixMult(2.5, PsiFixFmt(0, 2, 1),
                       -1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(1, 3, 3)))

    def test_AUnsignedPos_BSignedPos_ResultUnsigned(self):
        self.assertEqual(
            2.5 * 1.25,
            PsiFixMult(2.5, PsiFixFmt(0, 2, 1),
                       1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(0, 3, 3)))

    def test_AUnsignedPos_BSignedPos_Saturate(self):
        self.assertEqual(
            1.875,
            PsiFixMult(2.5, PsiFixFmt(0, 2, 1),
                       1.25, PsiFixFmt(1, 1, 2),
                       PsiFixFmt(0, 1, 3), PsiFixRnd.Trunc, PsiFixSat.Sat))

### PsiFixAbs ###
class PsiFixAbsTest(unittest.TestCase):

    def test_Positive_Stay_Positive(self):
        self.assertEqual(2.5, PsiFixAbs(2.5, PsiFixFmt(0,5,1), PsiFixFmt(0,5,1)))

    def test_Negative_Becomes_Positive(self):
        self.assertEqual(4.0, PsiFixAbs(-4.0, PsiFixFmt(1, 2, 2), PsiFixFmt(1, 3, 3)))

    def test_Most_Negative_Value_Sat(self):
        self.assertEqual(3.75, PsiFixAbs(-4.0, PsiFixFmt(1, 2, 2), PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

### PsiFixNeg ###
class PsiFixNegTest(unittest.TestCase):

    def test_PositiveToNegative_SignedToSigned(self):
        self.assertEqual(-2.5, PsiFixNeg(2.5, PsiFixFmt(1,5,1), PsiFixFmt(1,5,5)))

    def test_PositiveToNegative_UnsignedToSigned(self):
        self.assertEqual(-2.5, PsiFixNeg(2.5, PsiFixFmt(0, 5, 1), PsiFixFmt(1, 5, 5)))

    def test_NegativeToPositive_SignedToSigned(self):
        self.assertEqual(2.5, PsiFixNeg(-2.5, PsiFixFmt(1, 5, 1), PsiFixFmt(1, 5, 5)))

    def test_NegativeToPositive_SignedToUnsigned(self):
        self.assertEqual(2.5, PsiFixNeg(-2.5, PsiFixFmt(1, 5, 1), PsiFixFmt(0, 5, 5)))

    def test_Saturation_SignedToSigned(self):
        self.assertEqual(3.75, PsiFixNeg(-4.0, PsiFixFmt(1, 2, 4), PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_Wrap_SignedToSigned(self):
        self.assertEqual(-4.0, PsiFixNeg(-4.0, PsiFixFmt(1, 2, 4), PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_PosToNegSaturate_SignedToUnsigned(self):
        self.assertEqual(0.0, PsiFixNeg(2.5, PsiFixFmt(1, 5, 1), PsiFixFmt(0, 5, 5), PsiFixRnd.Trunc, PsiFixSat.Sat))

### PsiFixShiftLeft ###
class PsiFixShiftLeftTest(unittest.TestCase):

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            2.5,
            PsiFixShiftLeft(1.25, PsiFixFmt(0,3,2),
                            1, 10,
                            PsiFixFmt(0,3,2)))

    def test_SameFmt_Signed(self):
        self.assertEqual(
            2.5,
            PsiFixShiftLeft(1.25, PsiFixFmt(1, 3, 2),
                            1, 10,
                            PsiFixFmt(1, 3, 2)))

    def test_FmtChange(self):
        self.assertEqual(
            2.5,
            PsiFixShiftLeft(1.25, PsiFixFmt(1, 1, 2),
                            1, 10,
                            PsiFixFmt(0, 3, 2)))

    def test_Saturation_Signed(self):
        self.assertEqual(
            3.75,
            PsiFixShiftLeft(2.0, PsiFixFmt(1, 2, 2),
                            1, 10,
                            PsiFixFmt(0, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_Saturation_UnsignedToSigned(self):
        self.assertEqual(
            3.75,
            PsiFixShiftLeft(2.0, PsiFixFmt(0, 3, 2),
                            1, 10,
                            PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_Saturation_SignedToUnsigned(self):
        self.assertEqual(
            0.0,
            PsiFixShiftLeft(-0.5, PsiFixFmt(1, 3, 2),
                            1, 10,
                            PsiFixFmt(0, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_Wrap_Signed(self):
        self.assertEqual(
            -4.0,
            PsiFixShiftLeft(2.0, PsiFixFmt(1, 2, 2),
                            1, 10,
                            PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Wrap_UnsignedToSigned(self):
        self.assertEqual(
            -4.0,
            PsiFixShiftLeft(2.0, PsiFixFmt(0, 3, 2),
                            1, 10,
                            PsiFixFmt(1, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Wrap_SignedToUnsigned(self):
        self.assertEqual(
            3.0,
            PsiFixShiftLeft(-0.5, PsiFixFmt(1, 3, 2),
                            1, 10,
                            PsiFixFmt(0, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Shift0(self):
        self.assertEqual(
            0.5,
            PsiFixShiftLeft(0.5, PsiFixFmt(1, 5, 5),
                            0, 10,
                            PsiFixFmt(1, 5, 5), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Shift3(self):
        self.assertEqual(
            -4.0,
            PsiFixShiftLeft(-0.5, PsiFixFmt(1, 5, 5),
                            3, 10,
                            PsiFixFmt(1, 5, 5), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Error_NegativeShift(self):
        with self.assertRaises(ValueError):
            PsiFixShiftLeft(0.0, PsiFixFmt(1,5,5), -1, 10, PsiFixFmt(1,5,5))

    def test_Error_ShiftOutOfRange(self):
        with self.assertRaises(ValueError):
            PsiFixShiftLeft(0.0, PsiFixFmt(1,5,5), 11, 10, PsiFixFmt(1,5,5))

### PsiFixShiftRight ###
class PsiFixShiftRightTest(unittest.TestCase):

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            1.25,
            PsiFixShiftRight(2.5, PsiFixFmt(0, 3, 2),
                            1, 10,
                            PsiFixFmt(0, 3, 2)))

    def test_SameFmt_Signed(self):
        self.assertEqual(
            1.25,
            PsiFixShiftRight(2.5, PsiFixFmt(1, 3, 2),
                             1, 10,
                             PsiFixFmt(1, 3, 2)))

    def test_FmtChange(self):
        self.assertEqual(
            1.25,
            PsiFixShiftRight(2.5, PsiFixFmt(0, 3, 2),
                             1, 10,
                             PsiFixFmt(1, 1, 2)))

    def test_Saturation_SignedToUnsigned(self):
        self.assertEqual(
            0.0,
            PsiFixShiftRight(-0.5, PsiFixFmt(1, 3, 2),
                             1, 10,
                             PsiFixFmt(0, 2, 2), PsiFixRnd.Trunc, PsiFixSat.Sat))

    def test_Saturation_Shift0(self):
        self.assertEqual(
            0.5,
            PsiFixShiftRight(0.5, PsiFixFmt(1, 5, 5),
                             0, 10,
                             PsiFixFmt(1, 5, 5), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Saturation_Shift3(self):
        self.assertEqual(
            -0.5,
            PsiFixShiftRight(-4.0, PsiFixFmt(1, 5, 5),
                             3, 10,
                             PsiFixFmt(1, 5, 5), PsiFixRnd.Trunc, PsiFixSat.Wrap))

    def test_Error_NegativeShift(self):
        with self.assertRaises(ValueError):
            PsiFixShiftRight(0.0, PsiFixFmt(1,5,5), -1, 10, PsiFixFmt(1,5,5))

    def test_Error_ShiftOutOfRange(self):
        with self.assertRaises(ValueError):
            PsiFixShiftRight(0.0, PsiFixFmt(1,5,5), 11, 10, PsiFixFmt(1,5,5))

### PsiFixUpperBound ###
class PsiFixUpperBoundTest(unittest.TestCase):

    def test_Unsigned(self):
        self.assertEqual(3.75, PsiFixUpperBound(PsiFixFmt(0,2,2)))

    def test_Signed(self):
        self.assertEqual(1.75, PsiFixUpperBound(PsiFixFmt(1, 1, 2)))

### PsiFixLowerBound ###
class PsiFixLowerBoundTest(unittest.TestCase):
    def test_Unsigned(self):
        self.assertEqual(0.0, PsiFixLowerBound(PsiFixFmt(0, 2, 2)))

    def test_Signed(self):
        self.assertEqual(-2.0, PsiFixLowerBound(PsiFixFmt(1, 1, 2)))

### PsiFixInRange ###
class PsiFixInRangeTest(unittest.TestCase):

    def test_InRangeNormal(self):
        self.assertEqual(True, PsiFixInRange(1.25, PsiFixFmt(1,4,2), PsiFixFmt(1,2,4), PsiFixRnd.Trunc))

    def test_OutRangeNormal(self):
        self.assertEqual(False, PsiFixInRange(6.25, PsiFixFmt(1,4,2), PsiFixFmt(1,2,4), PsiFixRnd.Trunc))

    def test_SignedUnsigned_OutRange(self):
        self.assertEqual(False, PsiFixInRange(-1.25, PsiFixFmt(1,4,2), PsiFixFmt(0,5,2), PsiFixRnd.Trunc))

    def test_UnsignedSigned_OutRange(self):
        self.assertEqual(False, PsiFixInRange(15.0, PsiFixFmt(0,4,2), PsiFixFmt(1,3,2), PsiFixRnd.Trunc))

    def test_UnsignedSigned_InRange(self):
        self.assertEqual(True, PsiFixInRange(15.0, PsiFixFmt(0,4,2), PsiFixFmt(1,4,2), PsiFixRnd.Trunc))

    def test_Rounding_OutRange(self):
        self.assertEqual(False, PsiFixInRange(15.5, PsiFixFmt(0,4,2), PsiFixFmt(1,4,0), PsiFixRnd.Round))

    def test_Rounding_InRange1(self):
        self.assertEqual(True, PsiFixInRange(15.5, PsiFixFmt(0,4,2), PsiFixFmt(1,4,1), PsiFixRnd.Round))

    def test_Rounding_InRange2(self):
        self.assertEqual(True, PsiFixInRange(15.5, PsiFixFmt(0,4,2), PsiFixFmt(0,5,0), PsiFixRnd.Round))

########################################################################################################################
# Test Runner
########################################################################################################################
if __name__ == "__main__":
    unittest.main()




