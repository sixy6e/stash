#!/usr/bin/env python

import numpy

def square_roi(array, seed):
    """
    Expands a single pixel to include the 8 surrounding neighbours.
    """

    # Find the seed's neighbours
    x   = numpy.arange(9) % 3 + (seed[1][i] - 1)
    y   = numpy.arange(9) / 3 + (seed[0][i] - 1)
    roi = (y,x)

    # Check if any parts of the roi are outside the image
    bxmin = numpy.where(roi[1] < 0)
    bymin = numpy.where(roi[0] < 0)
    bxmax = numpy.where(roi[1] >= dims[1])
    bymax = numpy.where(roi[0] >= dims[0])

    # Change if roi co-ordinates exist outside the image domain.
    roi[1][bxmin] = 0
    roi[0][bymin] = 0
    roi[1][bxmax] = dims[1]-1
    roi[0][bymax] = dims[0]-1

    return roi

