#!/usr/bin/env python
import os
import sys
import logging
import errno
from datetime import datetime, time
import pdb
import re
import numpy

from osgeo import gdal
from stacker import Stacker
from ULA3.utils import log_multiline

# Set top level standard output 
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
console_formatter = logging.Formatter('%(message)s')
console_handler.setFormatter(console_formatter)

logger = logging.getLogger(__name__)
if not logger.level:
    logger.setLevel(logging.DEBUG) # Default logging level for all modules
    logger.addHandler(console_handler)

def extractPQFlags(array, flags=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1], invert=False, check_zero=False):
    """
    """

    # Specific bit positions for each PQ flag
    bits = [1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384, 32768]

    bit_shift = {1 : 0,
                 2 : 1,
                 4 : 2,
                 8 : 3,
                 16 : 4,
                 32 : 5,
                 64 : 6,
                 128 : 7,
                 256 : 8,
                 512 : 9,
                 1024 : 10,
                 2048 : 11,
                 4096 : 12,
                 8192 : 13,
                 16384 : 14,
                 32768 : 15
                }

    # image dimensions
    dims = array.shape
    if len(dims) != 2:
        raise Exception('Error. Array dimensions must be 2D, not %i' %len(dims))

    rows = dims[0]
    cols = dims[1]

    # Which flags have been set for extraction
    flags = [bits[i] for i, val in enumerate(flags) if val]

    # Setup the array to contain the n_bands per n_flags
    n_flags  = len(flags)
    pq_flags = numpy.zeros((n_flags,rows,cols), dtype='bool')

    if check_zero:
        zero = array == 0
        for i in range(n_flags):
            flag = flags[i]
            pq_flags[i] = (array & flag) >> bit_shift[flag]
            pq_flags[i][zero] = True
    else:
        for i in range(n_flags):
            flag = flags[i]
            pq_flags[i] = (array & flag) >> bit_shift[flag]

    if invert:
        return ~pq_flags
    else:
        return pq_flags

def pqCloud(file_path):
    """
    """

    # Open the PQ dataset
    ds = gdal.Open(file_path)

    # Number of bands, lines, samples
    nb = ds.RasterCount
    nl = ds.RasterYSize
    ns = ds.RasterXSize

    # Get the projection and geotransform parameters
    prj  = ds.GetProjection()
    geoT = ds.GetGeoTransform()

    # Initialise the output array
    clouds = numpy.zeros((2,nl,ns), dtype='uint16')


    # Case switch for saturation lookup
    #sat_idx_map = {'TM' : [sat1[0], sat2[0], sat3[0], sat4[0], sat5[0], satTherm[0], sat7[0]],
    #               'ETM+' : [sat1[1], sat2[1], sat3[1], sat4[1], sat5[1], satTherm[1], satTherm[2], sat7[1]]
    #              }
                  
    # Loop over the time series
    for i in range(1, nb + 1):
        # Band object
        band = ds.GetRasterBand(i)

        # PQ data
        PQdata = band.ReadAsArray()
        band.FlushCache()

        # Metadata
        md = band.GetMetadata_List()

        # Get the sensor
        #if 'satellite_tag=LS5' in md:
        #    sensor = 'TM'
        #else:
        #    sensor = 'ETM+'

        # Get the saturation flags
        #if sensor == 'TM': # Landsat 5
        #    pq_flags = extractPQFlags(PQdata, flags=[1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0], invert=True, check_zero=True)
        #    cloud    = extractPQFlags(PQdata, flags=[0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0], invert=True, check_zero=True)
        #    cloud    = cloud[0] | cloud[1]
        #else: # Landsat 7
        #    pq_flags = extractPQFlags(PQdata, flags=[1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0], invert=True, check_zero=True)
        cloud    = extractPQFlags(PQdata, flags=[0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0], invert=True, check_zero=True)
        #    cloud    = cloud[0] | cloud[1]

       # # Exclude cloud from the saturation count
       # for i in range(pq_flags.shape[0]):
       #     pq_flags[i][cloud] = False

        #if i == 1:
        #    write_img(pq_flags.astype('uint8'), name='test_pq_bits')

        # Update the saturation counts for each band
        #for i in range(len(sat_idx_map[sensor])):
        #    sat_idx_map[sensor][i] += pq_flags[i]

        for i in range(2):
            clouds[i] += cloud[i]

    #return (sat1, sat2, sat3, sat4, sat5, satTherm, sat7, prj, geoT)
    return (clouds, prj, geoT)

