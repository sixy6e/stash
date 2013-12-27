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
    A unit testing procedure for the IDL Region_Grow function.
    """

    def setUp(self):
        self.array1 = numpy.zeros((100,100))
        self.array2 = numpy.random.randint(100,201,(10,10))
        self.array3 = numpy.random.randint(10,31,(100,100))
        self.array4 = numpy.array([[10,20,30],[10,20,30],[10,20,30]])
        self.array5 = numpy.random.randint(0,171,(100,100))
        self.array6 = numpy.array([[0,0,0],[120,120,120],[120,120,120]])

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

    def test_min_max(self):
        """
        Test that the min/max of the ROI is used when neither the stddev multiplier or the threshold parameters are used.
        This will test that the entire array except the first pixel will be included in the grown region.
        """
        array = self.array3.copy()
        # Set one element to a value outside the range (10 <= x <= 30)
        array[0,0] = 40
        # Set a region of the array to values that include 10 and 30
        array[10:13,10:13] = self.array4
        pix = [11,11]
        x = numpy.arange(9) % 3 + (pix[1] - 1)
        y = numpy.arange(9) % 3 + (pix[0] - 1)
        roi = (y,x)
        grown = region_grow(array, roi)
        # Using the grown index set the regions to zero
        array[grown] = 0
        # The only pixel left should hole the value 40
        total = numpy.sum(array)
        self.assertEqual(total, 40)

    def test_stddev_mult(self):
        """
        Test that the standard deviation multiplier works.
        This will test that the entire array except the first pixel will be included in the grown region.
        """
        array = self.array5.copy()
        # Set one element to a value outside the range (0 <= x <= 170)
        array[0,0] = 255
        # Set a region of the array with a stddev of 60 and mean of 80
        array[10:13,10:13] = self.array6
        pix = [11,11]
        x = numpy.arange(9) % 3 + (pix[1] - 1)
        y = numpy.arange(9) % 3 + (pix[0] - 1)
        roi = (y,x)
        grown = region_grow(array, roi, stddev_multiplier=1.5)
        # Using the grown index set the regions to zero
        array[grown] = 0
        # The only pixel left should hole the value 40
        total = numpy.sum(array)
        self.assertEqual(total, 255)

if __name__ == '__main__':
    unittest.main()
