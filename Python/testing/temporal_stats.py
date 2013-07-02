#! /usr/bin/env python

import os
import sys
import argparse
import numpy
from osgeo import gdal
import datetime
import gc

sys.path.append('/home/547/jps547')

import median_josh
import get_tiles

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

#subset = iobj.ReadAsArray(0,0,10,10)
#WriteArray(self, array, xoff=0, yoff=0)

def temporal_stats(infile, outfile, file_driver):

    iobj = gdal.Open(infile, gdal.gdalconst.GA_ReadOnly)
    assert iobj

    samples = iobj.RasterXSize
    lines   = iobj.RasterYSize
    band    = iobj.GetRasterBand(1)
    noData  = band.GetNoDataValue()
    band    = None

    outnb   = 5
    NaN     = numpy.float32(numpy.NaN)

    driver     = gdal.GetDriverByName(file_driver)
    outDataset = driver.Create(outfile, samples, lines, outnb, 6)
    outDataset.SetMetadata(iobj.GetMetadata())
    outDataset.SetGeoTransform(iobj.GetGeoTransform())
    outDataset.SetProjection(iobj.GetProjection())


    # Going to do it row by row, should be less loops
    tiles = get_tiles.get_tile3(samples, lines, xtile=samples, ytile=1)
    for tile in tiles:
        ystart = int(tile[0])
        yend   = int(tile[1])
        xstart = int(tile[2])
        xend   = int(tile[3])

        xsize = int(xend - xstart)
        ysize = int(yend - ystart)

        iobj = gdal.Open(infile, gdal.gdalconst.GA_ReadOnly)
        subset = iobj.ReadAsArray(xstart, ystart, xsize, ysize)
        stats = numpy.zeros((outnb, ysize, xsize), dtype='float32')

        # loop over the columns
        for i in xrange(subset.shape[2]):
            data = subset[:,:,i]
            wh = (data != noData)
            count = numpy.sum(wh)
            stats[0,:,i] = median_josh.median(data[wh], even_left=True)
            stats[3,:,i] = numpy.float(count)
            tf = numpy.isnan(stats[0,:,i])
            if tf:
                stats[4,:,i] = NaN
                stats[2,:,i] = NaN
                stats[1,:,i] = NaN
            else:
                stats[2,:,i] = numpy.min(data[wh])
                stats[1,:,i] = numpy.max(data[wh])
                wh = numpy.where(data == stats[0,:,i])
                stats[4,:,i] = wh[0][0] # start index from 0?

        # replace NaNs with noData value
        wh = ~(numpy.isfinite(stats))
        stats[wh] = noData

        for i in range(stats.shape[0]):
            outband = outDataset.GetRasterBand(i+1)
            outband.WriteArray(stats[i], xstart, ystart)
            outband.SetNoDataValue(noData)
            outband.FlushCache()
            outband = None
 
        iobj   = None
        del subset, stats, wh, tf, data
        gc.collect()

    outDataset = None


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Calculates Median over temporal domain.')
    parser.add_argument('--infile', required=True, help='The input file of which to calculate the stats.')
    parser.add_argument('--outfile', required=True, help='The output file name.')
    parser.add_argument('--driver', default='ENVI', help="The file driver type for the output file. See GDAL's list of valid file types. (Defaults to ENVI).")

    parsed_args = parser.parse_args()

    infile  = parsed_args.infile
    outfile = parsed_args.outfile
    driver  = parsed_args.driver

    temporal_stats(infile, outfile, driver)

