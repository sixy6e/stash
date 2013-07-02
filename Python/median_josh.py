#! /usr/bin/env python

import numpy

def median(array, even_left=False, even_right=False):
    '''Calculates the median of a 1D array.

    This function can support even arrays and return a non-interpolated value.

    Args:
        array: A 1D numpy array
        even_left: For even length arrays, the returned median will be the
            value on the left hand side of the two middle values.
        even_right: For even length arrays, the returned median will be the
            value on the right hand side of the two middle values.

    Returns:
        A floating point value representing the median.

    Author:
        Josh Sixsmith; joshua.sixsmith@ga.gov.au
    '''

    if (array.size == 0):
        return numpy.float32(numpy.NaN)

    if even_left:
        if even_right:
            raise Exception('Only 1 even argument can be accepted!')
        if (array.shape[0] % 2 != 0):
            med = numpy.median(array)
        else:
            sort = numpy.sort(array)
            len = array.shape[0]
            ind = (len / 2) - 1
            med = numpy.float(sort[ind])
    elif even_right:
        if (array.shape[0] % 2 != 0):
            med = numpy.median(array)
        else:
            sort = numpy.sort(array)
            len = array.shape[0]
            ind = (len / 2)
            med = numpy.float(sort[ind])
    else:
        med = numpy.median(array)
    return med
