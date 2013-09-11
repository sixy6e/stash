#! /usr/bin/env python

import numpy
from scipy import ndimage
from IDL_functions import IDL_Histogram

def summary_cleanup(array, min_value=1, max_value=4, min_pop_count=10):
    """
    """
    dims = array.shape
    if (len(dims) != 2):
        print 'Array is not 2-Dimensional!!!'
        return None

    flat_array = array.flatten()

    low_obs = (array >= min_value) & (array <= max_value)
    kernel  = [[1,1,1],[1,1,1],[1,1,1]]

    label_array, num_labels = ndimage.label(low_obs, structure=kernel)

    h = IDL_Histogram(label_array.flatten(), min=1, reverse_indices='ri')

    hist = h['histogram']
    ri   = h['ri']

    wh = numpy.where(hist <= max_value)
    for i in wh[0]:
        flat_array[ri[ri[i]:ri[i+1]]] = 0

    cleaned_array = flat_array.reshape(dims)
    return cleaned_array

