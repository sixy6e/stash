#!/usr/bin/env python

import numpy
from IDL_functions import histogram, array_indices

def obj_area(array):
    """
    Calculates area per object. Area is referred to as number of pixels.
    """

    h = histogram(array.flatten(i), min=1)
    hist = h['histogram']

    return hist

def obj_centroid(array):
    """
    Calculates centroids per object.
    """

    dims = array.shape
    h    = histogram(array.flatten(), min=1, reverse_indices='ri')
    hist = h['histogram']
    ri   = h['ri']
    cent = []
    for i in numpy.arange(hist.shape[0]):
        if (hist[i] == 0):
            continue
        idx = numpy.array(array_indices(dims, ri[ri[i]:ri[i+1]], dimensions=True))
        cent_i = numpy.mean(idx, axis=1)
        cent.append(cent_i)

    return cent

def obj_mean(array):
    """
    Calculates mean value per object.
    """
    arr_flat = array.flatten()
    h        = histogram(array.flatten(), min=1, reverse_indices='ri')
    hist     = h['histogram']
    ri       = h['ri']
    mean_obj = []
    for i in numpy.arange(hist.shape[0]):
        if (hist[i] == 0): 
            continue
        xbar = numpy.mean(arr_flat[ri[ri[i]:ri[i+1]]])
        mean_obj.append(xbar)

    return mean_obj

def perimeter(array, labeled=False, all_neighbors=False):
    """
    Calculates the perimeter per objectt.
    """

    if labelled:
        arr = array > 0

    # Construct the kernel to be used for the erosion process
    if all_neighbors:
        k = [[1,1,1],[1,1,1],[1,1,1]]
    else:
        k = [[0,1,0],[1,1,1],[0,1,0]]

    arr = array

    erode = ndimage.binary_erosion(arr, k)

    obj_borders = arr - erode

    # There is potential here for the kernel to miss object borders containing diagonal features
    # Force the kernel to include all neighbouring pixels
    k = [[1,1,1],[1,1,1],[1,1,1]]
    label_arr, n_labels = ndimage.label(obj_borders, k)
    #TODO
    # An alternative would be to use the reverse_indices of the original objects.
    # It shouldn't matter if they point to zero in the convolve array as the second histogram will exclude them.

    h    = histogram(label_arr.flatten(), min=1, reverse_indices='ri')
    hist = h['histogram']
    ri   = h['ri']

    # Construct the perimeter kernel
    k2 = [[10,2,10],[2,1,2],[10,2,10]]
    convolved = ndimage.convolve(diff, k2, mode='constant', cval=0.0) # pixels on array border only use values within the array extents

    perim   = []
    sqrt2   = numpy.sqrt(2.)
    weights = numpy.zeros(50)
    weights[[5,7,15,17,25,27]] = 1
    weights[[21,33]] = sqrt2
    weights[[13,23]] = (1. + sqrt2) / 2.

    for i in numpy.arange(hist.shape[0]):
        #if hist[i] # Probable don't need this check, as ndimage.label() should provide consecutive labels
        h_i    = histogram(convolved[ri[ri[i]:ri[i+1]]], min=1, max=50)
        hist_i = h_i['histogram']
        perim.append(numpy.dot(hist_i, weights)

    return perim
