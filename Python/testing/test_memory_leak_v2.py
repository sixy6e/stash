#! /usr/bin/env python

import os
import sys
import argparse
import numpy
from osgeo import gdal

sys.path.append('/home/547/jps547')

import median_josh
import get_tiles


#for i in xrange(1000):
#    x = numpy.zeros((7,8000,8000), dtype='float32')

#    print (x.nbytes /1024. /1024 /1024), 'gb'

f='/g/data/v10/tmp/dataprep/mdba_20090101-20090430/ndvi_093-094_080/stack_093-094_080_GDA94-MGA-zone-55_envi'
outfile='/g/data/v10/tmp/dataprep/mdba_20090101-20090430/ndvi_093-094_080/test_in_out_tiling'

iobj = gdal.Open(f, gdal.gdalconst.GA_ReadOnly)
assert iobj

samples = iobj.RasterXSize
lines   = iobj.RasterYSize
nb      = iobj.RasterCount
band    = iobj.GetRasterBand(1)
noData  = band.GetNoDataValue()
band    = None

driver     = gdal.GetDriverByName("ENVI")
outDataset = driver.Create(outfile, samples, lines, nb, 6)
outDataset.SetMetadata(iobj.GetMetadata())
outDataset.SetGeoTransform(iobj.GetGeoTransform())
outDataset.SetProjection(iobj.GetProjection())

outband = []
for i in range(outnb):
    outband.append(outDataset.GetRasterBand(i+1))
    outband[i].SetNoDataValue(noData)

tiles = get_tiles.get_tile3(samples, lines, xtile=samples, ytile=1)

for tile in tiles:
    ystart = int(tile[0])
    yend   = int(tile[1])
    xstart = int(tile[2])
    xend   = int(tile[3])

    xsize = int(xend - xstart)
    ysize = int(yend - ystart)

    subset = iobj.ReadAsArray(xstart, ystart, xsize, ysize)

    for i in range(subset.shape[0]):
        #outband = outDataset.GetRasterBand(i+1)
        #outband.WriteArray(subset[i], xstart, ystart)
        outband[i].WriteArray(subset[i], xstart, ystart)
        #outband.SetNoDataValue(noData)
        #outband.FlushCache()
        #outband = None
    
outDataset = None
