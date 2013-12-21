#!/usr/bin/env python

import numpy

def create_roi(array, loc, kx=3, ky=3):
    """
    Expands a single pixel to an ROI defined by a kernel size.
    """

    dims = array.shape
    if (len(dims) != 2):
        raise Exception("Array Must Be 2 Dimensional!")

    # Kernel size squared
    kx2 = kx**2
    ky2 = ky**2

    # Kernel offsets
    xoff = kx / 2
    yoff = ky / 2

    # Find the seed's neighbours
    x   = numpy.arange(kx2) % kx + (seed[1] - xoff)
    y   = numpy.arange(ky2) / ky + (seed[0] - yoff)
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

