#!/usr/bin/env python

import numpy
from scipy import ndimage
from IDL_funtions import histogram

def region_grow(array, seed, stdv_multiplier=None, ROI=False, All_Neighbours=False, threshold=[None,None]):
    """
    Grows a single pixel or a group of pixels into a region.

    Similar to IDL's REGION_GROW function. (Interactive Data Language, EXELISvis).
    For the single pixel case, the seed and its neighbours are used to generate statistical thresholds by which to grow connected pixels. 
    If the keyword 'ROI' is set to True, then the seed will be assumed to be a region of neighbouring pixels. Otherwise the region grow function will iterate through the seed points and grow them individually.

    :param array:
        A single 2D numpy array.

    :param seed:
        A tuple containing a the location of a single pixel, or multiple pixel locations.

    :param stdv_multiplier:
        A value containing the standard deviation multiplier that defines the upper and lower threshold limits. Defaulted to None, in which case the min and max will be used as defining threshold limits.

    :param ROI:
        If set to True, then the seed is assumed to be a region of neighbouring pixels, and gather stats from the ROI to perform the threholding. Defaults to False; eg pixels are not neighbouring and will iterate through all pixels contained in the seed.

    :param All_Neighbours:
        If set to True, then all 8 neighbours will be used to search for connectivity. Defaults to False (only the 4 immediate neighbours are used for connectivity).
 
    :return:
        A mask of type Bool containing the grown locations.

    :author:
        Josh Sixsmith; joshua.sixsmith@ga.gov.au, josh.sixsmith@gmail.com

    :history:
       * 20/04/2012: Created.
       * 12/12/2013: Re-written and adapted for the IDL_functions suite.

    :notes:
        The keyword ROI is an addition to IDL's version of REGION_GROW, in that a series of seed points can be provided for growing, not just a single ROI.
        IDL will return a vector of pixel indices representing the grown regions. Numpy can use a boolean array to index, as such a boolean array will be returned. This also makes it easier to return multiple grown regions within a single boolean array.

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

    def case_one():
        return (upper,lower)

    def case_two():
        return (upper,lower)

    def case_three():
        return (upper,lower)

    def case_four():
        return (upper,lower)


    if len(array.shape) != 2:
        raise Exception('Input array needs to be 2D in shape')

    if type(seed) != tuple:
        raise Exception('Seed must be a tuple')

    if len(seed) != 2:
        raise Exception('Seed must be of length 2')

    if type(All_Neighbours) != bool:
        raise Exception('All_Neighbours keyword must be of type bool')

    # this can be used only if initialised as threshold=[None,None]
    #if (len(threshold) != 2):
    #    raise Exception('Threshold must be of length 2: [Min,Max]!!!')

    if (stdv_multiplier == None) & (threshold == None):
        case = '1'
        case_one()
    elif (stdv_multiplier == None) & (threshold != None):
        if (len(threshold) != 2):
            raise Exception('Threshold must be of length 2: [Min,Max]!!!')
        case = '2'
        case_two()
    elif (stdv_multiplier != None) & (threshold != None):
        print 'Warning!!! Both stdv_multiplier and threshold parameters are set. Using threshold.'
        if (len(threshold) != 2):
            raise Exception('Threshold must be of length 2: [Min,Max]!!!')
        case = '2'
        case_two()
    else:
        case = '3'
        case_three()

    # Create the structure for the labeling procedure
    if All_Neighbours:
        s = [[1,1,1],[1,1,1],[1,1,1]]
    else:
        s = [[0,1,0],[1,1,1],[0,1,0]]

    dims = array.shape
    # Create the array that will hold the grown region
    grown_regions = numpy.zeros(dims, dtype='bool').flatten()

    if (type(seed[0]) == numpy.ndarray) & ROI == False:
       loop = range(len(seed[0]))
    else:
       loop = range(1)

    for i in loop:

        if ROI == False:
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
        else:
            roi = seed

        # Implement the following prior to looping. Set up as a dictionary styled case switch
        if (stdv_multiplier == None) & (threshold == None):
            upper = numpy.max(array[roi])
            lower = numpy.min(array[roi])
        elif (stdv_multiplier == None) & (threshold != None):
            if (len(threshold) != 2):
                raise Exception('Threshold must be of length 2: [Min,Max]!!!')
            upper = threshold[1]
            lower = threshold[0]
        elif (stdv_multiplier != None) & (threshold != None):
            print 'Warning!!! Both stdv_multiplier and threshold parameters are set. Using threshold.'
            if (len(threshold) != 2):
                raise Exception('Threshold must be of length 2: [Min,Max]!!!')
            upper = threshold[1]
            lower = threshold[0]
        else:
            stdv  = numpy.std(array[roi], ddof=1)
            limit = stdv_multiplier * stdv
            mean  = numpy.mean(array[roi])
            upper = mean + limit
            lower = mean - limit

        # Create the mask via the thresholds
        mask = (array >= lower) & (array <= upper)

        # The label function segments the image into contiguous blobs
        label_array, num_labels = ndimage.label(mask, structure=s)

        # Find the labels associated with the roi
        labels  = label_array[roi]
        ulabels = (numpy.unique(labels[labels > 0])).tolist() # Convert to list; Makes for neater indexing

        # Generate a histogram to find the label locations, excluding zero (background)
        # num_labels can be used for 'max' as the labeling function should return labels 0 through to n without skipping a value
        h = histogram(label_array.flatten(), min=1, max=num_labels, reverse_indices='ri')
        hist = h['histogram']
        ri = h['ri']

        for lab in ulabels:
            if hist[lab] == 0:
                continue
            grown_regions[ri[ri[lab]:ri[lab+1]]] = True

        #for i in numpy.arange(ulabels.shape[0]):
        #    if hist[ulabels[i]] == 0:
        #        continue
        #    grown_regions[ri[ri[ulabels[i]]:ri[ulabels[i]+1]]] = True
            
    return grown_regions.reshape(dims)
