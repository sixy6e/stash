#!/usr/bin/env python

import os
import glob
import traceback
import sys
import re
import copy
import logging
import argparse
from osgeo import gdal
from osgeo import ogr
from WaterSummary import WaterSummary
from WaterExtent import WaterExtent
from datetime import datetime, time
from fileSystem import *
from jobControl import WorkUnit
from IDL_functions import histogram


def getFiles(path, pattern):
    """
    """

    # Get the current directory so we can change back later
    CWD = os.getcwd()

    os.chdir(path)

    # Find the files matching the pattern
    files = glob.glob(pattern)
    files = [os.path.abspath(i) for i in files]

    # Change back to the original directory
    os.chdir(CWD)

    return files

def getWaterExtents(file_list, sort=True):
    """
    """

    waterExtents = []
    cellId = None

    for f in file_list:
        waterExtent = WaterExtent(f)

        # check for lon, lat consistency
        if cellId:
            thisCellId = [waterExtent.lon, waterExtent.lat]
            if thisCellId != cellId:
                logging.error("Extents must be from same cell. At file %s got %s, expecting %s" % (f, thisCellId, cellId))
                sys.exit(1)
        else:
            cellId = [waterExtent.lon, waterExtent.lat]

        waterExtents.append(waterExtent)

    if sort:
        # all good, so now sort the extents by datetime
        logging.info("Collected %d files. Now sort them." % len(file_list))
        sortedWaterExtents = sorted(waterExtents, key=lambda extent: extent.getDatetime())
        return (sortedWaterExtents, cellId)
    else:
        logging.info("Collected %d files. Sorting not applied." % len(file_list))
        return (waterExtents, cellId)


