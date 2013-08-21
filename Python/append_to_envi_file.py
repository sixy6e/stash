#! /usr/bin/env python

import os
import subprocess
import struct
import shutil
import argparse
import re
import numpy
from osgeo import gdal

"""
This script is designed to take an ENVI file and append an extra band.
The data for the extra band is taken from the HDF file, also specified
upon input.
The script should be run from the command line eg:
python append_to_envi_file.py --ENVI_file --HDF_file --dir /path/to/work_directory

Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

History:
    2013/07/10: Created.
    2013/07/16: Added the functions modify_envi_dict(), create_envi_dict() and
                prep_envi_header().
                This provides a more elegant way of reading the ENVI header file,
                as well as prepping the header information for writing to disk.
"""

def line_num_finder(array, string = "", offset=0):
    """
    Used to find the line in the list containing the specific string.
    """
    for i in (numpy.arange(len(array))+offset):
        if string in str(array[i]):
            return i

def read_envi_hdr(hdr_name=''):
    """
    Read the ENVI hdr file into a List.
    """
    if os.path.exists(hdr_name):
        hdr_open = open(hdr_name)
        hdr = hdr_open.readlines()
        hdr_open.close()
        return hdr
    else:
        raise Exception('Error. No file with that name exists!')

def modify_envi_dict(dict):
    """
    Modifies the specific keys (if they're existant within the dictionary.
    This function is called internally and is  therefore not necessary to be 
    called independently.
    Band names will be converted to a List. The band names and the description
    will have the {} characters removed. Leading and trailing blank spaces will
    also be removed from both keys.
    Using regular expression might be overkill, as all {} characters will
    be removed from each string.
    Numeric values for keys such as samples, lines, bands will be converted to
    integerse.
    This function can be expanded to include other ENVI header items that
    need reformatting.
    Also provides some basic input checks in regards to existance of necessary
    values such as samples, lines, bands.
    """
    if ('band names' in dict.keys()):
        bn = dict['band names'].split(',')
        bn  = [(re.sub('[{}]', '', item)).strip() for item in bn]
        dict['band names'] = bn
    if ('description' in dict.keys()):
        desc = dict['description']
        desc = (re.sub('[{}]', '', desc)).strip()
        dict['description'] = desc
    if ('samples' in  dict.keys()):
        dict['samples'] = int(dict['samples'])
    else:
        raise Exception('Error. The number of samples could not be found!')
    if ('lines' in dict.keys()):
         dict['lines'] = int(dict['lines'])
    else:
        raise Exception('Error. The number of lines could not be found!')
    if ('bands' in dict.keys()):
        dict['bands'] = int(dict['bands'])
    else:
        raise Exception('Error. The number of bands could not be found!')
    if ('byte order' in dict.keys()):
        dict['byte order'] = int(dict['byte order'])
    else:
        raise Exception('Error. The byte order could not be found!')
    if ('data type' in dict.keys()):
        dict['data type'] = int(dict['data type'])
    else:
        raise Exception('Error. The data type could not be found!')
    if ('header offset' in dict.keys()):
        dict['header offset'] = int(dict['header offset'])
    if ('x start' in dict.keys()):
        dict['x start'] = int(dict['x start'])
    if ('y start' in dict.keys()):
        dict['y start'] = int(dict['y start'])
    return dict

def create_envi_dict(hdr):
    """
    Create a dictionary containing the ENVI header information.
    Value modifications, and checks for required keys are handled in
    the modify_envi_dict() function. The dictionary is first parsed to
    modify_envi_dict() before being returned. 
    """
    if hdr[0].split()[0] != 'ENVI':
        raise Exception('Error. This is not a standard ENVI header file!')
    d = {}
    for line in range(1,len(hdr)):
        sp = hdr[line].split()
        if '=' in sp:
            idx = sp.index('=')
            key = sp[0]
            for i in range(1,idx):
                key = key + ' ' + sp[i]
            val = sp[idx+1]
            offset = idx+2
            for v in range(offset,len(sp[idx+2:])+offset):
                val = val + ' ' + sp[v]
            d[key] = val
        else:
            for v in range(len(sp)):
                val = val + ' ' + sp[v]
            d[key] = val
    d = modify_envi_dict(dict=d)
    return d

