#!/usr/bin/env python

import os
import sys

from osgeo import gdal


def process_image_band(imgpath=None, band_number=1, mode=gdal.gdalconst.GA_ReadOnly):

    if not imgpath:
        print 'ERROR: imgpath unspecified'
        return

    if not os.path.exists(imgpath):
        print 'ERROR: file not found (%s)' % imgpath
        return

    fobj = gdal.Open(imgpath, mode)
    assert fobj

    metadata = fobj.GetMetadata_Dict()

    band = fobj.GetRasterBand(band_number)

    if band is None:
        print 'ERROR: GetRasterBand FAILED'
        return

    x_size = band.x_size
    y_size = band.y_size
    data_type = gdal.GetDataTypeName(band.DataType)
    data = band.ReadAsArray()

    # ...do something useful with data (numpy array)...



if __name__ == '__main__':

    # usage: junk.py myfile.tif

    process_image_band(sys.argv[1])