if __name__ == '__main__':

    description = 'Reports area counts per feature for a given vector file.'

    parser = argparse.ArgumentParser(description)
    parser.add_argument('--outdir', dest="baseOutputPath", help="Output base directory.", required=True)
    parser.add_argument('--log', dest="logPath", help="Directory where log files will be written.", required=True)
    parser.add_argument('--indir', required=True, help="Input directory containing water extent files.")
    parser.add_argument('--sfx', default='*.tif', help="File suffix to search for. Default is '*.tif'")
    parser.add_argument('--vector', required=True, help="An OGR compatible vector file.")
    parser.add_argument('--outname', default='WaterExtentVectorSummary.csv', help="The name of the output file to contain the summary. Default is 'WaterExtentVectorSummary.csv'.")

    args = parser.parse_args()

    # Retrieve command arguments
    baseOutputPath = args.baseOutputPath
    log            = args.logPath
    path           = args.indir
    pattern        = args.sfx
    vector_file    = args.vector
    outfname       = args.outname
    
    # setup logging file ... log to <outputPath>/../logs/createWaterExtent_<hostname>_pid.log
    logPath = os.path.join(log,"waterExtentVectorSummary_%s_%d.log" % (os.uname()[1], os.getpid()))
    logging.basicConfig(filename=logPath,format='%(asctime)s %(levelname)s: %(message)s', datefmt='%d/%m/%Y %H:%M:%S', level=logging.INFO)


    baseOutputDir = Directory(baseOutputPath)
    if not baseOutputDir.exists():
        logging.error("%s does not exist" % baseOutputDir.getPath())
        sys.exit(1)


    # TODO
    # Re-write so that WaterExtents sorted or unsorted are function based
    # That way we keep a more general interface

    # Get a list of water_extent files
    #files = getFiles(path, pattern)

    # Get the water_extent objects and sort them by date
    #sortedWaterExtents, cellID = getWaterExtents(files)

    # Get the current directory so we can change back later
    CWD = os.getcwd()

    os.chdir(path)

    # Find the files matching the pattern
    files = glob.glob(pattern)
    files = [os.path.abspath(f) for f in files]

    # Change back to the original directory
    os.chdir(CWD)

    waterExtents = []
    cellId = None

    for f in files:
        waterExtent = WaterExtent(f)

        # check for lon, lat consistency
        if cellId:
            thisCellId = [waterExtent.lon, waterExtent.lat]
            if thisCellId != cellId:
                logging.error("Extents must be from same cell. At file %s got %s, expecting %s" % (f, thisCellId, cellId))
                sys.exit(1)
        else:
            cellId = [waterExtent.lon, waterExtent.lat]

        waterExtents.append(waterExtent)

    # all good, so now sort the extents by datetime
    logging.info("Collected %d files. Now sort them." % len(files))
    sortedWaterExtents = sorted(waterExtents, key=lambda extent: extent.getDatetime())

    # now we can build all summaries
    logging.info("Sorting done, starting analysis")
    
    # lat and lon will be helpful
    lon = cellId[0]
    lat = cellId[1]

    # we output to a lon_lat subdirectory in the base output directory
    # create it
    outputPath = "%s/%03d_%04d" % (baseOutputDir.getPath(), lon, lat)
    outputDir = Directory(outputPath)
    outputDir.makedirs()
    logging.info("output directory is %s" %outputDir.getPath())

   
    logging.info("Opening vector file %s" %vector_file)
    vec_ds  = ogr.Open(vector_file)
    layer   = vec_ds.GetLayer()
    lyr_cnt = layer.GetFeatureCount()

    # Get the feature names
    feature_names = []
    hydro_id      = []
    for feature in layer:
        feature_names.append(feature.GetField("NAME"))
        #hydro_id.append(feature.GetField("AUSHYDRO_I"))
        hydro_id.append(feature.GetField("PID"))
    layer.ResetReading()

    # Replace any occurences of None with UNKNOWN
    for idx, item in enumerate(feature_names):
        if item == None:
            feature_names[idx] = 'UNKNOWN'

    # We need to extract info from the source dataset in order to generate a new one
    source_ds = gdal.Open(files[0])
    samples   = source_ds.RasterXSize
    lines     = source_ds.RasterYSize
    geoT      = source_ds.GetGeoTransform()
    prj       = source_ds.GetProjection()
    source_ds = None

    logging.info("Creating in-memory GDAL object")
    drv = gdal.GetDriverByName("MEM")
    #outds = drv.Create('memory', samples, lines, 1, gdal.GDT_Byte) # If more than 255 features....
    outds = drv.Create('memory', samples, lines, 1, gdal.GDT_UInt32)
    outds.SetGeoTransform(geoT)
    outds.SetProjection(prj)

    logging.info("Rasterizing each feature")
    # Loop over n features burning 1 to n into the raster
    # GDAL.RasterizeLayer() doesn't work on individual features
    # We can burn all the features at once, then label them
    # or build a layer from each feature.
    # We might be able to give it an SQl query?
    # Select by attribute FID will leave only a single feature in the layer active
    for i in range(layer.GetFeatureCount()):
        layer.SetAttributeFilter("FID = %d"%i)
        burn = i + 1
        gdal.RasterizeLayer(outds, [1], layer, burn_values=[burn])
        layer.SetAttributeFilter(None)

    # Retrieve the rasterised vector and delete the GDAL MEM dataset
    vec2rast = outds.ReadAsArray().flatten()
    outds    = None
    vec_ds   = None
    layer    = None

    # TODO
    # Need to sort out feature names with features that get rasterised
    # Hmmm, it might be ok

    # Calculate the histogram and the reverse indices of the rasterised vector
    h = histogram(vec2rast, min=1, reverse_indices='ri', omax='omax')
    hist = h['histogram']
    ri   = h['ri']
    omax = h['omax']

    # Get the indices for each bin
    idxs = []
    for i in range(hist.shape[0]):
        if hist[i] == 0:
            idxs.append(None) # An empty item
            continue
        idx = ri[ri[i]:ri[i+1]]
        idxs.append(idx)

    logging.info("Creating output summary file")

    outcsv = open(os.path.join(outputDir.getPath(), outfname), 'w')
    #headings = "Time Slice, Feature Name, AUSHYDRO_ID, Total Pixel Count, WATER_NOT_PRESENT, NO_DATA, MASKED_NO_CONTIGUITY, MASKED_SEA_WATER, MASKED_TERRAIN_SHADOW, MASKED_HIGH_SLOPE, MASKED_CLOUD_SHADOW, MASKED_CLOUD, WATER_PRESENT\n"
    headings = "Time Slice, Feature Name, PID, Total Pixel Count, WATER_NOT_PRESENT, NO_DATA, MASKED_NO_CONTIGUITY, MASKED_SEA_WATER, MASKED_TERRAIN_SHADOW, MASKED_HIGH_SLOPE, MASKED_CLOUD_SHADOW, MASKED_CLOUD, WATER_PRESENT\n"
    outcsv.write(headings)

    # Loop over each WaterExtent file
    for waterExtent in sortedWaterExtents:

        logging.info("Processing %s" % waterExtent.filename)

        # read the waterLayer from the extent
        waterLayer = waterExtent.getArray().flatten()

        # Loop over every feature in the rasterised vector
        for i in range(hist.shape[0]):
            if hist[i] == 0:
                continue # Empty bin
            h2 = histogram(waterLayer[idxs[i]], min=0, max=128)
            hist2 = h2['histogram']
            total_area = hist[i]

            """
            A WaterTile stores 1 data layer encoded as unsigned BYTE values as described in the WaterConstants.py file.

            Note - legal (decimal) values are:

                   0:  no water in pixel
                   1:  no data (one or more bands) in source NBAR image
               2-127:  pixel masked for some reason (refer to MASKED bits)
                 128:  water in pixel

            Values 129-255 are illegal (i.e. if bit 7 set, all others must be unset)


            WATER_PRESENT          (dec 128) bit 7: 1=water present, 0=no water if all other bits zero
            MASKED_CLOUD           (dec 64)  bit 6: 1=pixel masked out due to cloud, 0=unmasked
            MASKED_CLOUD_SHADOW    (dec 32)  bit 5: 1=pixel masked out due to cloud shadow, 0=unmasked
            MASKED_HIGH_SLOPE      (dec 16)  bit 4: 1=pixel masked out due to high slope, 0=unmasked
            MASKED_TERRAIN_SHADOW  (dec 8)   bit 3: 1=pixel masked out due to terrain shadow, 0=unmasked
            MASKED_SEA_WATER       (dec 4)   bit 2: 1=pixel masked out due to being over sea, 0=unmasked
            MASKED_NO_CONTIGUITY   (dec 2)   bit 1: 1=pixel masked out due to lack of data contiguity, 0=unmasked
            NO_DATA                (dec 1)   bit 0: 1=pixel masked out due to NO_DATA in NBAR source, 0=valid data in NBAR
            WATER_NOT_PRESENT      (dec 0)          All bits zero indicated valid observation, no water present
            """

            WATER_NOT_PRESENT     = hist2[0]
            NO_DATA               = hist2[1]
            MASKED_NO_CONTIGUITY  = hist2[2]
            MASKED_SEA_WATER      = hist2[4]
            MASKED_TERRAIN_SHADOW = hist2[8]
            MASKED_HIGH_SLOPE     = hist2[16]
            MASKED_CLOUD_SHADOW   = hist2[32]
            MASKED_CLOUD          = hist2[64]
            WATER_PRESENT         = hist2[128]

            # Now to output counts per feature
            s = "%s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d\n" %(waterExtent.filename,feature_names[i],hydro_id[i],total_area,
                                                                         WATER_NOT_PRESENT,NO_DATA,MASKED_NO_CONTIGUITY,
                                                                         MASKED_SEA_WATER,MASKED_TERRAIN_SHADOW,MASKED_HIGH_SLOPE,
                                                                         MASKED_CLOUD_SHADOW,MASKED_CLOUD,WATER_PRESENT)
            outcsv.write(s)

    outcsv.close()

