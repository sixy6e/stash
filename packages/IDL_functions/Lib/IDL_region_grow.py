#!/usr/bin/env python

import numpy
from scipy import ndimage
from IDL_functions import histogram
from IDL_functions import array_indices

def region_grow(array, ROIPixels, stddev_multiplier=None, All_Neighbors=False, threshold=None):
    """
    Grows an ROI (Region of Interest) for a given array.

    Replicates IDL's REGION_GROW function (Interactive Data Language, EXELISvis).
    The ROI is used to generate statistical thresholds by which to grow connected pixels. 

    :param array:
        A single 2D numpy array.

    :param ROIPixels:
        A tuple containing a the location of a single pixel, or multiple pixel locations.

    :param stddev_multiplier:
        A value containing the standard deviation multiplier that defines the upper and lower threshold limits. Defaulted to None, in which case the min and max will be used as defining threshold limits.

    :param All_Neighbors:
        If set to True, then all 8 neighbours will be used to search for connectivity. Defaults to False (only the 4 immediate neighbours are used for connectivity).
 
    :return:
        A tuple of (y,x) 1D numpy arrays containing image co-ordinates of the grown regions.

    Example:

        >>> array = numpy.random.randint(0,256, (100,100))
        >>> pix = [50,50]
        >>> x = numpy.arange(9) % 3 + (pix[1] - 1)
        >>> y = numpy.arange(9) % 3 + (pix[0] - 1)
        >>> roi = (y,x)
        >>> grown_region = region_grow(array, roi, stddev_multiplier=2.5, All_Neighbors=True)

    :author:
        Josh Sixsmith; joshua.sixsmith@ga.gov.au, josh.sixsmith@gmail.com

    :history:
       * 20/04/2012: Created.
       * 12/12/2013: Re-written and adapted for the IDL_functions suite.
       * 21/12/2013: Functionality changed (removed ROI creation and assumed the base input is already an ROI) to bring more into line with EXELISvis's version of REGION_GROW.
       * 27/12/2013: Changed roi keyword to ROIPixels to bring into line with the keyword used by IDL.

    :copyright:
        Copyright (c) 2013, Josh Sixsmith
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        1. Redistributions of source code must retain the above copyright notice, this
           list of conditions and the following disclaimer. 
        2. Redistributions in binary form must reproduce the above copyright notice,
           this list of conditions and the following disclaimer in the documentation
           and/or other materials provided with the distribution. 

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
        ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

        The views and conclusions contained in the software and documentation are those
        of the authors and should not be interpreted as representing official policies, 
        either expressed or implied, of the FreeBSD Project.

    """

    def case_one(array=None, ROI=None, threshold=None, stddev_multiplier=None):
        """
        Calculates the upper and lower thresholds based on an ROI of array.
        """
        upper = numpy.max(array[ROI])
        lower = numpy.min(array[ROI])

        return (upper,lower)

    def case_two(array=None, ROI=None, threshold=None, stddev_multiplier=None):
        """
        No calculation, simply returns the upper and lower thresholds based on given threshold paramater.
        """
        upper = threshold[1]
        lower = threshold[0]

        return (upper,lower)

    def case_three(array=None, ROI=None, threshold=None, stddev_multiplier=None):
        """
        Calculates the upper and lower thresholds via the ROI of an array and a standard deviation multiplier.
        """

        # For the case of a single pixel ROI, the standard deviation would be undefined
        # So set the mean to equal the pixel value and stdv to 0.0
        if (ROI[0].shape == 1):
            mean = array[ROI]
            stdv = 0.0
        else:
            stdv  = numpy.std(array[ROI], ddof=1) # Sample standard deviation
            limit = stddev_multiplier * stdv
            mean  = numpy.mean(array[ROI])

        upper = mean + limit
        lower = mean - limit

        return (upper,lower)

    if (len(array.shape) != 2):
        raise Exception('Input array needs to be 2D in shape!')

    if not ((type(ROIPixels) != list) | (type(ROIPixels) != tuple)):
        raise Exception('ROIPixels must be of type tuple or type list containing (ndarray,ndarray) or [ndarray,ndarray]!')

    if (type(ROIPixels[0]) != numpy.ndarray):
        raise Exception('ROIPixels must be of type ndarray for tuple (ndarray,ndarray) or list [ndarray,ndarray] style of index!')

    if (len(ROIPixels) != 2):
        raise Exception('ROIPixels must be of length 2!')

    if (type(All_Neighbors) != bool):
        raise Exception('All_Neighbours keyword must be of type bool!')

    case_of = {
                '1' : case_one,
                '2' : case_two,
                '3' : case_three,
              }

    if (stddev_multiplier == None) & (threshold == None):
        case = '1'
    elif (stddev_multiplier == None) & (threshold != None):
        if (len(threshold) != 2):
            raise Exception('Threshold must be of length 2: [Min,Max]!!!')
        case = '2'
    elif (stddev_multiplier != None) & (threshold != None):
        print 'Warning!!! Both stddev_multiplier and threshold parameters are set. Using threshold.'
        if (len(threshold) != 2):
            raise Exception('Threshold must be of length 2: [Min,Max]!!!')
        case = '2'
    else:
        case = '3'

    # Create the structure for the labeling procedure
    if All_Neighbors:
        s = [[1,1,1],[1,1,1],[1,1,1]]
    else:
        s = [[0,1,0],[1,1,1],[0,1,0]]

    # Get the array dimensions
    dims = array.shape

    # Create the index list
    idx = []

    # Get the upper and lower limits to generate the mask
    upper, lower = case_of[case](array, ROIPixels, threshold=threshold, stddev_multiplier=stddev_multiplier)

    # Create the mask via the thresholds
    mask = (array >= lower) & (array <= upper)

    # The label function segments the image into contiguous blobs
    label_array, num_labels = ndimage.label(mask, structure=s)

    # Find the labels associated with the ROI
    labels  = label_array[ROIPixels]
    mx_lab  = numpy.max(labels)
    # Find unique labels, excluding zero (background)
    ulabels = (numpy.unique(labels[labels > 0])).tolist() # Convert to list; Makes for neater indexing

    # Generate a histogram to find the label locations
    h = histogram(label_array.flatten(), min=0, max=mx_lab, reverse_indices='ri')
    hist = h['histogram']
    ri = h['ri']

    for lab in ulabels:
        if hist[lab] == 0:
            continue
        idx.extend(ri[ri[lab]:ri[lab+1]])

    idx = numpy.array(idx)
    idx = array_indices(dims, idx, dimensions=True)

    return idx

