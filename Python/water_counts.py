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
from WaterSummary import WaterSummary
from WaterExtent import WaterExtent
from datetime import datetime, time
from fileSystem import *
from jobControl import WorkUnit
from IDL_functions import histogram
import pdb
import numpy


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

    description = 'Reports pixel counts per water extent time slice.'

    parser = argparse.ArgumentParser(description)
    parser.add_argument('--outdir', dest="baseOutputPath", help="Output base directory.", required=True)
    parser.add_argument('--log', dest="logPath", help="Directory where log files will be written.", required=True)
    parser.add_argument('--indir', required=True, help="Input directory containing water extent files.")
    parser.add_argument('--sfx', default='*.tif', help="File suffix to search for. Default is '*.tif'")
    parser.add_argument('--outname', default='WaterExtentYearMonthAggregateSummary.csv', help="The name of the output file to contain the summary. Default is 'WaterExtentYearMonthAggregateSummary.csv'.")

    args = parser.parse_args()

    # Retrieve command arguments
    baseOutputPath = args.baseOutputPath
    log            = args.logPath
    path           = args.indir
    pattern        = args.sfx
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
    logging.info("Sorting done, staring analysis")
    
    # lat and lon will be helpful
    lon = cellId[0]
    lat = cellId[1]

    # we output to a lon_lat subdirectory in the base output directory
    # create it
    outputPath = "%s/%03d_%04d" % (baseOutputDir.getPath(), lon, lat)
    outputDir = Directory(outputPath)
    outputDir.makedirs()
    logging.info("output directory is %s" %outputDir.getPath())

    #pdb.set_trace()

    logging.info("Creating output summary file")
    outcsv = open(os.path.join(outputDir.getPath(), outfname), 'w')
    #headings = "Time Slice, Feature Name, AUSHYDRO_ID, Total Pixel Count, WATER_NOT_PRESENT, NO_DATA, MASKED_NO_CONTIGUITY, MASKED_SEA_WATER, MASKED_TERRAIN_SHADOW, MASKED_HIGH_SLOPE, MASKED_CLOUD_SHADOW, MASKED_CLOUD, WATER_PRESENT\n"
    #headings = "Time Slice, WATER_NOT_PRESENT, NO_DATA, MASKED_NO_CONTIGUITY, MASKED_SEA_WATER, MASKED_TERRAIN_SHADOW, MASKED_HIGH_SLOPE, MASKED_CLOUD_SHADOW, MASKED_CLOUD, WATER_PRESENT\n"
    headings = "Year_Month, Count\n"
    outcsv.write(headings)

    # Get the year month for the first timeslice
    zeroYear  = sortedWaterExtents[0].year
    zeroMonth = sortedWaterExtents[0].month

    waterLayer = sortedWaterExtents[0].getArray().flatten()

    waterpres  = waterLayer == 128

    # Loop over each WaterExtent file
    for i in range(1, len(sortedWaterExtents)):

        logging.info("Processing %s" % sortedWaterExtents[i].filename)

        year  = sortedWaterExtents[i].year
        month = sortedWaterExtents[i].month

        # read the waterLayer from the extent
        waterLayer = sortedWaterExtents[i].getArray().flatten()

        if ((year == zeroYear) & (month == zeroMonth)):
            waterpres |= waterLayer == 128
        else:
            count = numpy.sum(waterpres)
            s = "%d_%d, %d\n" %(year, month, count)
            zeroYear = year
            zeroMonth = month
            outcsv.write(s)
            waterpres  = waterLayer == 128

        #h = histogram(waterLayer, min=0, max=128)
        #hist = h['histogram']

        #"""
        #A WaterTile stores 1 data layer encoded as unsigned BYTE values as described in the WaterConstants.py file.

        #Note - legal (decimal) values are:

        #       0:  no water in pixel
        #       1:  no data (one or more bands) in source NBAR image
        #   2-127:  pixel masked for some reason (refer to MASKED bits)
        #     128:  water in pixel

        #Values 129-255 are illegal (i.e. if bit 7 set, all others must be unset)


        #WATER_PRESENT          (dec 128) bit 7: 1=water present, 0=no water if all other bits zero
        #MASKED_CLOUD           (dec 64)  bit 6: 1=pixel masked out due to cloud, 0=unmasked
        #MASKED_CLOUD_SHADOW    (dec 32)  bit 5: 1=pixel masked out due to cloud shadow, 0=unmasked
        #MASKED_HIGH_SLOPE      (dec 16)  bit 4: 1=pixel masked out due to high slope, 0=unmasked
        #MASKED_TERRAIN_SHADOW  (dec 8)   bit 3: 1=pixel masked out due to terrain shadow, 0=unmasked
        #MASKED_SEA_WATER       (dec 4)   bit 2: 1=pixel masked out due to being over sea, 0=unmasked
        #MASKED_NO_CONTIGUITY   (dec 2)   bit 1: 1=pixel masked out due to lack of data contiguity, 0=unmasked
        #NO_DATA                (dec 1)   bit 0: 1=pixel masked out due to NO_DATA in NBAR source, 0=valid data in NBAR
        #WATER_NOT_PRESENT      (dec 0)          All bits zero indicated valid observation, no water present
        #"""

        #WATER_NOT_PRESENT     = hist[0]
        #NO_DATA               = hist[1]
        #MASKED_NO_CONTIGUITY  = hist[2]
        #MASKED_SEA_WATER      = hist[4]
        #MASKED_TERRAIN_SHADOW = hist[8]
        #MASKED_HIGH_SLOPE     = hist[16]
        #MASKED_CLOUD_SHADOW   = hist[32]
        #MASKED_CLOUD          = hist[64]
        #WATER_PRESENT         = hist[128]

        ## Now to output counts per feature
        #s = "%s, %d, %d, %d, %d, %d, %d, %d, %d, %d\n" %(waterExtent.filename,
        #                                                 WATER_NOT_PRESENT,
        #                                                 NO_DATA,
        #                                                 MASKED_NO_CONTIGUITY,
        #                                                 MASKED_SEA_WATER,
        #                                                 MASKED_TERRAIN_SHADOW,
        #                                                 MASKED_HIGH_SLOPE,
        #                                                 MASKED_CLOUD_SHADOW,
        #                                                 MASKED_CLOUD,
        #                                                 WATER_PRESENT)
        #outcsv.write(s)

    outcsv.close()

