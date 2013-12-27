#! /usr/bin/env python
import sys
import os
import unittest
import numpy

# Need to temporarily append to the PYTHONPATH in order to import the 
# newly built region_grow function
sys.path.append(os.getcwd())
from IDL_functions import region_grow


class IDL_region_grow_Tester(unittest.TestCase):
    """
    A unit testing procedure for the IDL Region_Grow funciton.
    """

    def setUp(self):
        self.array1 = numpy.zeros((100,100))
        self.array2 = numpy.random.randint(100,201,(10,10))

    def test_threshold(self):
        """
        Test that the threshold keyword works
        """
        # Using an array of zeros, set the middle 10x10 to values between 100 and 200
        array = self.array1.copy()
        array[45:55,45:55] = self.array2
        pix = [50,50]
        x = numpy.arange(9) % 3 + (pix[1] - 1)
        y = numpy.arange(9) % 3 + (pix[0] - 1)
        roi = (y,x)
        grown = region_grow(array, roi, threshold=[100,200])
        diff = numpy.sum(array[grown] - self.array2.flatten())
        self.assertEqual(0, 0)


if __name__ == '__main__':
    unittest.main()
