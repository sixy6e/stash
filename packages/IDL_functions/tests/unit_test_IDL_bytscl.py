#! /usr/bin/env python
import sys
import os
import unittest
import numpy

# Need to temporarily append to the PYTHONPATH in order to import the 
# newly built region_grow function
sys.path.append(os.getcwd())
from IDL_functions import bytscl


class IDL_bytscl_Tester(unittest.TestCase):
    """
    A unit testing procedure for the IDL BYTSCL function.
    """

    def setUp(self):
        self.array1 = numpy.random.randn(100,100)
        self.array2 = numpy.random.randint(0,256,(100,100))

    def test_output_range(self):
        """
        Test that the output array is [0,255].
        """
        byt = bytscl(self.array1)
        outside = (byt < 0) | (byt > 255)
        total = numpy.sum(outside)
        self.assertEqual(total, 0)

    def test_out_dtype(self):
        """
        Test that the output array is of type uint8.
        """
        byt = bytscl(self.array1)
        dtype = byt.dtype
        self.assertEqual(dtype, 'uint8')

    def test_Top_keyword(self):
        """
        Test that the Top keyword works as expected.
        """
        # Set Top to 200
        byt = bytscl(self.array1, Top=200)
        mx = numpy.max(byt)
        self.assertEqual(mx, 200)

    def test_Max_keyword(self):
        """
        Test that the Max keyword works as expected.
        """
        # Set Max to 200
        byt = bytscl(self.array2, Max=200)
        control = numpy.sum(self.array2 >= 200)
        total = numpy.sum(byt == 255)
        self.assertEqual(total, control)

    def test_Min_keyword(self):
        """
        Test that the Min keyword works as expected.
        """
        # Set Min to 200
        byt = bytscl(self.array2, Min=200)
        control = numpy.sum(self.array2 <= 200)
        total = numpy.sum(byt == 0)
        self.assertEqual(total, control)

    def test_NaN_keyword(self):
        """
        Test that the NaN keyword works as expected.
        """
        # If array has any NaN's then the output will return all zeros
        array = self.array1.copy()
        array[0,0] = numpy.nan
        byt = bytscl(array, NaN=True)
        total = numpy.sum(byt)
        self.assertTrue(total != 0)

if __name__ == '__main__':
    unittest.main()
