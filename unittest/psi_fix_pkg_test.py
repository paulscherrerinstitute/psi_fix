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

### psi_fix_size ###
class PsiFixSizeTest(unittest.TestCase):

    def test_IntOnly_Unsiged_NoFractionalBits(self):
        self.assertEqual(3, psi_fix_size(psi_fix_fmt_t(0, 3, 0)))

    def test_IntOnly_Signed_NoFractionalBits(self):
        self.assertEqual(4, psi_fix_size(psi_fix_fmt_t(1, 3, 0)))

    def test_FractionalOnly_Unsigned_NoIntegerBits(self):
        self.assertEqual(3, psi_fix_size(psi_fix_fmt_t(0, 0, 3)))

    def test_FractionalOnly_Signed_NoIntegerBits(self):
        self.assertEqual(4, psi_fix_size(psi_fix_fmt_t(1, 0, 3)))

    def test_IntAndFract(self):
        self.assertEqual(7, psi_fix_size(psi_fix_fmt_t(1, 3, 3)))

    def test_NegativeInt(self):
        self.assertEqual(2, psi_fix_size(psi_fix_fmt_t(1, -2, 3)))

    def test_NegativeFract(self):
        self.assertEqual(2, psi_fix_size(psi_fix_fmt_t(1, 3, -2)))

### psi_fix_from_real ###
class PsiFixFromRealTest(unittest.TestCase):

    def test_Rounding(self):
        self.assertEqual(1.25, psi_fix_from_real(1.2, psi_fix_fmt_t(0, 2, 2)))
        self.assertEqual(-0.5, psi_fix_from_real(-0.52, psi_fix_fmt_t(1, 2, 2)))

    def test_OutOfRangeError(self):
        with self.assertRaises(ValueError):
            psi_fix_from_real(4.2, psi_fix_fmt_t(0, 2, 2))
        with self.assertRaises(ValueError):
            psi_fix_from_real(-0.5, psi_fix_fmt_t(0, 2, 2))
        with self.assertRaises(ValueError):
            psi_fix_from_real(-4.2, psi_fix_fmt_t(1, 2, 2))

    def test_OutOfRangeNoError(self):
        self.assertEqual(3.75, psi_fix_from_real(4.2, psi_fix_fmt_t(0, 2, 2), False))
        self.assertEqual(0.0, psi_fix_from_real(-0.5, psi_fix_fmt_t(0, 2, 2), False))
        self.assertEqual(-4.0, psi_fix_from_real(-4.2, psi_fix_fmt_t(1, 2, 2), False))

    def test_LimitDueToRounding(self):
        with self.assertRaises(ValueError):
            psi_fix_from_real(3.9, psi_fix_fmt_t(0, 2, 2))

### psi_fix_from_bits_as_int ###
class PsiFixFromBitsAsIntTest(unittest.TestCase):

    def test_Unsigned_Positive(self):
        self.assertEqual(1.5, psi_fix_from_bits_as_int(3, psi_fix_fmt_t(0,3,1)))

    def test_Signed_Positive(self):
        self.assertEqual(1.5, psi_fix_from_bits_as_int(3, psi_fix_fmt_t(1, 2, 1)))

    def test_Signed_Negative(self):
        self.assertEqual(-1.5, psi_fix_from_bits_as_int(-3, psi_fix_fmt_t(1, 2, 1)))

    def test_Wrap_Unsigned(self):
        with self.assertRaises(ValueError):
            self.assertEqual(1, psi_fix_from_bits_as_int(17, psi_fix_fmt_t(0, 4, 0)))

### psi_fix_get_bits_as_int ###
class PsiFixGetBitsAsIntTest(unittest.TestCase):

    def test_Unsigned_Positive(self):
        self.assertEqual(3, psi_fix_get_bits_as_int(1.5, psi_fix_fmt_t(0, 3, 1)), psi_fix_fmt_t(0, 3, 1))

    def test_Signed_Positive(self):
        self.assertEqual(3, psi_fix_get_bits_as_int(1.5, psi_fix_fmt_t(1, 2, 1)), psi_fix_fmt_t(1, 2, 1))

    def test_Signed_Negative(self):
        self.assertEqual(-3, psi_fix_get_bits_as_int(-1.5, psi_fix_fmt_t(1, 2, 1)), psi_fix_fmt_t(1, 2, 1))

