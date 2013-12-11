#!/usr/bin/env python

import os
import numpy
from scipy import ndimage
import argparse
from osgeo import gdal
from IDL_functions import histogram

def binary_recursive_histogram(image, outfile, all_neighbours=False):
    """
    Recursively applies a histogram to an image with multiple bands.
    Designed for the analysing the binary results by finding counts of 1 within each band.

    :param image:
        A string containing the full file path name of a multi-band binary image.

    :param outfile:
        The output filename of the textfile that will contain the report.

    :param all_neighbours:
        If set then pixel connectivity will be 8 neighbours rather than 4. Default is 4.

    :author:
        Josh Sixsmith; josh.sixsmith@gmail.com, joshua.sixsmith@ga.gov.au

    :history:
        * 07/12/2013: Created
        * 11/12/2013: Added more stats to the output

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

    # Check that the directory for the output file exists.
    if not (os.path.exists(os.path.dirname(outfile))):
        if os.path.dirname(outfile) == '': # Output to the current directory
            outfname = os.path.join(os.getcwd(), outfile)
        else:
            os.makedirs(os.path.dirname(outfile))

    #if (type image == str):
    #    ds = gdal.Open(image)
    #    nb = ds.GetRasterCount()
    ds = gdal.Open(image)
    nb = ds.RasterCount

    # Initialise the result array
    result      =  numpy.zeros((nb,4), dtype='int') # Only dealing with integers at this point in time. This could change in future.
    result_list = []

    # Loop over the bands
    for i in range(nb):
        band = ds.GetRasterBand(i+1) # GDAL uses start index of 1
        img  = band.ReadAsArray()
        band.FlushCache()

        # Generate the histogram
        h    = histogram(img.flatten(), min=0)
        hist = h['histogram']

        # Segment the binary mask
        kernel = [[0,1,0],[1,1,1],[0,1,0]]
        if all_neighbours:
            kernel = [[1,1,1],[1,1,1],[1,1,1]]
        label_arr, nlabels = ndimage.label(img, structure=kernel)

        # Get min and max areas of the segmented regions
        h2       = histogram(label_arr.flatten(), min=1)
        hist2    = h2['histogram']
        mn_area  = numpy.min(hist2)
        mx_area  = numpy.max(hist2)
        avg_area = numpy.mean(hist2)

        # Populate the result array if data is found
        if (hist.shape[0] >= 2):
            result[i,0] = hist[1]
            result[i,1] = nlabels
            result[i,2] = mn_area
            result[i,3] = mx_area
            result_list.append('%i, %i, %i, %i, %i, %f\n' %(i+1, hist[1], nlabels, mn_area, mx_area, avg_area))
        else:
            result_list.append('%i, %i, %i, %i, %i, %f\n' %(i+1, 0, 0, 0, 0, 0.0))

    mx_loc      = numpy.argmax(result[:,0]) + 1 # Refer back to a 1 based band index
    mx_seg_loc  = numpy.argmax(result[:,1]) + 1 # Refer back to a 1 based band index
    mn_area_loc = numpy.argmin(result[:,2]) + 1 # Refer back to a 1 based band index
    mx_area_loc = numpy.argmax(result[:,3]) + 1 # Refer back to a 1 based band index

    outfile = open(outfname, 'w')
    outfile.write('Results from %s image file\n' %image)
    outfile.write('Band with most flagged pixels: %i\n' %mx_loc)
    outfile.write('Band with most objects: %i\n' %mx_seg_loc)
    outfile.write('\n')
    outfile.write('Band, Flagged Pixels, Number of Objects, Smallest Object, Largest Object, Average Object Size\n')
    
    for res in result_list:
        outfile.write(res)

    outfile.close()

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='A histogram and segmentation is applied to every band in an image. Only 0-1 binary images should be used. The result is output as a textfile. Stats outputs on a per band basis include num of flagged pixels, number of objects, min/max/avg object area.')
    parser.add_argument('--infile', required=True, help='The input image on which to apply the analysis.')
    parser.add_argument('--outfile', required=True, help='The output filename of the textfile that will contain the report.')
    parser.add_argument('--all_neighbours', action="store_true", help='If set, then all 8 neighbours of a pixel will be used for the segmentation process. Default is the immediate 4 neighbours.')

    parsed_args = parser.parse_args()

    infile  = parsed_args.infile
    outfile = parsed_args.outfile
    all_neighbours = parsed_args.all_neighbours 

    binary_recursive_histogram(infile, outfile, all_neighbours)