def write_img(array, name='', format='ENVI', projection=None, geotransform=None):
    """
    Write a 2D/3D image to disk using GDAL.

    :param array:
        A 2D/3D Numpy array.

    :param name:
        A string containing the output file name.

    :param format:
        A string containing a GDAL compliant image format. Default is 'ENVI'.

    :param projection:
        A variable containing the projection information of the array.

    :param geotransform:
        A variable containing the geotransform information for the array.

    :author:
        Josh Sixsmith, joshua.sixsmith@ga.gov.au

    :history:
        * 04/09/2013--Created
    """
    dims   = array.shape
    if (len(dims) == 2):
        samples = dims[1]
        lines   = dims[0]
        bands   = 1
    elif (len(dims) == 3):
        samples = dims[2]
        lines   = dims[1]
        bands   = dims[0]
    else:
        print 'Input array is not of 2 or 3 dimensions!!!'
        print 'Array dimensions: ', len(dims)
        return

    dtype  = datatype(array.dtype.name)
    driver = gdal.GetDriverByName(format)
    outds  = driver.Create(name, samples, lines, bands, dtype)

    if (projection != None):
        outds.SetProjection(projection)

    if (geotransform != None):
        outds.SetGeoTransform(geotransform)

    if (bands > 1):
        for i in range(bands):
            band   = outds.GetRasterBand(i+1)
            band.WriteArray(array[i])
            band.FlushCache()
    else:
        band   = outds.GetRasterBand(1)
        band.WriteArray(array)
        band.FlushCache()

    outds = None

def datatype(val):
    """
    Provides a map to convert a numpy datatype to a GDAL datatype.

    :param val:
        A string numpy datatype identifier, eg 'uint8'.

    :return:
        An integer that corresponds to the equivalent GDAL data type.

    :author:
        Josh Sixsmith, joshua.sixsmith@ga.gov.au
    """
    instr = str(val)
    return {
        'uint8'     : 1,
        'uint16'    : 2,
        'int16'     : 3,
        'uint32'    : 4,
        'int32'     : 5,
        'float32'   : 6,
        'float64'   : 7,
        'complex64' : 8,
        'complex64' : 9,
        'complex64' : 10,
        'complex128': 11,
        'bool'      : 1
        }.get(instr, 7)

def cleanup(filelist):
    """
    Cleanup the intermediate files that were generated.
    Method taken from:
    http://stackoverflow.com/questions/10840533/most-pythonic-way-to-delete-a-file-which-may-not-exist
    """
    for f in filelist:
        try:
            os.remove(f)
        except OSError as e:
            if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
                raise # re-raise exception if a different error occured

if __name__ == '__main__':
    def date2datetime(input_date, time_offset=time.min):
        if not input_date:
            return None
        return datetime.combine(input_date, time_offset)

    stacker = Stacker()

    # Check for required command line parameters
    assert stacker.x_index, 'Tile X-index not specified (-x or --x_index)'
    assert stacker.y_index, 'Tile Y-index not specified (-y or --y_index)'
    assert stacker.output_dir, 'Output directory not specified (-o or --output)'
    assert os.path.isdir(stacker.output_dir), 'Invalid output directory specified (-o or --output)'
    stacker.output_dir = os.path.abspath(stacker.output_dir)

    log_multiline(logger.debug, stacker.__dict__, 'stacker.__dict__', '\t')

    # Stacker object already has command line parameters
    # that disregard_incomplete_data is set to True for command line invokation
    stack_info_dict = stacker.stack_tile(x_index=stacker.x_index,
                                         y_index=stacker.y_index,
                                         stack_output_dir=stacker.output_dir,
                                         start_datetime=date2datetime(stacker.start_date, time.min),
                                         end_datetime=date2datetime(stacker.end_date, time.max),
                                         satellite=stacker.satellite,
                                         sensor=stacker.sensor,
                                         path=stacker.path,
                                         row=stacker.row,
                                         tile_type_id=None,
                                         create_band_stacks=True,
                                         disregard_incomplete_data=True)

    log_multiline(logger.debug, stack_info_dict, 'stack_info_dict', '\t')
    logger.info('Finished creating %d temporal stack files in %s.', len(stack_info_dict), stacker.output_dir)

    file_paths = stack_info_dict.keys()
    for pth in file_paths:
        m = re.match(".*PQA.vrt", pth)
        if m:
            break

    # Get info from the first band
    b1 = stack_info_dict[pth][0]
    x_idx = str(b1['x_index'])
    y_idx = str(b1['y_index'])

    cell = x_idx + '_' + y_idx

    #sat1, sat2, sat3, sat4, sat5, satTherm, sat7, prj, geoT = pqSaturation(pth)
    cloud, prj, geoT = pqCloud(pth)

    #summaries = [sat1, sat2, sat3, sat4, sat5, satTherm, sat7]
    summaries = [cloud]

    # Out filenames
    #out_fnames = ['Band_1_Saturation_Summary',
    #              'Band_2_Saturation_Summary',
    #              'Band_3_Saturation_Summary',
    #              'Band_4_Saturation_Summary',
    #              'Band_5_Saturation_Summary',
    #              'Therm_Saturation_Summary',
    #              'Band_7_Saturation_Summary']
    out_fnames = ['Cloud_Summary']

    out_fnames = [''.join([fname,'_', cell]) for fname in out_fnames]

    out_fnames = [os.path.join(stacker.output_dir, fname) for fname in out_fnames]

    # Write each summary to disk
    for i in range(len(summaries)):
        write_img(summaries[i], out_fnames[i], projection=prj, geotransform=geoT)

    # Cleanup the intermediate files
    print 'Removing files from disk:\n'
    print file_paths
    cleanup(file_paths)

    #pdb.set_trace()

