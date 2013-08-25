#! /usr/bin/env python

"""
Created on 13/02/2013

@author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

Transcribed from IDL code provided by Landgate

Original IDL code only output the lat/lon co-ords to 3 decimal points, which
could differ from the original co-ordinate by a couple of dozen metres or more!.
The transcribed code outputs to the limit given by a float32 (about 6 decimal places).
Also, the original code had a bug in that outputs may not reflect actual hotspots.
The alg. search for values >= 10 (presumably these are hotspots) but it never used
those locations/indices to retrieve the lat/lon co-ordinates. As such there was
the potential for the code to be extracting incorrect lat/lon co-ordinates.
The following code has been modified so that it retrieves the correct 
lat/lon coordinates.

The h5py library can be obtained from 
http://code.google.com/p/h5py/

History:
2013/02/13: Initial transcription from IDL code
2013/05/17: Added a check to see whether or not the array is actually empty.
            Changed function name run_hotspost to run_hotspots
"""

import sys
import os
import numpy
import h5py
import fnmatch
import argparse

def locate(pattern, root):
    """ Finds files that match the given pattern.

        This will not search any sub-directories.

    Args:
        pattern: A string containing the pattern to search, eg '*.csv'
        root: The path directory to search

    Returns: A list of file-path name strings of files that match the given pattern.
    """

    matches = []
    for file in os.listdir(root):
        if fnmatch.fnmatch(file, pattern):
            matches.append(os.path.join(root, file))

    return matches

def run_hotspots(indir=None, outfile=None, ext=None):
    files = locate(ext, indir) # find the hdf5 files
    if (len(files) == 0):
        print 'No files found! Exiting.'
        return
    
    # only create a xml file if hdf5 files were found
    # change to the input directory, in case no output path was specified
    os.chdir(indir)
    outfile = os.path.abspath(outfile)
    outxml = open(outfile, 'w')
    outxml.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    outxml.write('<kml xmlns="http://earth.google.com/kml/2.0">\n')
    outxml.write('<Document>\n')

    for file in files:
        f = h5py.File(file,'r')
        block=f['All_Data']['VIIRS-AF-EDR_All']['QF4_VIIRSAFARP']['QF4_VIIRSAFARP_0']
        if (block.size == 0):
            print 'Empty array in %s' %os.path.basename(file)
            print 'Skipping dataset %s' %os.path.basename(file)
            continue
        data=block.value
        if (data.size == 0):
            continue
        lat = f['All_Data']['VIIRS-AF-EDR_All']['Latitude']['Latitude_0'].value
        lon = f['All_Data']['VIIRS-AF-EDR_All']['Longitude']['Longitude_0'].value
        loc = numpy.where(data >= 10) # presumably hotspots are values > 10
        lat_loc = lat[loc] # get the lattitude corresponding with a hotspot
        lon_loc = lon[loc] # get the longitude corresponding with a hotspot
        
        for i in numpy.arange(lat_loc.shape[0]):
            outxml.write(' <Placemark><Point>\n')
            outstring = '  <coordinates>  %f, %f, 0.0 </coordinates>\n' %(lon_loc[i], lat_loc[i])
            outxml.write(outstring)
            outxml.write(' </Point></Placemark>\n')
            
    outxml.write('</Document>\n')
    outxml.write('</kml>\n')
    outxml.close()
        
    return

def Main():
    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Finds Hotspots and outputs to a kml file.')
    parser.add_argument('--indir', required=True, help='The directory containing the hdf5 files.')
    parser.add_argument('--outfile', default='viirs_fire.kml', help='The output filename. Defaults to "viirs_fire.kml" and dumped into the input directory.')
    parser.add_argument('--ext', default='*.h5', help='The file extension to search for. eg --ext *.h5 (which is the default).')

    parsed_args = parser.parse_args()

    indir   = os.path.abspath(parsed_args.indir)
    outfile = parsed_args.outfile
    ext     = parsed_args.ext

    run_hotspots(indir, outfile, ext)

if __name__ == '__main__':
    Main()

