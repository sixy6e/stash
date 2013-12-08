#!/usr/bin/env python

import numpy
from scipy import ndimage
from osgeo import gdal
from IDL_functions import histogram

def binary_recursive_histogram(image, all_neighbors=False):
    """
    """

    if (type image == str):
        ds = gdal.Open(image)
        nb = ds.GetRasterCount()

    # Initialise the result array
    result      =  numpy.zeros(nb, 2)
    result_list = []

    # Loop over the bands
    for i in range(nb):
        band = ds.GetRasterBand(i+1) # GDAL uses start index of 1
        img  = band.ReadRaster()
        band.FlushCache()

        # Generate the histogram
        h = histogram(img.flatten(), min=0)
        hist = h['histogram']

        # Segment the binary mask
        kernel = [[0,1,0],[1,1,1],[0,1,0]]
        if all_neighbors:
            kernel = [[1,1,1],[1,1,1],[1,1,1]]
        label_arr, nlabels = ndimage(img, structure=kernel)

        # Populate the result array if data is found
        if (hist.shape[0] >= 2):
            result[i,0] = hist[1]
            result[i,1] = nlabels
            result_list.append('%i, %i, %i\n' %(i, hist[1], nlabels))

    mx_loc     = numpy.argmax(result[:,0]) + 1 # Refer back to a 1 based band index
    mx_seg_loc = numpy.argmax(result[:,1]) + 1 # Refer back to a 1 based band index

    outfile = open(outfname, 'w')
    outfile.write('Results from %s image file\n' %image)
    outfile.write('Band with most flagged pixels: %i\n' %mx_loc)
    outfile.write('Band with most objects: %i\n' %mx_seg_loc)
    outfile.write('\n')
    outfile.write('Band, Flagged Pixels, Number of Objects\n')
    
    for res in result_list:
        outfile.write(r)

    outfile.close()
