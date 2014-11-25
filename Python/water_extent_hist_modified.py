#!/usr/bin/env python

import os
import glob
import sys
import logging
import argparse
import textwrap

# Debugging
import pdb

import numpy
from osgeo import gdal
from osgeo import ogr

import pandas

# ga-neo-nfrip repo
from WaterExtent import WaterExtent
from fileSystem import Directory

# IDL_functions repo
from IDL_functions import histogram

# image_processing repo
from image_processing.segmentation.rasterise import Rasterise
from image_processing.segmentation.segmentation import SegmentVisitor

def getFiles(path, pattern):
    """
    Just an internal function to find files given an file extension.
    This isn't really designed to go beyond development demonstration
    for this analytical workflow.
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
    Given a list of water extent image files, create a list of
    waterExtent class objects, and if sort by time, old -> new, if
    sort=True.

    :param file_list:
        A list containing filepath names to water extent image files.

    :param sort:
        A boolean keyword indicating if the waterExtent objects
        should be sorted before they're returned. Default is True.

    :return:
        A list of waterExtent class objects, one for every water
        image file in file_list, and optionally sorted by date,
        old -> new.
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

def tiled_main(vector_file, cell_list, indir, outdir, pattern, logpath):
    """
    
    """
    # setup logging file ... log to <outputPath>/../logs/createWaterExtent_<hostname>_pid.log
    logPath = os.path.join(logpath,"waterExtentVectorSummary_%s_%d.log" % (os.uname()[1], os.getpid()))
    logging.basicConfig(filename=logPath,format='%(asctime)s %(levelname)s: %(message)s', datefmt='%d/%m/%Y %H:%M:%S', level=logging.INFO)

    baseOutputDir = Directory(outdir)
    if not baseOutputDir.exists():
        logging.error("%s does not exist" % baseOutputDir.getPath())
        sys.exit(1)

    logging.info("Opening vector file %s" %vector_file)
    vec_ds  = ogr.Open(vector_file)
    layer   = vec_ds.GetLayer()

    # Initialise dicts to hold feature names, and hydro_id
    feature_names = {}
    hydro_id      = {}

    # Dicts to hold forward and backward mapping of fid's and seg id's
    seg2fid = {}
    fid2seg = {}

    fid_list = []

    fid_df = {}

    logging.info("Gathering attribute information for each feature.")
    # These Field Id's are unique to NGIG's vector datasets
    for feature in layer:
        fid                = feature.GetFID()
        feature_names[fid] = feature.GetField("NAME")
        hydro_id[fid]      = feature.GetField("AUSHYDRO_I")
        seg2fid[fid+1]     = fid
        fid2seg[fid]       = fid + 1
        fid_list.append(fid)
        fid_df[fid] = pandas.DataFrame()

    # Initialise the dataframe to store the results
    df = pandas.DataFrame()
    df['FID'] = fid_list.sort()

    nfeatures = len(fid_list)
    min_fid = df['FID'].min()
    max_fid = df['FID'].max()

    # We offset the min and max fid's by 1 as the rasterisation will be
    # created that way
    h = histogram(numpy.zeros((10), dtype='int32'), Max=max_fid+1, Min=min_fid+1)
    # This will be used as the input keyword and changes will be made in place
    t_area = h['histogram']

    for cell in cell_list:
        celldir = os.path.join(indir, cell)
        # processing here
        result_df = tiled_processing(vector_file, t_area, min_fid, max_fid, celldir, pattern)
        # We don't need to define cols up front
        # We can define an empty dataframe and append to it
        # That way cols can be defined within the script
        # but how do we combine records of the same fid, & date but different cell???
        # do we need to know the cols then? maybe cols should only contain counts???
        for key in result_df:
            fid_df[key] = fid_df[key].append(result_df, ignore_index=True)

    # Combine FIDs with identical timestamps and sum the pixel counts
    # Including the hydro_id and fid as groupby's should exclude them from
    # the summation.
    # The filename and Feature Name fields will be removed as a result of the
    # summation. Feature Name could potentially be kept
    group_items = ['Time Stamp', 'AUSHYDRO_ID', 'FID']
    for key in fid_df:
        fid_df[key] = fid_df[key].groupby(group_items).sum()

    # Now to output files
    fname1 = os.path.join(outdir, 'result_combined.xls')
    excel_file1 = pandas.ExcelWriter(fname1)

    combined_df = pandas.DataFrame()

    fname2 = os.path.join(outdir, 'result_multiple_sheets.xls')
    excel_file2 = pandas.ExcelWriter(fname2)

    for key in fid_df:
        sheet_name = 'FID {fid}'.format({'fid': key})
        fid_df[key].to_excel(excel_file2, sheet_name)
        combined_df = combined_df.append(fid_df[key])
        fid_df[key] = None # Attempt to conserve memory

    combined_df.to_excel(excel_file1, 'Sheet1')

    excel_file1.save()
    excel_file2.save()


def tiled_processing(vector_file, input_hist, Min_id, Max_id, indir, pattern):
    """
    The main processing routine.

    :param indir:
        A string containing the file system pathname to a directory
        containing the water extent image files.

    :param outdir:
        A string containing the file system pathname to a directory
        that will contain the result output.

    :param logpath:
        A string containing the file system pathname to a directory
        that will contain the operation system logging information.

    :param pattern:
        A string containing the image extents file extension pattern,
        eg '*.tif'.

    :param vector_file:
        A string containing the file system pathname to an OGR
        compatible vector file.

    :param outfname):
        A string containing the ststem file pathname for the output
        csv file.

    :return:
        Nothing, main() acts as a procedure.
    """




    # Get a list of water_extent files
    files = getFiles(indir, pattern)

    # Get the water_extent objects and sort them by date
    sortedWaterExtents, cellId = getWaterExtents(files)

    # lat and lon will be helpful
    lon = cellId[0]
    lat = cellId[1]

    logging.info("output directory is %s" %outputDir.getPath())

    # Rasterise the features
    # We can use the first image file as the base
    segments_ds = Rasterise(RasterFilename=files[0], VectorFilename=vector_file)
    logging.info("Rasterising features.")
    segments_ds.rasterise()

    # Extract the array
    veg2rast = segments_ds.segemented_array

    # Initialise the segment visitor
    seg_vis = SegmentVisitor(veg2rast)

    # Update the total area (recursive histogram technique)
    # input keyword modifies in-place
    recursive_h = histogram(veg2rast, input=input_hist, Min=Min_id, Max=Max_id)

    # Get specific attribute records
    logging.info("Opening vector file %s" %vector_file)
    vec_ds  = ogr.Open(vector_file)
    layer   = vec_ds.GetLayer()

    # Define the headings for the data frame
    headings = ["Filename", "Time Stamp", "Feature Name", "AUSHYDRO_ID",
                "FID", "Total Pixel Count", "WATER_NOT_PRESENT",
                "NO_DATA", "MASKED_NO_CONTIGUITY",
                "MASKED_SEA_WATER", "MASKED_TERRAIN_SHADOW",
                "MASKED_HIGH_SLOPE", "MASKED_CLOUD_SHADOW",
                "MASKED_CLOUD", "WATER_PRESENT"]

    # Initialise dicts to hold feature names, hydro_id and data frame
    feature_names = {}
    hydro_id      = {}
    fid_df        = {}

    # Dicts to hold forward and backward mapping of fid's and seg id's
    seg2fid = {}
    fid2seg = {}

    logging.info("Gathering attribute information for each feature.")
    # These Field Id's are unique to NGIG's vector datasets
    for feature in layer:
        fid                = feature.GetFID()
        feature_names[fid] = feature.GetField("NAME")
        hydro_id[fid]      = feature.GetField("AUSHYDRO_I")
        seg2fid[fid+1]     = fid
        fid2seg[fid]       = fid + 1
        fid_df[fid] = pandas.DataFrame(columns=headings)

    # Go back to the start of the vector file
    layer.ResetReading()

    # Replace any occurences of None with UNKNOWN
    for key in feature_names.keys():
        if feature_names[key] == None:
            feature_names[key] = 'UNKNOWN'

    # TODO Define dict lookup for potential segments up to max segment

    # Loop over each WaterExtent file
    for waterExtent in sortedWaterExtents:
        logging.info("Processing %s" % waterExtent.filename)


        # Read the waterLayer from the extent file
        waterLayer = waterExtent.getArray()

        # timestamp
        timestamp = waterLayer.timestamp
        #str_time = timestamp.strftime('%Y-%m-%d %H:%M:%S.%f')

        # Loop over each feature Id
        # Skip any FID's that don't exist in the current spatial extent
        for key in fid2seg.keys():
            if fid2seg[key] > seg_vis.max_segID:
                continue
            data = seg_vis.getSegmentData(waterLayer, segmentID=fid2seg[key])
            dim  = data.shape
            #pdb.set_trace()
            # Returns are 1D arrays, so check if we have an empty array
            if dim[0] == 0:
                continue # Empty bin, (no data), skipping
            FID = seg2fid[key]
            h    = histogram(data, Min=0, Max=128)
            hist = h['histogram']
            total_area = dim[0]


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

            # [0..128] bins were generated, i.e 129 bins
            WATER_NOT_PRESENT     = hist[0]
            NO_DATA               = hist[1]
            MASKED_NO_CONTIGUITY  = hist[2]
            MASKED_SEA_WATER      = hist[4]
            MASKED_TERRAIN_SHADOW = hist[8]
            MASKED_HIGH_SLOPE     = hist[16]
            MASKED_CLOUD_SHADOW   = hist[32]
            MASKED_CLOUD          = hist[64]
            WATER_PRESENT         = hist[128]

            format_dict = {'Filename': waterExtent.filename,
                           'Time Stamp': timestamp,
                           'Feature Name': feature_names[key],
                           'AUSHYDRO_ID': hydro_id[key],
                           'FID': FID,
                           'Total Pixel Count': total_area,
                           'WATER_NOT_PRESENT': WATER_NOT_PRESENT,
                           'NO_DATA': NO_DATA,
                           'MASKED_NO_CONTIGUITY': MASKED_NO_CONTIGUITY,
                           'MASKED_SEA_WATER': MASKED_SEA_WATER,
                           'MASKED_TERRAIN_SHADOW': MASKED_TERRAIN_SHADOW,
                           'MASKED_HIGH_SLOPE': MASKED_HIGH_SLOPE,
                           'MASKED_CLOUD_SHADOW': MASKED_CLOUD_SHADOW,
                           'MASKED_CLOUD': MASKED_CLOUD,
                           'WATER_PRESENT': WATER_PRESENT}

            # Append the new data to the FID data frame
            fid_df[FID] = fid_df[FID].append(format_dict, ignore_index=True)

    return fid_df


def main(indir, outdir, logpath, pattern, vector_file, outfname):
    """
    The main processing routine.

    :param indir:
        A string containing the file system pathname to a directory
        containing the water extent image files.

    :param outdir:
        A string containing the file system pathname to a directory
        that will contain the result output.

    :param logpath:
        A string containing the file system pathname to a directory
        that will contain the operation system logging information.

    :param pattern:
        A string containing the image extents file extension pattern,
        eg '*.tif'.

    :param vector_file:
        A string containing the file system pathname to an OGR
        compatible vector file.

    :param outfname):
        A string containing the ststem file pathname for the output
        csv file.

    :return:
        Nothing, main() acts as a procedure.
    """

    # setup logging file ... log to <outputPath>/../logs/createWaterExtent_<hostname>_pid.log
    logPath = os.path.join(logpath,"waterExtentVectorSummary_%s_%d.log" % (os.uname()[1], os.getpid()))
    logging.basicConfig(filename=logPath,format='%(asctime)s %(levelname)s: %(message)s', datefmt='%d/%m/%Y %H:%M:%S', level=logging.INFO)


    baseOutputDir = Directory(outdir)
    if not baseOutputDir.exists():
        logging.error("%s does not exist" % baseOutputDir.getPath())
        sys.exit(1)

    # Get a list of water_extent files
    files = getFiles(indir, pattern)

    # Get the water_extent objects and sort them by date
    sortedWaterExtents, cellId = getWaterExtents(files)

    # lat and lon will be helpful
    lon = cellId[0]
    lat = cellId[1]

    # we output to a lon_lat subdirectory in the base output directory
    # create it
    outputPath = "%s/%03d_%04d" % (baseOutputDir.getPath(), lon, lat)
    outputDir = Directory(outputPath)
    outputDir.makedirs()
    logging.info("output directory is %s" %outputDir.getPath())

    # Rasterise the features
    # We can use the first image file as the base
    segments_ds = Rasterise(RasterFilename=files[0], VectorFilename=vector_file)
    logging.info("Rasterising features.")
    segments_ds.rasterise()

    # Extract the array
    veg2rast = segments_ds.segemented_array

    # Initialise the segment visitor
    seg_vis = SegmentVisitor(veg2rast)

    # Get specific attribute records
    logging.info("Opening vector file %s" %vector_file)
    vec_ds  = ogr.Open(vector_file)
    layer   = vec_ds.GetLayer()

    # Initialise dicts to hold feature names, and hydro_id
    feature_names = {}
    hydro_id      = {}

    # Dicts to hold forward and backward mapping of fid's and seg id's
    seg2fid = {}
    fid2seg = {}

    logging.info("Gathering attribute information for each feature.")
    # These Field Id's are unique to NGIG's vector datasets
    for feature in layer:
        fid                = feature.GetFID()
        feature_names[fid] = feature.GetField("NAME")
        hydro_id[fid]      = feature.GetField("AUSHYDRO_I")
        seg2fid[fid+1]     = fid
        fid2seg[fid]       = fid + 1

    # Go back to the start of the vector file
    layer.ResetReading()

    # Replace any occurences of None with UNKNOWN
    for key in feature_names.keys():
        if feature_names[key] == None:
            feature_names[key] = 'UNKNOWN'

    # TODO Define dict lookup for potential segments up to max segment

    # Initialise the output file
    full_fname = os.path.join(outputDir.getPath(), outfname)
    logging.info("Creating output summary file %s"%full_fname)
    outcsv = open(full_fname, 'w')

    # Define the headings for the output file
    headings = ("Time Slice, Time Stamp, Feature Name, AUSHYDRO_ID, "
                "FID, Total Pixel Count, WATER_NOT_PRESENT, "
                "NO_DATA, MASKED_NO_CONTIGUITY, "
                "MASKED_SEA_WATER, MASKED_TERRAIN_SHADOW, "
                "MASKED_HIGH_SLOPE, MASKED_CLOUD_SHADOW, "
                "MASKED_CLOUD, WATER_PRESENT\n")

    # Write the headings to disk
    outcsv.write(textwrap.dedent(headings))

    # Loop over each WaterExtent file
    for waterExtent in sortedWaterExtents:
        logging.info("Processing %s" % waterExtent.filename)


        # Read the waterLayer from the extent file
        waterLayer = waterExtent.getArray()

        # timestamp
        timestamp = waterLayer.timestamp
        str_time = timestamp.strftime('%Y-%m-%d %H:%M:%S.%f')

        # Loop over each feature Id
        # Skip any FID's that don't exist in the current spatial extent
        for key in fid2seg.keys():
            if fid2seg[key] > seg_vis.max_segID:
                continue
            data = seg_vis.getSegmentData(waterLayer, segmentID=fid2seg[key])
            dim  = data.shape
            #pdb.set_trace()
            # Returns are 1D arrays, so check if we have an empty array
            if dim[0] == 0:
                continue # Empty bin, (no data), skipping
            h    = histogram(data, Min=0, Max=128)
            hist = h['histogram']
            total_area = dim[0]


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

            # [0..128] bins were generated, i.e 129 bins
            WATER_NOT_PRESENT     = hist[0]
            NO_DATA               = hist[1]
            MASKED_NO_CONTIGUITY  = hist[2]
            MASKED_SEA_WATER      = hist[4]
            MASKED_TERRAIN_SHADOW = hist[8]
            MASKED_HIGH_SLOPE     = hist[16]
            MASKED_CLOUD_SHADOW   = hist[32]
            MASKED_CLOUD          = hist[64]
            WATER_PRESENT         = hist[128]

            # Now to output counts per feature
            # TODO update to Python's newer version of string insertion
            #s = "%s, %s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d\n" %(waterExtent.filename,
            #                                                             str_time,
            #                                                             feature_names[key],
            #                                                             hydro_id[key],
            #                                                             total_area,
            #                                                             WATER_NOT_PRESENT,
            #                                                             NO_DATA,
            #                                                             MASKED_NO_CONTIGUITY,
            #                                                             MASKED_SEA_WATER,
            #                                                             MASKED_TERRAIN_SHADOW,
            #                                                             MASKED_HIGH_SLOPE,
            #                                                             MASKED_CLOUD_SHADOW,
            #                                                             MASKED_CLOUD,
            #                                                             WATER_PRESENT)

            s = ('{fname}, {timestamp}, {feature_name}, {hydro_id}, {FID}, '
                 '{area}, {not_water}, {no_data}, {contiguity}, {sea}, '
                 '{terrain}, {slope}, {cloud_shadow}, {cloud}, {water}\n')

            format_dict = {'fname': waterExtent.filename,
                           'timestamp': str_time,
                           'feature_name': feature_names[key],
                           'hydro_id': hydro_id[key],
                           'FID': seg2fid[key],
                           'area': total_area,
                           'not_water': WATER_NOT_PRESENT,
                           'no_data': NO_DATA,
                           'contiguity': MASKED_NO_CONTIGUITY,
                           'sea': MASKED_SEA_WATER,
                           'terrain': MASKED_TERRAIN_SHADOW,
                           'slope': MASKED_HIGH_SLOPE,
                           'cloud_shadow': MASKED_CLOUD_SHADOW,
                           'cloud': MASKED_CLOUD,
                           'water': WATER_PRESENT}

            s.format(format_dict)
            outcsv.write(s)

    outcsv.close()


if __name__ == '__main__':

    description = 'Reports area counts per feature for a given vector file.'

    parser = argparse.ArgumentParser(description)
    parser.add_argument('--outdir', dest="baseOutputPath", help="Output base directory.", required=True)
    parser.add_argument('--log', dest="logPath", help="Directory where log files will be written.", required=True)
    parser.add_argument('--indir', required=True, help="Input directory containing water extent files.")
    parser.add_argument('--sfx', default='*.tif', help="File suffix to search for. Default is '*.tif'")
    parser.add_argument('--vector', required=True, help="An OGR compatible vector file.")
    parser.add_argument('--outname', default='WaterExtentVectorSummary.csv', help="The name of the output file to contain the summary. Default is 'WaterExtentVectorSummary.csv'.")

    # Collect the arguments
    args = parser.parse_args()

    # Retrieve command arguments
    baseOutputPath = args.baseOutputPath
    log            = args.logPath
    path           = args.indir
    pattern        = args.sfx
    vector_file    = args.vector
    outfname       = args.outname
    
    # Run
    #main(indir=path, outdir=baseOutputPath, logpath=log, pattern=pattern,
    #     vector_file=vector_file, outfname=outfname)

    cell_list = ['144_-041', '145_-041', '147_-041', '148_-041', '145_-042',
                 '146_-042', '147_-042', '148_-042', '145_-043', '146_-043',
                 '147_-043', '146_-044']

    #cell_list = ['144_-041']

    tiled_main(vector_file, cell_list, path, baseOutputPath, pattern, log)