def prep_envi_header(dict):
    """
    Takes a dictionary containing ENVI header information and converts to a List
    in preperation for writing to disk.
    The key components are listed first, eg ENVI, description, samples, lines, 
    bands, then everything else with the band names coming last.
    """
    dict_cp = dict.copy()
    hdr_list = []
    hdr_list.append('ENVI\n')
    if ('description' in dict_cp):
        hdr_list.append('description = {\n')
        hdr_list.append(dict_cp['description'] + '}\n')
        del dict_cp['description']
    hdr_list.append('samples = %i\n' %(dict_cp['samples']))
    hdr_list.append('lines   = %i\n' %(dict_cp['lines']))
    hdr_list.append('bands   = %i\n' %(dict_cp['bands']))
    del dict_cp['samples'], dict_cp['lines'], dict_cp['bands']
    bn = False
    if ('band names' in dict_cp.keys()):
        bn = True
        bn_list = list(dict_cp['band names'])
        del dict_cp['band names']
        bn_list = [bname + ',\n' for bname in bn_list]
        bn_list[-1] = bn_list[-1].replace(',','}')
        bn_list.insert(0, 'band names = {\n')
    for key in dict_cp.keys():
        hdr_list.append('%s = %s\n' %(key, str(dict_cp[key])))
    if bn:
        hdr_list.extend(bn_list)
    return hdr_list

def get_tile3(samples, lines, xtile=100,ytile=100):
    """
    A function that pre-calculates tile indices for a 2D array.
    """
    ncols = samples
    nrows = lines
    tiles = []
    xstart = numpy.arange(0,ncols,xtile)
    ystart = numpy.arange(0,nrows,ytile)
    for ystep in ystart:
        if ystep + ytile < nrows:
            yend = ystep + ytile
        else:
            yend = nrows
        for xstep in xstart:
            if xstep + xtile < ncols:
                xend = xstep + xtile
            else:
                xend = ncols
            tiles.append((ystep,yend,xstep, xend))
    return tiles

def struct_datatype(val):
    """
    Maps ENVI's datatypes to Python's struct datatypes.
    """
    instr = str(val)
    return {
        '1' : 'B',
        '2' : 'h',
        '3' : 'l',
        '4' : 'f',
        '5' : 'd',
        '12' : 'H',
        '13' : 'L',
        '14' : 'q',
        '15' : 'Q',
        }.get(instr, 'Error')

def struct_byte_order(val):
    """
    Maps ENVI's byte ordering key to Python's struct byte ordering key.
    """
    instr = str(val)
    return {
        '0' : '<',
        '1' : '>',
        }.get(instr, 'Error')

