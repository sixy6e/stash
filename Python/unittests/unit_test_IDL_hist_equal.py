#! /usr/bin/env python
import sys
import os
import unittest
import numpy
from scipy import stats

# Need to temporarily append to the PYTHONPATH in order to import the 
# newly built hist_equal function
sys.path.append(os.getcwd())
from IDL_functions import hist_equal

class IDL_hist_equal_Tester(unittest.TestCase):
    """
    A unit testing procedure for the IDL hist_equal function.
    """

    def setUp(self):
        # This should create an array with a skewness and kurtosis of ~0
        # Set an error limit, 0.01 should be ok.
        self.array = numpy.random.randn(100,100)
        self.error   = 0.01

    def test_kurtosis(self):
        """
        An equalised distribution should have a kurtosis of ~1.2.
        """
        scl_a = hist_equal(self.array)
        kur   = abs(stats.kurtosis(scl_a, axis=None) + 1.2)
        self.assertTrue(kur <= self.error)

    def test_skewness(self):
        """
        An equalised distribution should have a skewness of ~0.
        """
        scl_a = hist_equal(self.array)
        skw   = abs(stats.skew(scl_a, axis=None))
        self.assertTrue(skw <= self.error)

if __name__ == '__main__':
    unittest.main()

