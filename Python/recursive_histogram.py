#!/usr/bin/env python

import os
import numpy
from scipy import ndimage
import argparse
from osgeo import gdal
from IDL_functions import histogram

def binary_recursive_histogram(image, outfile, all_neighbours=False):
    """
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
    result      =  numpy.zeros((nb,2))
    result_list = []

    # Loop over the bands
    for i in range(nb):
        band = ds.GetRasterBand(i+1) # GDAL uses start index of 1
        img  = band.ReadAsArray()
        band.FlushCache()

        # Generate the histogram
        h = histogram(img.flatten(), min=0)
        hist = h['histogram']

        # Segment the binary mask
        kernel = [[0,1,0],[1,1,1],[0,1,0]]
        if all_neighbours:
            kernel = [[1,1,1],[1,1,1],[1,1,1]]
        label_arr, nlabels = ndimage.label(img, structure=kernel)

        # Populate the result array if data is found
        if (hist.shape[0] >= 2):
            result[i,0] = hist[1]
            result[i,1] = nlabels
            result_list.append('%i, %i, %i\n' %(i+1, hist[1], nlabels))

    mx_loc     = numpy.argmax(result[:,0]) + 1 # Refer back to a 1 based band index
    mx_seg_loc = numpy.argmax(result[:,1]) + 1 # Refer back to a 1 based band index

    outfile = open(outfname, 'w')
    outfile.write('Results from %s image file\n' %image)
    outfile.write('Band with most flagged pixels: %i\n' %mx_loc)
    outfile.write('Band with most objects: %i\n' %mx_seg_loc)
    outfile.write('\n')
    outfile.write('Band, Flagged Pixels, Number of Objects\n')
    
    for res in result_list:
        outfile.write(res)

    outfile.close()

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='A histogram and segmentation is applied to every band in an image. Only 0-1 binary images should be used. The result is output as a textfile.')
    parser.add_argument('--infile', required=True, help='The input image on which to apply the analysis.')
    parser.add_argument('--outfile', required=True, help='The output filename of the textfile that will contain the report.')
    parser.add_argument('--all_neighbours', action="store_true", help='If set, then all 8 neighbours of a pixel will be used for the segmentation process. Default is the immediate 4 neighbours.')

    parsed_args = parser.parse_args()

    infile  = parsed_args.infile
    outfile = parsed_args.outfile
    all_neighbours = parsed_args.all_neighbours 

    binary_recursive_histogram(infile, outfile, all_neighbours)
