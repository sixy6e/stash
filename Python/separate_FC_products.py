#! /usr/bin/env python

import os
import sys
import numpy
import fnmatch
import argparse
import gc

from osgeo import gdal

def locate(pattern, root):
    ''' Finds files that match the given pattern.

        This will not search any sub-directories.

    Args:
        pattern: A string containing the pattern to search, eg '*.csv'
        root: The path directory to search

    Returns: A list of file-path name strings of files that match the given pattern.
    '''

    matches = []
    for file in os.listdir(root):
        if fnmatch.fnmatch(file, pattern):
            matches.append(os.path.join(root, file))

    return matches

def gdal_datatype(val):
    instring = str(val)
    return {
        'uint8' : gdal.gdalconst.GDT_Byte,
        'uint16' : gdal.gdalconst.GDT_UInt16,
        'int16' : gdal.gdalconst.GDT_Int16,
        'uint32' : gdal.gdalconst.GDT_UInt32,
        'int32' : gdal.gdalconst.GDT_Int32,
        'float32' : gdal.gdalconst.GDT_Float32,
        'float64' : gdal.gdalconst.GDT_Float64,
        'complex64' : gdal.gdalconst.GDT_CInt16,
        'complex64' : gdal.gdalconst.GDT_CInt32,
        'comlpex64' : gdal.gdalconst.GDT_CFloat32,
        'comlpex128' : gdal.gdalconst.GDT_CFloat64,
        }.get(instring, 'Error')

def main(dir_path, pattern, file_driver):

    os.chdir(dir_path)

    # Get a list of directories contained within input directory
    dir_list = [os.path.abspath(d) for d in os.listdir(dir_path) if os.path.isdir(d)]
    for i in dir_list:
        tif_file = locate(pattern, i)
        if (len(tif_file) == 0):
            print 'No %s file found in directory %s' %(pattern, i)
            continue
        elif (len(tif_file) > 1):
            print 'Multiple %s files found in directory %s ...ignoring' %(pattern, i)
            continue # presumably the bands have been extracted into files
        else:
            print '%s file found, processing file %s' %(pattern, tif_file[0])

            iobj = gdal.Open(tif_file[0], gdal.gdalconst.GA_ReadOnly)

            # Check that the file is valid
            if (iobj == None):
                print >> sys.stderr, 'Error, invalid file: %s' %tif_file[0]
                continue

            prj          = iobj.GetProjection()
            geotransform = iobj.GetGeoTransform()
            metadata     = iobj.GetMetadata()
            samples      = iobj.RasterXSize
            lines        = iobj.RasterYSize
            band         = iobj.GetRasterBand(1)
            noData       = band.GetNoDataValue()
            band         = None

            img = iobj.ReadAsArray()
            iobj.FlushCache()

            if (img.shape[0] != 4):
                print '%s file does not have 4 bands. Probably not a FC product' %tif_file[0]
                continue

            outnb      = 1
            out_fnames = []
            file_ext   = os.path.splitext(tif_file[0])[1]
            dir_name   = os.path.dirname(tif_file[0])
            base_name  = os.path.splitext(os.path.basename(tif_file[0]))[0]

            FC_components = ['_PV', '_NPV', '_BS', '_UE']

            dtype = gdal_datatype(img.dtype.name)
            if (dtype == 'Error'):
                raise Exception('Error. Incompatable Data Type. Compatable Data Types Include: int8, uint8, int16, uint16, int32, uint32, int64, uint64, float32, float64')

            # Need to add a scene01 directory to the path name
            dir_name = os.path.join(dir_name, 'scene01')
            if (not os.path.exists(dir_name)):
                os.makedirs(dir_name)

            for c in FC_components:
                out_fnames.append(os.path.join(dir_name, base_name + c + file_ext))

            # Now to write out the individual files
            driver = gdal.GetDriverByName(file_driver)
            for i in range(len(FC_components)):
                outds = driver.Create(out_fnames[i], samples, lines, outnb, dtype)
                assert outds
                outds.SetMetadata(metadata)
                outds.SetProjection(prj)
                outds.SetGeoTransform(geotransform)

                outband = outds.GetRasterBand(1)
                outband.SetNoDataValue(noData)
                outband.WriteArray(img[i])

                # Close the dataset
                outds.FlushCache()
                outband = None
                outds = None

            # Now to remove the original file. Remove any potential references
            # as well.
            iobj         = None
            iprj         = None    
            geotransform = None
            metadata     = None
            samples      = None
            lines        = None

            os.remove(tif_file[0])
            gc.collect()

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Converts a single multi-band Fractional Cover product and into single-band files.')
    parser.add_argument('--indir', required=True, help='The input directory that contains the Fractional Cover products for a specific year-month, eg 2008-11')
    parser.add_argument('--ext', default='*.tif', help='''The file extension to search for.  The default is '*.tif'.''')
    parser.add_argument('--driver', default='GTiff', help='The output file type. The default is GTiff.')

    parsed_args = parser.parse_args()

    indir = parsed_args.indir
    ext   = parsed_args.ext
    driver = parsed_args.driver

    print 'Input directory: ', indir
    print 'File extension: ', ext
    print 'Output file type: ', driver
    print 'Process stating....'
    main(indir, ext, driver)