def main(envi_file, hdf_file, scratch_space, ytiles):
    """
    The main routine that appends new bands to an existing ENVI file.
    """

    if not (os.path.exists(envi_file)):
        raise Exception('Error. No file with that name exists!')

    if not (os.path.exists(hdf_file)):
        raise Exception('Error. No file with that name exists!')

    if not (os.path.exists(scratch_space)):
        raise Exception('Error. No directory with that name exists!')

    #hdr_fname = os.path.splitext(envi_file)[0] + '.hdr'
    hdr_fname = envi_file + '.hdr'
    hdr_data = read_envi_hdr(hdr_name=hdr_fname)
    hdr_dict = create_envi_dict(hdr_data)

    # Initialise the remove condition. We don't want to remove the source data!
    remove = False

    # The hdf files may be compressed i.e. MOD13Q1.2002.113.aust.005.b04.250m_0620_0670nm_refl.hdf.gz
    # So we may need to call a command line argument to fist uncompress the file
    if (os.path.splitext(hdf_file)[1] == '.gz'):

        print 'Copying %s to %s' %(hdf_file, scratch_space)
        # We should use a scratch space, incase the directory containing the original files
        # was supplied
        shutil.copy(hdf_file, scratch_space)
        scratch_hdf_file = os.path.join(scratch_space, os.path.basename(hdf_file))

        print 'Decompressing %s' %scratch_hdf_file
        # then need to uncompress/decompress the data
        command = ['gunzip', '-d', scratch_hdf_file]
        subprocess.call(command)

        # By default the '.gz' should be removed, leaving only the uncompressed file.
        gzip_file = scratch_hdf_file
        hdf_file  = os.path.splitext(scratch_hdf_file)[0]

        # Set to True so that file cleanup is performed.
        remove = True

    hdf_basename  = os.path.basename(hdf_file)
    envi_basename = os.path.basename(envi_file)

    # Find the machine byte ordering (little vs big endian)
    #find       = line_num_finder(hdr_data, 'byte order')
    #sfind      = hdr_data[find]
    #byte_order = int(sfind.split()[3])

    # Map the byte order to Python's struct module byte order characters
    #struct_byt_char = struct_byte_order(byte_order)
    struct_byt_char = struct_byte_order(hdr_dict['byte order'])
    if (struct_byt_char == 'Error'):
        raise Exception('Error. Incompatable Byte Order Value. Compatable ENVI Byte Order Values Are: 0, 1')

    # Find the number of bands
    #fnb   = line_num_finder(hdr_data, 'bands')
    #sfind = hdr_data[fnb]
    #nb    = int(sfind.split()[2])

    # Find the band names
    #fbn = line_num_finder(hdr_data, 'band names')
    #if (fbn != None):
    #    f_endbrace = line_num_finder(hdr_data, '}', offset=fbn)
    #    bn_stuff   = hdr_data[fbn:f_endbrace+1]

    # Find the interleave. If not BSQ then we can't append new bands.
    #find       = line_num_finder(hdr_data, 'interleave')
    #sfind      = hdr_data[find]
    #interleave = sfind.split()[2]
    #if (interleave != 'bsq'): # probably should use regex here
    if (hdr_dict['interleave'] != 'bsq'): # probably should use regex here, or something similar to match upper/lowercase.
        raise Exception('Error. File interleave must be BSQ in order for bands to be appended!')

    # Find the data type of the existing envi file.
    #fdt = line_num_finder(hdr_data, 'data type')
    #sfind      = hdr_data[fdt]
    #dtype = int(sfind.split()[3])

    # Map the datatype to Python's struct module datatype characters.
    #struct_dtype = struct_datatype(dtype)
    struct_dtype = struct_datatype(hdr_dict['data type'])
    if (struct_dtype == 'Error'):
       raise Exception('Error. Incompatable Data Type. Compatable ENVI Data Types Are: 1, 2, 3, 4, 5, 12, 13, 14, 15')

    struct_code_string = struct_byt_char + struct_dtype

    # Now open the hdf file and extract the image
    ds = gdal.Open(hdf_file)
    num_bands = ds.RasterCount
    samples = ds.RasterXSize
    lines = ds.RasterYSize

    if (num_bands != 1):
        raise Exception('Error. Was expecting an image with only one band!')

    #nb = nb + 1
    hdr_dict['bands'] += 1

    # Now to write out the file. This file should already be in existance.
    append = open(envi_file, 'ab')

    # Should we implement a tiling mechanism?
    # If so, then xsize is always all samples, and ysize can vary.
    tiles = get_tile3(samples, lines, xtile=samples,ytile=ytiles)

    print 'Appending data from %s to %s' %(hdf_basename, envi_basename)

    for tile in tiles:
        ystart = int(tile[0])
        yend   = int(tile[1])
        xstart = int(tile[2])
        xend   = int(tile[3])
        xsize  = int(xend - xstart)
        ysize  = int(yend - ystart)

        subset = (ds.ReadAsArray(xstart, ystart, xsize, ysize)).flatten().tolist()

        # Python has to have a better way than this. We should be able to write
        # the array directly to disk, rather than converting to a list and then a string.
        # Potential TODO Build gnudatalanguage as a Python module. This will provide access
        # to openr, openu, openw and the writeu commands. Escaping the need to convert to string.
        byte_string = ''
        byte_string = byte_string.join((struct.pack(struct_code_string, val) for val in subset))
        append.write(byte_string)

    append.close()
        
    # Now to re-create the ENVI header file, updating the necessary parameters.
    create_hdr = open(hdr_fname, 'r')

    #out_num_bands = 'bands   = %i\n'  %nb

    # Set up the new bands list
    #if (fbn != None):
    #    bn_stuff[-1] = bn_stuff[-1].replace('}',',')
    #    bn_stuff.append(os.path.basename(hdf_file) + '}\n')
    if ('band names' in hdr_dict.keys()):
        bname = 'Band ' + str(hdr_dict['bands']) + ' ' + os.path.basename(hdf_file)
        hdr_dict['band names'].append(bname)

    #hdr_len = len(hdr_data)

    new_hdr = prep_envi_header(hdr_dict)

    # We only need to change the number of bands and band names.
    # If 'bands' was written before 'band names', write data till the bands
    # line, then write modifed bands, then write data till bands names, write 
    # modified band names, then write the rest of the header. Else, reverse the logic.
    # TODO Write a better routine!!!
    #if (fbn != None): # Band name info exists
    #    if (fnb < fbn): # Number of bands is written before band names
    #        new_hdr = hdr_data[0:fnb]
    #        new_hdr.append(out_num_bands)
    #        for i in range(len(hdr_data[fnb+1:fbn])):
    #            new_hdr.append(hdr_data[i+fnb+1])
    #        for i in range(len(bn_stuff)):
    #            new_hdr.append(bn_stuff[i])
    #        # check that band name endbrace is the end of the file
    #        # if not, then get the extra stuff and append it
    #        if (hdr_len > (f_endbrace +1)):
    #            extra_hdr = hdr_data[f_endbrace+1]
    #            for i in range(len(extra_hdr)):
    #                new_hdr.append(extra_hdr[i])
    #    else: # band names is written before number of bands
    #        new_hdr = hdr_data[0:fbn]
    #        for i in range(len(bn_stuff)):
    #            new_hdr.append(bn_stuff)
    #        for i in range(len(hdr_data[fbn+1:fnb])):
    #            new_hdr.append(hdr_data[i+fnb+1])
    #        new_hdr.append(out_num_bands)
    #        if (hdr_len > (fnb +1)): # Check for end of hdr file
    #            extra_hdr = hdr_data[fnb+1]
    #            for i in range(len(extra_hdr)):
    #                new_hdr.append(extra_hdr[i])
    #else: # No band name info
    #    new_hdr = hdr_data[0:fnb]
    #    new_hdr.append(out_num_bands)
    #    if (hdr_len > (fnb +1)): # Check for end of hdr file
    #        extra_hdr = hdr_data[fnb+1:]
    #        for i in range(len(extra_hdr)):
    #            new_hdr.append(extra_hdr[i])
 
 

    # open the hdr file again for writing
    hdr_open = open(hdr_fname, 'w')

    for line in new_hdr:
        hdr_open.write(line)

    # close the hdr file
    hdr_open.close()

    # File cleanup
    if remove:
        print 'Removing intermediate files'
        os.remove(hdf_file)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Appends extra bands to an existing ENVI file.')
    parser.add_argument('--ENVI_file', required=True, help='The input ENVI file.')
    parser.add_argument('--HDF_file', required=True, help='The input HDF file.')
    parser.add_argument('--ysize', default=100, help='The tile size for dimension y. Default is 100 lines.', type=int)
    parser.add_argument('--dir', help='The working directory. Used for copying and decompressing the HDF file. If not supplied, the current working directory will be used for copying the data.')

    parsed_args = parser.parse_args()

    if parsed_args.dir != True:
        cwd = os.getcwd()
        wd  = os.path.join(cwd, 'working_directory')
        if not os.path.exists(wd):
            os.makedirs(wd)
    else:
        wd = parsed_args.dir
        if not os.path.exists(wd):
            os.makedirs(wd)

    ENVI_File = parsed_args.ENVI_file
    HDF_File  = parsed_args.HDF_file
    ytile     = parsed_args.ysize
        
    main(envi_file=ENVI_File, hdf_file=HDF_File, scratch_space=wd, ytiles=ytile)

