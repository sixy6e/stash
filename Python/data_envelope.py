#!/usr/bin/env python

import os
import numpy
import argparse
from datetime import datetime
from osgeo import gdal
from osgeo import ogr
from osgeo import osr

try:
    from ULA3.dataset import SceneDataset as SD
except ImportError:
    print 'ULA3.dataset not found! Function getImageDataEnvelope() will only work for single files.'
from image_tools import map2img

def getImageDataEnvelope(dataset):
    """
    Extracts the envelope (min/max extents) for valid data areas from a given dataset.

    :param dataset:
        If dataset is directory then the SceneDataset class will attempt to read
        the files contained within.
        If dataset is a path to an image file, then GDAL will be used directly
        on the single file.
        In either case, dataset should be a full filepath.

    :return:
        A tuple in the form (ystart, ystop, xstart, xstop). This refers to the
        start and stop index for both the y & x (lines, samples) dimensions.

    :notes:
        GDAL will attempt to retrive the no-data value. If this is None then
        a no-data value of 0 (Zero) will be used.
        The ystop and xstop array indices will be 1 more than expect. This is 
        to account for Python's exclusive behaviour for the righmost index.

    :author:
        Josh Sixsmith; josh.sixsmith@gmail.com, joshua.sixsmith@ga.gov.au

    :history:
        * 18/06/2014--Created

    """

    # Check that the directory or file exists
    if not os.path.exists(dataset):
        raise Exception('Error! Dataset could not be found!!! Dataset: %s' %dataset)

    # Open the dataset
    # A weak check for dealing with either a single file or a directory
    if os.path.isdir(dataset):
        ds = SD(dataset)
    else:
        ds = gdal.Open(dataset)

    # Retrieve the GeoTransform and Projection info
    geoT = ds.GetGeoTransform()
    prj  = ds.GetProjection()

    # Get array dimensions
    samples = ds.RasterXSize
    lines   = ds.RasterYSize
    bands   = ds.RasterCount

    # Need to handle a NoData value. Default to zero
    b = ds.GetRasterBand(1)
    noData = b.GetNoDataValue()
    if noData == None:
        noData = 0

    # Read the entire dataset. This part will take a large portion of memory
    img = ds.ReadAsArray()

    # Now to find only data areas. Need to handle the case where we have only 1 band
    if bands > 1:
        data = numpy.any(img != noData, axis=0)
    else:
        data = numpy.any(img != noData)

    # Cleanup
    del img

    # Now to create an in-memory GDAL dataset
    img_drv = gdal.GetDriverByName("MEM")
    memds   = img_drv.Create("Memory Dataset", samples, lines, 1, gdal.GDT_Byte)
    memds.SetGeoTransform(geoT)
    memds.SetProjection(prj)
    memds.GetRasterBand(1).WriteArray(data)

    # Now to retrieve the source dataset
    srcband = memds.GetRasterBand(1)

    # Setup the base projection to be used by the vector file
    vprj = osr.SpatialReference()
    vprj.ImportFromWkt(prj)

    # Create the vector dataset
    vec   = ogr.GetDriverByName('Memory').CreateDataSource('')
    layer = vec.CreateLayer('Mask', geom_type=ogr.wkbPolygon, srs=vprj)

    # Polygonize the raster
    gdal.Polygonize(srcband, srcband, layer, -1, ["8CONNECTED"], None)

    # Get the extents of the vector
    extents = layer.GetExtent() # Returns (xmin, xmax, ymin, ymax)

    # Just handle for Australia for the time being
    # TODO
    # Need to handle the case for Northern/Southern & Eastern/Western Hemispheres
    UL = (extents[0], extents[3])
    LR = (extents[1], extents[2])

    # Convert each co-ordinate into an image co-ordinate
    UL_img = map2img(geoT, UL)
    LR_img = map2img(geoT, LR)

    # Create the index
    ystart = UL_img[0]
    ystop  = LR_img[0] + 1 # Account for Python's exclusive rightmost index
    xstart = UL_img[1]
    xstop  = LR_img[1] + 1 # Account for Python's exclusive rightmost index

    return (ystart, ystop, xstart, xstop)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Extracts the envelope (min/max) extents from a given dataset.')
    parser.add_argument('--dataset', required=True, help='The input dataset from which to extract the envelope of the valid data.')

    # Collect all the passed arguments
    parsed_args = parser.parse_args()

    # Initialise process timing
    st = datetime.now()

    # Get the index referring to the envelope
    idx = getImageDataEnvelope(parsed_args.dataset)

    # Finalise process timing
    et = datetime.now()

    print "The array indices are:"
    print "Row Start:    %i\nRow Stop:     %i\nColumn Start: %i\nColumn End:   %i\n" %idx
    print "Total time taken:"
    print et - st

