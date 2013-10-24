#! /usr/bin/env python

import numpy
from scipy import ndimage
from IDL_functions import histogram

def summary_cleanup(array, min_value=1, max_value=4, min_population=10, all_neighbors=True):
    """
    A function for removing pixel 'islands' from the water summary output.
    Using the default parameters, pixel groups with less than 10 members
    within the data range of (1 <= x <= 4) are removed from the original array.

    :param array:
        A 2-Dimensional numpy array.

    :param min_value:
        Default value of 1. The minimum pixel value to be included within the analysis.

    :param max_value:
        Default value of 4. The maximum pixel value to be included within the analysis.

    :param min_population:
        Default value of 10. The minimum population size a group of pixels must be in order to be retained.

    :param all_neighbors:
        Default is True. If True, the 8 surrounding neighbors of the centre pixel will be used for connectivity.
        If False, then only the 4 immediate neighbors of the centre pixel will be used for connectivity.

    :return:
        A copy of array with pixels satisfying the min_value/max_value/min_pop_count parameters removed.

    :author:
        Josh Sixsmith; joshua.sixsmith@ga.gov.au

    :history:
        *  2013/09/11: Created
    """

    dims = array.shape
    if (len(dims) != 2):
        print 'Array is not 2-Dimensional!!!'
        return None

    flat_array = array.flatten()

    low_obs = (array >= min_value) & (array <= max_value)

    if all_neighbors:
        kernel  = [[1,1,1],[1,1,1],[1,1,1]]
    else:
        kernel  = [[0,1,0],[1,1,1],[0,1,0]]

    label_array, num_labels = ndimage.label(low_obs, structure=kernel)

    h = histogram(label_array.flatten(), min=1, reverse_indices='ri')

    hist = h['histogram']
    ri   = h['ri']

    wh = numpy.where(hist < min_population)
    for i in wh[0]:
        flat_array[ri[ri[i]:ri[i+1]]] = 0

    cleaned_array = flat_array.reshape(dims)
    return cleaned_array

