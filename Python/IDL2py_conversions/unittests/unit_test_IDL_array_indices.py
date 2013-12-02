#! /usr/bin/env python
import sys
import os
import unittest
import numpy

# Need to temporarily append to the PYTHONPATH in order to import the 
# newly built hist_equal function
sys.path.append(os.getcwd())
from IDL_functions import array_indices

class IDL_array_indices_Tester(unittest.TestCase):
    """
    A unit testing procedure for the IDL array_indices function.
    """

    def setUp(self):
        self.array_1D_1 = numpy.random.randint(0,256,(10000))
        self.array_1D_2 = numpy.random.randint(0,256,(30000))
        self.array_2D   = self.array_1D_1.reshape(100,100)
        self.array_3D   = self.array_1D_2.reshape((3,100,100))

    def test_2D_indices_row(self):
        """
        The returned 2D index should be the same as control.
        """
        control = numpy.where(self.array_2D == 66)
        wh      = numpy.where(self.array_1D_1 == 66)
        ind2D   = array_indices(array=self.array_2D, index=wh[0])
        n       = len(control[0])
        self.assertEqual((control[0] == ind2D[0]).sum(), n)

    def test_2D_indices_col(self):
        """
        The returned 2D index should be the same as control.
        """
        control = numpy.where(self.array_2D == 66)
        wh      = numpy.where(self.array_1D_1 == 66)
        ind2D   = array_indices(array=self.array_2D, index=wh[0])
        n       = len(control[1])
        self.assertEqual((control[1] == ind2D[1]).sum(), n)

    def test_dimensions(self):
        """
        Test that the dimensions keyword works and yields the same result as the control.
        """
        control     = numpy.where(self.array_3D == 66)
        control_sum = numpy.sum(self.array_3D[control])
        wh          = numpy.where(self.array_1D_2 == 66)
        ind3D       = array_indices(array=self.array_3D.shape, index=wh[0], dimensions=True)
        test_sum    = numpy.sum(self.array_3D[ind3D])
        self.assertEqual(control_sum, test_sum)

if __name__ == '__main__':
    unittest.main()

