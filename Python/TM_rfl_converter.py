#! /usr/bin/env python

import os
import sys
import argparse
import fnmatch
import numpy
import numexpr
from osgeo import gdal
import osr
import pdb
import datetime

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

# Returns the required line from a list of strings
def linefinder(array, string = ""):
    """Searches a list for the specified string.

       Args:
           array: A list containing searchable strings.
           string: User input containing the string to search.

       Returns:
           The line containing the found sting.
    """

    for line in array:
        if string in str(line):
            return line

# Reads the metadata file in order to extract the needed parameters
def read_metafile(metafile):
    """Opens the metadata file and extracs relevant parameters.

       Args:
           metafile: A full string path name to the metadata file.

       Returns:
           Dictionary containing the parameters.
    """

    f         = open(metafile, 'r')
    met_array = f.readlines()
    f.close()

    files = []

    sfind  = linefinder(met_array,'SPACECRAFT_ID')
    s_craft = sfind.split()[2].replace('"', '')

    if s_craft == "Landsat7":
        sfind = linefinder(met_array, 'LMIN_BAND1')
        LminB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND2')
        LminB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND3')
        LminB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND4')
        LminB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND5')
        LminB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND61')
        LminB61  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND62')
        LminB62  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND7')
        LminB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND1')
        LmaxB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND2')
        LmaxB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND3')
        LmaxB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND4')
        LmaxB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND5')
        LmaxB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND61')
        LmaxB61  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND62')
        LmaxB62  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND7')
        LmaxB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND1')
        QminB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND1')
        QmaxB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND2')
        QminB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND2')
        QmaxB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND3')
        QminB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND3')
        QmaxB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND4')
        QminB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND4')
        QmaxB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND5')
        QminB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND5')
        QmaxB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND61')
        QminB61  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND61')
        QmaxB61  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND62')
        QminB62  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND62')
        QmaxB62  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND7')
        QminB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND7')
        QmaxB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'BAND1_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND2_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND3_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND4_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND5_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        #sfind = linefinder(met_array, 'BAND61_FILE_NAME')
        #files.append(sfind.split()[2].replace('"', ''))
        #sfind = linefinder(met_array, 'BAND62_FILE_NAME')
        #files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND7_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))


    else:
        sfind = linefinder(met_array, 'LMIN_BAND1')
        LminB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND2')
        LminB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND3')
        LminB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND4')
        LminB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND5')
        LminB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND6')
        LminB6  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMIN_BAND7')
        LminB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND1')
        LmaxB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND2')
        LmaxB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND3')
        LmaxB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND4')
        LmaxB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND5')
        LmaxB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND6')
        LmaxB6  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'LMAX_BAND7')
        LmaxB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND1')
        QminB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND1')
        QmaxB1  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND2')
        QminB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND2')
        QmaxB2  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND3')
        QminB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND3')
        QmaxB3  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND4')
        QminB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND4')
        QmaxB4  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND5')
        QminB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND5')
        QmaxB5  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND6')
        QminB6  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND6')
        QmaxB6  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMIN_BAND7')
        QminB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'QCALMAX_BAND7')
        QmaxB7  = float(sfind.split()[2])
        sfind = linefinder(met_array, 'BAND1_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND2_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND3_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND4_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND5_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))
        #sfind = linefinder(met_array, 'BAND6_FILE_NAME')
        #files.append(sfind.split()[2].replace('"', ''))
        sfind = linefinder(met_array, 'BAND7_FILE_NAME')
        files.append(sfind.split()[2].replace('"', ''))


    sfind   = linefinder(met_array, 'PRODUCT_TYPE')
    ptype   = sfind.split()[2].replace('"', '')
    sfind   = linefinder(met_array, 'PRODUCT_SAMPLES_REF')
    samples = int(sfind.split()[2])
    sfind   = linefinder(met_array, 'PRODUCT_LINES_REF')
    lines   = int(sfind.split()[2])
    sfind   = linefinder(met_array, 'SUN_AZIMUTH')
    s_azi   = float(sfind.split()[2])
    sfind   = linefinder(met_array, 'SUN_ELEVATION')
    s_elev  = float(sfind.split()[2])
    sfind   = linefinder(met_array, 'WRS_PATH')
    path    = int(sfind.split()[2])
    sfind   = linefinder(met_array, 'STARTING_ROW')
    row     = int(sfind.split()[2])
    sfind   = linefinder(met_array, 'ZONE_NUMBER')
    zone    = int(sfind.split()[2])
    sfind   = linefinder(met_array, 'ACQUISITION_DATE')
    aq_date = int(sfind.split()[2].replace('-', ''))
    sfind   = linefinder(met_array, 'DATEHOUR_CONTACT_PERIOD')
    doy     = int((sfind.split()[2].strip('"'))[2:5])


    if s_craft == "Landsat7":
        params  = {
                     'Satellite'        : s_craft,
                     'LMIN_B1'             : LminB1,
                     'LMAX_B1'             : LmaxB1,
                     'QCAL_MIN_B1'         : QminB1,
                     'QCAL_MAX_B1'         : QmaxB1,
                     'LMIN_B2'             : LminB2,
                     'LMAX_B2'             : LmaxB2,
                     'QCAL_MIN_B2'         : QminB2,
                     'QCAL_MAX_B2'         : QmaxB2,
                     'LMIN_B3'             : LminB3,
                     'LMAX_B3'             : LmaxB3,
                     'QCAL_MIN_B3'         : QminB3,
                     'QCAL_MAX_B3'         : QmaxB3,
                     'LMIN_B4'             : LminB4,
                     'LMAX_B4'             : LmaxB4,
                     'QCAL_MIN_B4'         : QminB4,
                     'QCAL_MAX_B4'         : QmaxB4,
                     'LMIN_B5'             : LminB5,
                     'LMAX_B5'             : LmaxB5,
                     'QCAL_MIN_B5'         : QminB5,
                     'QCAL_MAX_B5'         : QmaxB5,
                     'LMIN_B61'             : LminB61,
                     'LMAX_B61'             : LmaxB61,
                     'QCAL_MIN_B61'         : QminB61,
                     'QCAL_MAX_B61'         : QmaxB61,
                     'LMIN_B62'             : LminB62,
                     'LMAX_B62'             : LmaxB62,
                     'QCAL_MIN_B62'         : QminB62,
                     'QCAL_MAX_B62'         : QmaxB62,
                     'LMIN_B7'             : LminB7,
                     'LMAX_B7'             : LmaxB7,
                     'QCAL_MIN_B7'         : QminB7,
                     'QCAL_MAX_B7'         : QmaxB7,
                     'Product_Type'     : ptype,
                     'Images'           : files,
                     'Columns'          : samples,
                     'Rows'             : lines,
                     'Sun_Azimuth'      : s_azi,
                     'Sun_Elevation'    : s_elev,
                     'Path'             : path,
                     'Row'              : row,
                     'Zone'             : zone,
                     'Acquisition_Date' : aq_date,
                     'DOY'              : doy,
                  }

    else:
        params  = {
                     'Satellite'        : s_craft,
                     'LMIN_B1'             : LminB1,
                     'LMAX_B1'             : LmaxB1,
                     'QCAL_MIN_B1'         : QminB1,
                     'QCAL_MAX_B1'         : QmaxB1,
                     'LMIN_B2'             : LminB2,
                     'LMAX_B2'             : LmaxB2,
                     'QCAL_MIN_B2'         : QminB2,
                     'QCAL_MAX_B2'         : QmaxB2,
                     'LMIN_B3'             : LminB3,
                     'LMAX_B3'             : LmaxB3,
                     'QCAL_MIN_B3'         : QminB3,
                     'QCAL_MAX_B3'         : QmaxB3,
                     'LMIN_B4'             : LminB4,
                     'LMAX_B4'             : LmaxB4,
                     'QCAL_MIN_B4'         : QminB4,
                     'QCAL_MAX_B4'         : QmaxB4,
                     'LMIN_B5'             : LminB5,
                     'LMAX_B5'             : LmaxB5,
                     'QCAL_MIN_B5'         : QminB5,
                     'QCAL_MAX_B5'         : QmaxB5,
                     'LMIN_B6'             : LminB6,
                     'LMAX_B6'             : LmaxB6,
                     'QCAL_MIN_B6'         : QminB6,
                     'QCAL_MAX_B6'         : QmaxB6,
                     'LMIN_B7'             : LminB7,
                     'LMAX_B7'             : LmaxB7,
                     'QCAL_MIN_B7'         : QminB7,
                     'QCAL_MAX_B7'         : QmaxB7,
                     'Product_Type'     : ptype,
                     'Images'           : files,
                     'Columns'          : samples,
                     'Rows'             : lines,
                     'Sun_Azimuth'      : s_azi,
                     'Sun_Elevation'    : s_elev,
                     'Path'             : path,
                     'Row'              : row,
                     'Zone'             : zone,
                     'Acquisition_Date' : aq_date,
                     'DOY'              : doy,
                  }

    return params

def radiance_conversion(image, gain, bias):

    """Converts the input image into radiance.

       Two methods could be used; the Gain and bias or the spectral radiance
       scaling. Defined to use the spectral radiance scaling method

       Gain and bias method:
       B6_gain = (LMAX_BAND6 - LMIN_BAND6) / (QCALMAX_Band6 - QCALMIN_Band6)
       B6_bias = LMIN_BAND6 - (B6_gain * QCALMIN_Band6)
       rad = gain * image + bias

       Spectral Radiance Scaling method
       rad = ((LMAX - LMIN)/(QCALMAX - QCALMIN)) * (image - QCALMIN) + LMIN

       Args:
           image: The Thermal band to be converted to radiance, requires DN.
           gain: Rescaled gain in watts/(meter squared * ster * um)
           bias: Rescaled bias (offset) in watts/(meter squared * ster * um)

       Returns:
           The thermal band converted to at-sensor radiance in
           watts/(meter squared * ster * um) as an ndaray.
    """

    rad = numexpr.evaluate("gain * image + bias").astype("float32")

    #rad = (
    #        ((met_data['LMAX'] - met_data['LMIN'])/(met_data['QCAL_MAX'] -
    #         met_data['QCAL_MIN'])) * (image - met_data['QCAL_MIN']) +
    #         met_data['LMIN']
    #      )

    return rad

def reflectance_conversion(image, sol_zenith, esun_dist, sol_irrad):
    """Converts the input image into Top Of Atmosphere Reflectance (TOAR).

       Args:
           image: An nd-array containing top of atmosphere calibrated 
                  radiance.
           sol_zenith: The solar zenith angle in radians.
           esun_dist: The earth to sun distance in astro units.
           sol_irrad: The solar spectral irradiance in
                      watts/(meter squared * ster * um)

       Returns:
           A float32 nd-array containing TOAR.
       
    """

    pi = numpy.float32(numpy.pi)
    sol_zenith = numpy.float32(sol_zenith)
    esun_dist  = numpy.float32(esun_dist)
    sol_irrad  = numpy.float32(sol_irrad)
    ref = numexpr.evaluate("(pi * image * esun_dist**2) / (sol_irrad * cos(sol_zenith))").astype('float32')

    return ref

def earth_sun_dist(DOY):
    """A look up table for earth-sun distance in astronmical units.
      
       Args:
           DOY: An integer value between 1 and 366 (Day Of Year)

       Rerturns:
           The earth-sun distance in astronomical units.

    """

    assert (DOY >= 1 and DOY <= 366), 'Invalid Day of Year %i' % DOY

    sed = {
             1: 0.98331, 2: 0.98330, 3: 0.98330, 4: 0.98330,
             5: 0.98330, 6: 0.98332, 7: 0.98333, 8: 0.98335,
             9: 0.98338, 10: 0.98341, 11: 0.98345, 12: 0.98349,
             13: 0.98354, 14: 0.98359, 15: 0.98365, 16: 0.98371,
             17: 0.98378, 18: 0.98385, 19: 0.98393, 20: 0.98401,
             21: 0.98410, 22: 0.98419, 23: 0.98428, 24: 0.98439,
             25: 0.98449, 26: 0.98460, 27: 0.98472, 28: 0.98484,
             29: 0.98496, 30: 0.98509, 31: 0.98523, 32: 0.98536,
             33: 0.98551, 34: 0.98565, 35: 0.98580, 36: 0.98596,
             37: 0.98612, 38: 0.98628, 39: 0.98645, 40: 0.98662,
             41: 0.98680, 42: 0.98698, 43: 0.98717, 44: 0.98735,
             45: 0.98755, 46: 0.98774, 47: 0.98794, 48: 0.98814,
             49: 0.98835, 50: 0.98856, 51: 0.98877, 52: 0.98899,
             53: 0.98921, 54: 0.98944, 55: 0.98966, 56: 0.98989,
             57: 0.99012, 58: 0.99036, 59: 0.99060, 60: 0.99084,
             61: 0.99108, 62: 0.99133, 63: 0.99158, 64: 0.99183,
             65: 0.99208, 66: 0.99234, 67: 0.99260, 68: 0.99286,
             69: 0.99312, 70: 0.99339, 71: 0.99365, 72: 0.99392,
             73: 0.99419, 74: 0.99446, 75: 0.99474, 76: 0.99501,
             77: 0.99529, 78: 0.99556, 79: 0.99584, 80: 0.99612,
             81: 0.99640, 82: 0.99669, 83: 0.99697, 84: 0.99725,
             85: 0.99754, 86: 0.99782, 87: 0.99811, 88: 0.99840,
             89: 0.99868, 90: 0.99897, 91: 0.99926, 92: 0.99954,
             93: 0.99983, 94: 1.00012, 95: 1.00041, 96: 1.00069,
             97: 1.00098, 98: 1.00127, 99: 1.00155, 100: 1.00184,
             101: 1.00212, 102: 1.00240, 103: 1.00269, 104: 1.00297,
             105: 1.00325, 106: 1.00353, 107: 1.00381, 108: 1.00409,
             109: 1.00437, 110: 1.00464, 111: 1.00492, 112: 1.00519,
             113: 1.00546, 114: 1.00573, 115: 1.00600, 116: 1.00626,
             117: 1.00653, 118: 1.00679, 119: 1.00705, 120: 1.00731,
             121: 1.00756, 122: 1.00781, 123: 1.00806, 124: 1.00831,
             125: 1.00856, 126: 1.00880, 127: 1.00904, 128: 1.00928,
             129: 1.00952, 130: 1.00975, 131: 1.00998, 132: 1.01020,
             133: 1.01043, 134: 1.01065, 135: 1.01087, 136: 1.01108,
             137: 1.01129, 138: 1.01150, 139: 1.01170, 140: 1.01191,
             141: 1.01210, 142: 1.01230, 143: 1.01249, 144: 1.01267,
             145: 1.01286, 146: 1.01304, 147: 1.01321, 148: 1.01338,
             149: 1.01355, 150: 1.01371, 151: 1.01387, 152: 1.01403,
             153: 1.01418, 154: 1.01433, 155: 1.01447, 156: 1.01461,
             157: 1.01475, 158: 1.01488, 159: 1.01500, 160: 1.01513,
             161: 1.01524, 162: 1.01536, 163: 1.01547, 164: 1.01557,
             165: 1.01567, 166: 1.01577, 167: 1.01586, 168: 1.01595,
             169: 1.01603, 170: 1.01610, 171: 1.01618, 172: 1.01625,
             173: 1.01631, 174: 1.01637, 175: 1.01642, 176: 1.01647,
             177: 1.01652, 178: 1.01656, 179: 1.01659, 180: 1.01662,
             181: 1.01665, 182: 1.01667, 183: 1.01668, 184: 1.01670,
             185: 1.01670, 186: 1.01670, 187: 1.01670, 188: 1.01669,
             189: 1.01668, 190: 1.01666, 191: 1.01664, 192: 1.01661,
             193: 1.01658, 194: 1.01655, 195: 1.01650, 196: 1.01646,
             197: 1.01641, 198: 1.01635, 199: 1.01629, 200: 1.01623,
             201: 1.01616, 202: 1.01609, 203: 1.01601, 204: 1.01592,
             205: 1.01584, 206: 1.01575, 207: 1.01565, 208: 1.01555,
             209: 1.01544, 210: 1.01533, 211: 1.01522, 212: 1.01510,
             213: 1.01497, 214: 1.01485, 215: 1.01471, 216: 1.01458,
             217: 1.01444, 218: 1.01429, 219: 1.01414, 220: 1.01399,
             221: 1.01383, 222: 1.01367, 223: 1.01351, 224: 1.01334,
             225: 1.01317, 226: 1.01299, 227: 1.01281, 228: 1.01263,
             229: 1.01244, 230: 1.01225, 231: 1.01205, 232: 1.01186,
             233: 1.01165, 234: 1.01145, 235: 1.01124, 236: 1.01103,
             237: 1.01081, 238: 1.01060, 239: 1.01037, 240: 1.01015,
             241: 1.00992, 242: 1.00969, 243: 1.00946, 244: 1.00922,
             245: 1.00898, 246: 1.00874, 247: 1.00850, 248: 1.00825,
             249: 1.00800, 250: 1.00775, 251: 1.00750, 252: 1.00724,
             253: 1.00698, 254: 1.00672, 255: 1.00646, 256: 1.00620,
             257: 1.00593, 258: 1.00566, 259: 1.00539, 260: 1.00512,
             261: 1.00485, 262: 1.00457, 263: 1.00430, 264: 1.00402,
             265: 1.00374, 266: 1.00346, 267: 1.00318, 268: 1.00290,
             269: 1.00262, 270: 1.00234, 271: 1.00205, 272: 1.00177,
             273: 1.00148, 274: 1.00119, 275: 1.00091, 276: 1.00062,
             277: 1.00033, 278: 1.00005, 279: 0.99976, 280: 0.99947,
             281: 0.99918, 282: 0.99890, 283: 0.99861, 284: 0.99832,
             285: 0.99804, 286: 0.99775, 287: 0.99747, 288: 0.99718,
             289: 0.99690, 290: 0.99662, 291: 0.99634, 292: 0.99605,
             293: 0.99577, 294: 0.99550, 295: 0.99522, 296: 0.99494,
             297: 0.99467, 298: 0.99440, 299: 0.99412, 300: 0.99385,
             301: 0.99359, 302: 0.99332, 303: 0.99306, 304: 0.99279,
             305: 0.99253, 306: 0.99228, 307: 0.99202, 308: 0.99177,
             309: 0.99152, 310: 0.99127, 311: 0.99102, 312: 0.99078,
             313: 0.99054, 314: 0.99030, 315: 0.99007, 316: 0.98983,
             317: 0.98961, 318: 0.98938, 319: 0.98916, 320: 0.98894,
             321: 0.98872, 322: 0.98851, 323: 0.98830, 324: 0.98809,
             325: 0.98789, 326: 0.98769, 327: 0.98750, 328: 0.98731,
             329: 0.98712, 330: 0.98694, 331: 0.98676, 332: 0.98658,
             333: 0.98641, 334: 0.98624, 335: 0.98608, 336: 0.98592,
             337: 0.98577, 338: 0.98562, 339: 0.98547, 340: 0.98533,
             341: 0.98519, 342: 0.98506, 343: 0.98493, 344: 0.98481,
             345: 0.98469, 346: 0.98457, 347: 0.98446, 348: 0.98436,
             349: 0.98426, 350: 0.98416, 351: 0.98407, 352: 0.98399,
             353: 0.98391, 354: 0.98383, 355: 0.98376, 356: 0.98370,
             357: 0.98363, 358: 0.98358, 359: 0.98353, 360: 0.98348,
             361: 0.98344, 362: 0.98340, 363: 0.98337, 364: 0.98335,
             365: 0.98333, 366: 0.98331
          }
    return sed[DOY]

def datatype(val):
    instr = str(val)
    return {
        '1' : 'uint8',
        '2' : 'uint16',
        '3' : 'int16',
        '4' : 'uint32',
        '5' : 'int32',
        '6' : 'float32',
        '7' : 'float64',
        '8' : 'complex64',
        '9' : 'complex64',
        '10': 'complex64',
        '11': 'complex128',
        }.get(instr, 'float64')

def locate(pattern, root):
    """Searches for filenames specified by the pattern.

       Args:
           pattern: A string containing the relevant file pattern. The
              string can be a single string or a list of strings.
           root: A string containing the relevant folder to search.

       Returns:
           A list containing the files found.
    """

    matches = []

    # If the pattern to search is a list do:
    if type(pattern) is list:
        for path, dirs, files in os.walk(os.path.abspath(root)):
            for ext in pattern:
                for filename in fnmatch.filter(files, ext):
                    matches.append(os.path.join(path, filename))
        return matches


    # If the pattern is a single string do:
    else:
        for path, dirs, files in os.walk(os.path.abspath(root)):
            for filename in fnmatch.filter(files, pattern):
                matches.append(os.path.join(path, filename))
        return matches


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Calculates Top of Atmosphere Reflectance for Landsat 5 & 7.')

    parser.add_argument('-MTL', help='The landsat MTL text file. Or the directory to where the MTL file is located.')
    parser.add_argument('-outfile', default='TOAR.tif', help='The output filename.  At this stage only tif files are created. Defaults to TOAR.tif.')

    parsed_args = parser.parse_args()

    folder_path = parsed_args.MTL
    outname = parsed_args.outfile

    if os.path.isdir(folder_path):
        mfile  = locate('*MTL*', folder_path)
        m_info = read_metafile(mfile[0])
        os.chdir(os.path.dirname(mfile[0]))
    else:
        m_info = read_metafile(folder_path)
        # change to the directory in order to open the images.
        fdir = os.path.dirname(folder_path)
        os.chdir(fdir) # Change to the directory containing the 'MTL' file.

    #pdb.set_trace()

    nbands  = len(m_info['Images'])
    obj      = gdal.Open(m_info['Images'][0], gdal.gdalconst.GA_ReadOnly)
    prj      = obj.GetProjection()
    geotrans = obj.GetGeoTransform()
    band     = obj.GetRasterBand(1)
    datype   = datatype(band.DataType)

    driver = gdal.GetDriverByName('GTiff')
    #outds  = driver.Create(outname, m_info['Columns'], m_info['Rows'], nbands, 6)
    outds  = driver.Create(outname, m_info['Columns'], m_info['Rows'], nbands, 3)
    
    # see G. Chander et al. RSE 113 (2009) 893-903
    esun_L7=[1997.000, 1812.000, 1533.000, 1039.000, 230.800, 84.90]
    esun_L5=[1983.0, 1796.0, 1536.0, 1031.0, 220.0, 83.44]
    esun_L4=[1983.0, 1795.0, 1539.0, 1028.0, 219.8, 83.49]

    sol_zen = numpy.radians(90 - numpy.float32(m_info['Sun_Elevation']))

    if (m_info['Satellite'] == 'Landsat7'):
        ESUN = esun_L7
    else:
        ESUN = esun_L5

    gain_arr = []
    bias_arr = []

    gain_arr.append((m_info['LMAX_B1'] - m_info['LMIN_B1']) / (m_info['QCAL_MAX_B1'] - m_info['QCAL_MIN_B1']))
    gain_arr.append((m_info['LMAX_B2'] - m_info['LMIN_B2']) / (m_info['QCAL_MAX_B2'] - m_info['QCAL_MIN_B2']))
    gain_arr.append((m_info['LMAX_B3'] - m_info['LMIN_B3']) / (m_info['QCAL_MAX_B3'] - m_info['QCAL_MIN_B3']))
    gain_arr.append((m_info['LMAX_B4'] - m_info['LMIN_B4']) / (m_info['QCAL_MAX_B4'] - m_info['QCAL_MIN_B4']))
    gain_arr.append((m_info['LMAX_B5'] - m_info['LMIN_B5']) / (m_info['QCAL_MAX_B5'] - m_info['QCAL_MIN_B5']))
    gain_arr.append((m_info['LMAX_B7'] - m_info['LMIN_B7']) / (m_info['QCAL_MAX_B7'] - m_info['QCAL_MIN_B7']))

    bias_arr.append(m_info['LMIN_B1'] - (gain_arr[0] * m_info['QCAL_MIN_B1']))
    bias_arr.append(m_info['LMIN_B2'] - (gain_arr[1] * m_info['QCAL_MIN_B2']))
    bias_arr.append(m_info['LMIN_B3'] - (gain_arr[2] * m_info['QCAL_MIN_B3']))
    bias_arr.append(m_info['LMIN_B4'] - (gain_arr[3] * m_info['QCAL_MIN_B4']))
    bias_arr.append(m_info['LMIN_B5'] - (gain_arr[4] * m_info['QCAL_MIN_B5']))
    bias_arr.append(m_info['LMIN_B7'] - (gain_arr[5] * m_info['QCAL_MIN_B7']))

    esun_dist = earth_sun_dist(DOY=m_info['DOY'])

    print 'gain_arr: ', gain_arr
    print 'bias_arr: ', bias_arr
    print 'esun_dist: ', esun_dist
    print 'DOY: ', m_info['DOY']
    print 'ESUN: ', ESUN

    for i in range(nbands):
        st = datetime.datetime.now()
        iobj = gdal.Open(m_info['Images'][i], gdal.gdalconst.GA_ReadOnly)
        img = iobj.ReadAsArray()
        et = datetime.datetime.now()
        print 'Read band: ', et - st

        st = datetime.datetime.now()
        img = radiance_conversion(image=img, gain=gain_arr[i], bias=bias_arr[i])
        et = datetime.datetime.now()
        print 'Radiance Conversion: ', et - st
        st = datetime.datetime.now()
        img = reflectance_conversion(image=img, sol_zenith=sol_zen, esun_dist=esun_dist, sol_irrad=ESUN[i])
        et = datetime.datetime.now()
        print 'Reflectance Conversion: ', et - st

        st = datetime.datetime.now()
        img = numexpr.evaluate("img * 10000")
        et = datetime.datetime.now()
        print 'Apply Scale Factor: ', et - st

        st = datetime.datetime.now()
        outband = outds.GetRasterBand(i+1)
        outband.WriteArray(img)
        et = datetime.datetime.now()
        print 'Writing Array: ', et - st


    outds.SetGeoTransform(geotrans)
    outds.SetProjection(prj)
    outds = None