### psi_fix_resize ###
class PsiFixResizeTest(unittest.TestCase):

    def test_NoFormatChange(self):
        self.assertEqual(2.5, psi_fix_resize(2.5, psi_fix_fmt_t(1,2,1), psi_fix_fmt_t(1,2,1)))

    def test_RemoveFracBit1_Trunc(self):
        self.assertEqual(2.0, psi_fix_resize(2.5, psi_fix_fmt_t(1,2,1), psi_fix_fmt_t(1,2,0), psi_fix_rnd_t.trunc))

    def test_RemoveFracBit1_Round(self):
        self.assertEqual(3.0, psi_fix_resize(2.5, psi_fix_fmt_t(1, 2, 1), psi_fix_fmt_t(1, 2, 0), psi_fix_rnd_t.round))

    def test_RemoveFracBit0_Trunc(self):
        self.assertEqual(2.0, psi_fix_resize(2.0, psi_fix_fmt_t(1,2,1), psi_fix_fmt_t(1,2,0), psi_fix_rnd_t.trunc))

    def test_RemoveFracBit0_Round(self):
        self.assertEqual(2.0, psi_fix_resize(2.0, psi_fix_fmt_t(1,2,1), psi_fix_fmt_t(1,2,0), psi_fix_rnd_t.round))

    def test_AddFracBit_Signed(self):
        self.assertEqual(2.0, psi_fix_resize(2.0, psi_fix_fmt_t(1,2,1), psi_fix_fmt_t(1,2,2), psi_fix_rnd_t.round))

    def test_AddFracBit_Unsigned(self):
        self.assertEqual(2.0, psi_fix_resize(2.0, psi_fix_fmt_t(0,2,1), psi_fix_fmt_t(0,2,2), psi_fix_rnd_t.round))

    def test_RemoveInterBit_Signed_NoSat_Positive(self):
        self.assertEqual(3.5, psi_fix_resize(3.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveInterBit_Signed_NoSat_Negative(self):
        self.assertEqual(-3.5, psi_fix_resize(-3.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_RemoveInterBit_Signed_Wrap_Positive(self):
        self.assertEqual(-2.5, psi_fix_resize(5.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveInterBit_Signed_Wrap_Negative(self):
        self.assertEqual(1.5, psi_fix_resize(-6.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveInterBit_Signed_Sat_Positive(self):
        self.assertEqual(3.5, psi_fix_resize(5.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_RemoveInterBit_Signed_Sat_Negative(self):
        self.assertEqual(-4.0, psi_fix_resize(-6.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_RemoveInterBit_Unsigned_NoSat_Positive(self):
        self.assertEqual(2.5, psi_fix_resize(2.5, psi_fix_fmt_t(0,3,1), psi_fix_fmt_t(0,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveInterBit_Unsigned_Wrap_Positive(self):
        self.assertEqual(1.5, psi_fix_resize(5.5, psi_fix_fmt_t(0,3,1), psi_fix_fmt_t(0,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveInterBit_Unsigned_Sat_Positive(self):
        self.assertEqual(3.5, psi_fix_resize(5.5, psi_fix_fmt_t(0,3,1), psi_fix_fmt_t(0,2,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_RemoveSignBit_Signed_NoSat_Positive(self):
        self.assertEqual(3.5, psi_fix_resize(3.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(0,3,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveSignBit_Signed_Wrap_Negative(self):
        self.assertEqual(1.5, psi_fix_resize(-6.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(0,3,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_RemoveSignBit_Signed_Sat_Negative(self):
        self.assertEqual(0.0, psi_fix_resize(-6.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(0,3,1), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_OverflowDueRounding_Signed_Wrap(self):
        self.assertEqual(-8.0, psi_fix_resize(7.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,3,0), psi_fix_rnd_t.round, psi_fix_sat_t.wrap))

    def test_OverflowDueRounding_Signed_Sat(self):
        self.assertEqual(7.0, psi_fix_resize(7.5, psi_fix_fmt_t(1,3,1), psi_fix_fmt_t(1,3,0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

    def test_OverflowDueRounding_Unsigned_Wrap(self):
        self.assertEqual(0.0, psi_fix_resize(7.5, psi_fix_fmt_t(0,3,1), psi_fix_fmt_t(0,3,0), psi_fix_rnd_t.round, psi_fix_sat_t.wrap))

    def test_OverflowDueRounding_Unsigned_Sat(self):
        self.assertEqual(7.0, psi_fix_resize(7.5, psi_fix_fmt_t(0,3,1), psi_fix_fmt_t(0,3,0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

### psi_fix_add ###
class PsiFixAddTest(unittest.TestCase):

    def test_SameFmt_Signed(self):
        self.assertEqual(
            -2.5+1.25,
            psi_fix_add(  -2.5, psi_fix_fmt_t(1,5,3),
                        1.25, psi_fix_fmt_t(1,5,3),
                        psi_fix_fmt_t(1,5,3)))

    def test_SameFmt_Unigned(self):
        self.assertEqual(
            2.5 + 1.25,
            psi_fix_add(2.5, psi_fix_fmt_t(0, 5, 3),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffIntBits_Signed(self):
        self.assertEqual(
            -2.5 + 1.25,
            psi_fix_add(-2.5, psi_fix_fmt_t(1, 6, 3),
                      1.25, psi_fix_fmt_t(1, 5, 3),
                      psi_fix_fmt_t(1, 5, 3)))

    def test_DiffIntBits_Unsigned(self):
        self.assertEqual(
            2.5 + 1.25,
            psi_fix_add(2.5, psi_fix_fmt_t(0, 6, 3),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffFracBits_Signed(self):
        self.assertEqual(
            -2.5 + 1.25,
            psi_fix_add(-2.5, psi_fix_fmt_t(1, 5, 4),
                      1.25, psi_fix_fmt_t(1, 5, 3),
                      psi_fix_fmt_t(1, 5, 3)))

    def test_DiffFracBits_Unsigned(self):
        self.assertEqual(
            2.5 + 1.25,
            psi_fix_add(2.5, psi_fix_fmt_t(0, 5, 4),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffRanges_Unsigned(self):
        self.assertEqual(
            0.75 + 4.0,
            psi_fix_add(0.75, psi_fix_fmt_t(0, 0, 4),
                      4.0, psi_fix_fmt_t(0, 4, -1),
                      psi_fix_fmt_t(0, 5, 5)))

    def test_Round(self):
        self.assertEqual(
            5.0,
            psi_fix_add(0.75, psi_fix_fmt_t(0, 0, 4),
                      4.0, psi_fix_fmt_t(0, 4, -1),
                      psi_fix_fmt_t(0, 5, 0), psi_fix_rnd_t.round))

    def test_Saturate(self):
        self.assertEqual(
            15.0,
            psi_fix_add(0.75, psi_fix_fmt_t(0, 0, 4),
                      15.0, psi_fix_fmt_t(0, 4, 0),
                      psi_fix_fmt_t(0, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

### psi_fix_sub ###
class PsiFixSubTest(unittest.TestCase):
    def test_SameFmt_Signed(self):
        self.assertEqual(
            -2.5-1.25,
            psi_fix_sub(-2.5, psi_fix_fmt_t(1,5,3),
                      1.25, psi_fix_fmt_t(1,5,3),
                      psi_fix_fmt_t(1,5,3)))

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            psi_fix_sub(2.5, psi_fix_fmt_t(0, 5, 3),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffIntBits_Signed(self):
        self.assertEqual(
            -2.5 - 1.25,
            psi_fix_sub(-2.5, psi_fix_fmt_t(1, 6, 3),
                      1.25, psi_fix_fmt_t(1, 5, 3),
                      psi_fix_fmt_t(1, 5, 3)))

    def test_DiffIntBits_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            psi_fix_sub(2.5, psi_fix_fmt_t(0, 6, 3),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffFracBits_Signed(self):
        self.assertEqual(
            -2.5 - 1.25,
            psi_fix_sub(-2.5, psi_fix_fmt_t(1, 5, 4),
                      1.25, psi_fix_fmt_t(1, 5, 3),
                      psi_fix_fmt_t(1, 5, 3)))

    def test_DiffFracBits_Unsigned(self):
        self.assertEqual(
            2.5 - 1.25,
            psi_fix_sub(2.5, psi_fix_fmt_t(0, 5, 4),
                      1.25, psi_fix_fmt_t(0, 5, 3),
                      psi_fix_fmt_t(0, 5, 3)))

    def test_DiffRanges_Unsigned(self):
        self.assertEqual(
            4.0 - 0.75,
            psi_fix_sub(4.0, psi_fix_fmt_t(0, 4, -1),
                      0.75, psi_fix_fmt_t(0, 0, 4),
                      psi_fix_fmt_t(0, 5, 5)))

    def test_Round(self):
        self.assertEqual(
            4.0,
            psi_fix_sub(4.0, psi_fix_fmt_t(0, 4, -1),
                      0.25, psi_fix_fmt_t(0, 0, 4),
                      psi_fix_fmt_t(0, 5, 0), psi_fix_rnd_t.round))

    def test_Saturate(self):
        self.assertEqual(
            0.0,
            psi_fix_sub(0.75, psi_fix_fmt_t(0, 0, 4),
                      5.0, psi_fix_fmt_t(0, 4, 0),
                      psi_fix_fmt_t(0, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

    def test_InvertMostNegative_Signed_NoSat(self):
        self.assertEqual(
            -16.0,
            psi_fix_sub(0.0, psi_fix_fmt_t(1, 4, 0),
                      -16, psi_fix_fmt_t(1, 4, 0),
                      psi_fix_fmt_t(1, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.wrap))

    def test_InvertMostNegative_Signed_Sat(self):
        self.assertEqual(
            15.0,
            psi_fix_sub(0.0, psi_fix_fmt_t(1, 4, 0),
                      -16, psi_fix_fmt_t(1, 4, 0),
                      psi_fix_fmt_t(1, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

    def test_InvertMostNegative_Unsigned_NoSat(self):
        self.assertEqual(
            0.0,
            psi_fix_sub(0.0, psi_fix_fmt_t(0, 4, 0),
                      -16, psi_fix_fmt_t(0, 4, 0),
                      psi_fix_fmt_t(0, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.wrap))

    def test_InvertUnsigned_Sat(self):
        self.assertEqual(
            0.0,
            psi_fix_sub(0.0, psi_fix_fmt_t(0, 4, 0),
                      15.0, psi_fix_fmt_t(0, 4, 0),
                      psi_fix_fmt_t(0, 4, 0), psi_fix_rnd_t.round, psi_fix_sat_t.sat))

### psi_fix_mult ###
class PsiFixMultTest(unittest.TestCase):
    def test_AUnsignedPos_BUnsignedPos(self):
        self.assertEqual(
            2.5*1.25,
            psi_fix_mult(2.5, psi_fix_fmt_t(0, 5, 1),
                      1.25, psi_fix_fmt_t(0, 5, 2),
                      psi_fix_fmt_t(0, 5, 5)))

    def test_ASignedPos_BSignedPos(self):
        self.assertEqual(
            2.5 * 1.25,
            psi_fix_mult(2.5, psi_fix_fmt_t(1, 2, 1),
                       1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_ASignedPos_BSignedNeg(self):
        self.assertEqual(
            2.5 * (-1.25),
            psi_fix_mult(2.5, psi_fix_fmt_t(1, 2, 1),
                       -1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_ASignedNeg_BSignedPos(self):
        self.assertEqual(
            (-2.5) * 1.25,
            psi_fix_mult(-2.5, psi_fix_fmt_t(1, 2, 1),
                       1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_ASignedNeg_BSignedNeg(self):
        self.assertEqual(
            (-2.5) * (-1.25),
            psi_fix_mult(-2.5, psi_fix_fmt_t(1, 2, 1),
                       -1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_AUnsignedPos_BSignedPos(self):
        self.assertEqual(
            2.5 * 1.25,
            psi_fix_mult(2.5, psi_fix_fmt_t(0, 2, 1),
                       1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_AUnsignedPos_BSignedNeg(self):
        self.assertEqual(
            2.5 * (-1.25),
            psi_fix_mult(2.5, psi_fix_fmt_t(0, 2, 1),
                       -1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(1, 3, 3)))

    def test_AUnsignedPos_BSignedPos_ResultUnsigned(self):
        self.assertEqual(
            2.5 * 1.25,
            psi_fix_mult(2.5, psi_fix_fmt_t(0, 2, 1),
                       1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(0, 3, 3)))

    def test_AUnsignedPos_BSignedPos_Saturate(self):
        self.assertEqual(
            1.875,
            psi_fix_mult(2.5, psi_fix_fmt_t(0, 2, 1),
                       1.25, psi_fix_fmt_t(1, 1, 2),
                       psi_fix_fmt_t(0, 1, 3), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

### psi_fix_abs ###
class PsiFixAbsTest(unittest.TestCase):

    def test_Positive_Stay_Positive(self):
        self.assertEqual(2.5, psi_fix_abs(2.5, psi_fix_fmt_t(0,5,1), psi_fix_fmt_t(0,5,1)))

    def test_Negative_Becomes_Positive(self):
        self.assertEqual(4.0, psi_fix_abs(-4.0, psi_fix_fmt_t(1, 2, 2), psi_fix_fmt_t(1, 3, 3)))

    def test_Most_Negative_Value_Sat(self):
        self.assertEqual(3.75, psi_fix_abs(-4.0, psi_fix_fmt_t(1, 2, 2), psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

### psi_fix_neg ###
class PsiFixNegTest(unittest.TestCase):

    def test_PositiveToNegative_SignedToSigned(self):
        self.assertEqual(-2.5, psi_fix_neg(2.5, psi_fix_fmt_t(1,5,1), psi_fix_fmt_t(1,5,5)))

    def test_PositiveToNegative_UnsignedToSigned(self):
        self.assertEqual(-2.5, psi_fix_neg(2.5, psi_fix_fmt_t(0, 5, 1), psi_fix_fmt_t(1, 5, 5)))

    def test_NegativeToPositive_SignedToSigned(self):
        self.assertEqual(2.5, psi_fix_neg(-2.5, psi_fix_fmt_t(1, 5, 1), psi_fix_fmt_t(1, 5, 5)))

    def test_NegativeToPositive_SignedToUnsigned(self):
        self.assertEqual(2.5, psi_fix_neg(-2.5, psi_fix_fmt_t(1, 5, 1), psi_fix_fmt_t(0, 5, 5)))

    def test_Saturation_SignedToSigned(self):
        self.assertEqual(3.75, psi_fix_neg(-4.0, psi_fix_fmt_t(1, 2, 4), psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_Wrap_SignedToSigned(self):
        self.assertEqual(-4.0, psi_fix_neg(-4.0, psi_fix_fmt_t(1, 2, 4), psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_PosToNegSaturate_SignedToUnsigned(self):
        self.assertEqual(0.0, psi_fix_neg(2.5, psi_fix_fmt_t(1, 5, 1), psi_fix_fmt_t(0, 5, 5), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

### psi_fix_shift_left ###
class PsiFixShiftLeftTest(unittest.TestCase):

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            2.5,
            psi_fix_shift_left(1.25, psi_fix_fmt_t(0,3,2),
                            1, 10,
                            psi_fix_fmt_t(0,3,2)))

    def test_SameFmt_Signed(self):
        self.assertEqual(
            2.5,
            psi_fix_shift_left(1.25, psi_fix_fmt_t(1, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(1, 3, 2)))

    def test_FmtChange(self):
        self.assertEqual(
            2.5,
            psi_fix_shift_left(1.25, psi_fix_fmt_t(1, 1, 2),
                            1, 10,
                            psi_fix_fmt_t(0, 3, 2)))

    def test_Saturation_Signed(self):
        self.assertEqual(
            3.75,
            psi_fix_shift_left(2.0, psi_fix_fmt_t(1, 2, 2),
                            1, 10,
                            psi_fix_fmt_t(0, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_Saturation_UnsignedToSigned(self):
        self.assertEqual(
            3.75,
            psi_fix_shift_left(2.0, psi_fix_fmt_t(0, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_Saturation_SignedToUnsigned(self):
        self.assertEqual(
            0.0,
            psi_fix_shift_left(-0.5, psi_fix_fmt_t(1, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(0, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_Wrap_Signed(self):
        self.assertEqual(
            -4.0,
            psi_fix_shift_left(2.0, psi_fix_fmt_t(1, 2, 2),
                            1, 10,
                            psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Wrap_UnsignedToSigned(self):
        self.assertEqual(
            -4.0,
            psi_fix_shift_left(2.0, psi_fix_fmt_t(0, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(1, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Wrap_SignedToUnsigned(self):
        self.assertEqual(
            3.0,
            psi_fix_shift_left(-0.5, psi_fix_fmt_t(1, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(0, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Shift0(self):
        self.assertEqual(
            0.5,
            psi_fix_shift_left(0.5, psi_fix_fmt_t(1, 5, 5),
                            0, 10,
                            psi_fix_fmt_t(1, 5, 5), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Shift3(self):
        self.assertEqual(
            -4.0,
            psi_fix_shift_left(-0.5, psi_fix_fmt_t(1, 5, 5),
                            3, 10,
                            psi_fix_fmt_t(1, 5, 5), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Error_NegativeShift(self):
        with self.assertRaises(ValueError):
            psi_fix_shift_left(0.0, psi_fix_fmt_t(1,5,5), -1, 10, psi_fix_fmt_t(1,5,5))

    def test_Error_ShiftOutOfRange(self):
        with self.assertRaises(ValueError):
            psi_fix_shift_left(0.0, psi_fix_fmt_t(1,5,5), 11, 10, psi_fix_fmt_t(1,5,5))

### psi_fix_shift_right ###
class PsiFixShiftRightTest(unittest.TestCase):

    def test_SameFmt_Unsigned(self):
        self.assertEqual(
            1.25,
            psi_fix_shift_right(2.5, psi_fix_fmt_t(0, 3, 2),
                            1, 10,
                            psi_fix_fmt_t(0, 3, 2)))

    def test_SameFmt_Signed(self):
        self.assertEqual(
            1.25,
            psi_fix_shift_right(2.5, psi_fix_fmt_t(1, 3, 2),
                             1, 10,
                             psi_fix_fmt_t(1, 3, 2)))

    def test_FmtChange(self):
        self.assertEqual(
            1.25,
            psi_fix_shift_right(2.5, psi_fix_fmt_t(0, 3, 2),
                             1, 10,
                             psi_fix_fmt_t(1, 1, 2)))

    def test_Saturation_SignedToUnsigned(self):
        self.assertEqual(
            0.0,
            psi_fix_shift_right(-0.5, psi_fix_fmt_t(1, 3, 2),
                             1, 10,
                             psi_fix_fmt_t(0, 2, 2), psi_fix_rnd_t.trunc, psi_fix_sat_t.sat))

    def test_Saturation_Shift0(self):
        self.assertEqual(
            0.5,
            psi_fix_shift_right(0.5, psi_fix_fmt_t(1, 5, 5),
                             0, 10,
                             psi_fix_fmt_t(1, 5, 5), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Saturation_Shift3(self):
        self.assertEqual(
            -0.5,
            psi_fix_shift_right(-4.0, psi_fix_fmt_t(1, 5, 5),
                             3, 10,
                             psi_fix_fmt_t(1, 5, 5), psi_fix_rnd_t.trunc, psi_fix_sat_t.wrap))

    def test_Error_NegativeShift(self):
        with self.assertRaises(ValueError):
            psi_fix_shift_right(0.0, psi_fix_fmt_t(1,5,5), -1, 10, psi_fix_fmt_t(1,5,5))

    def test_Error_ShiftOutOfRange(self):
        with self.assertRaises(ValueError):
            psi_fix_shift_right(0.0, psi_fix_fmt_t(1,5,5), 11, 10, psi_fix_fmt_t(1,5,5))

### psi_fix_upper_bound ###
class PsiFixUpperBoundTest(unittest.TestCase):

    def test_Unsigned(self):
        self.assertEqual(3.75, psi_fix_upper_bound(psi_fix_fmt_t(0,2,2)))

    def test_Signed(self):
        self.assertEqual(1.75, psi_fix_upper_bound(psi_fix_fmt_t(1, 1, 2)))

### psi_fix_lower_bound ###
class PsiFixLowerBoundTest(unittest.TestCase):
    def test_Unsigned(self):
        self.assertEqual(0.0, psi_fix_lower_bound(psi_fix_fmt_t(0, 2, 2)))

    def test_Signed(self):
        self.assertEqual(-2.0, psi_fix_lower_bound(psi_fix_fmt_t(1, 1, 2)))

### psi_fix_in_range ###
class PsiFixInRangeTest(unittest.TestCase):

    def test_InRangeNormal(self):
        self.assertEqual(True, psi_fix_in_range(1.25, psi_fix_fmt_t(1,4,2), psi_fix_fmt_t(1,2,4), psi_fix_rnd_t.trunc))

    def test_OutRangeNormal(self):
        self.assertEqual(False, psi_fix_in_range(6.25, psi_fix_fmt_t(1,4,2), psi_fix_fmt_t(1,2,4), psi_fix_rnd_t.trunc))

    def test_SignedUnsigned_OutRange(self):
        self.assertEqual(False, psi_fix_in_range(-1.25, psi_fix_fmt_t(1,4,2), psi_fix_fmt_t(0,5,2), psi_fix_rnd_t.trunc))

    def test_UnsignedSigned_OutRange(self):
        self.assertEqual(False, psi_fix_in_range(15.0, psi_fix_fmt_t(0,4,2), psi_fix_fmt_t(1,3,2), psi_fix_rnd_t.trunc))

    def test_UnsignedSigned_InRange(self):
        self.assertEqual(True, psi_fix_in_range(15.0, psi_fix_fmt_t(0,4,2), psi_fix_fmt_t(1,4,2), psi_fix_rnd_t.trunc))

    def test_Rounding_OutRange(self):
        self.assertEqual(False, psi_fix_in_range(15.5, psi_fix_fmt_t(0,4,2), psi_fix_fmt_t(1,4,0), psi_fix_rnd_t.round))

    def test_Rounding_InRange1(self):
        self.assertEqual(True, psi_fix_in_range(15.5, psi_fix_fmt_t(0,4,2), psi_fix_fmt_t(1,4,1), psi_fix_rnd_t.round))

    def test_Rounding_InRange2(self):
        self.assertEqual(True, psi_fix_in_range(15.5, psi_fix_fmt_t(0,4,2), psi_fix_fmt_t(0,5,0), psi_fix_rnd_t.round))

########################################################################################################################
# Test Runner
########################################################################################################################
if __name__ == "__main__":
    unittest.main()




