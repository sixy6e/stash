#! /usr/bin/env python


import numpy
import datetime
from osgeo import gdal

#-------------------------------
# Function: SaturationMask(image)
# Description:
#   To set up Saturation Mask for each band
# Input: 
#   image: an array of all bands of an image, each band is an Numpy Array
# Return:
#   Saturation Mask for all bands: bit 0 for band1, bit 1 for band2, etc.
# History:
# Author:
#--------------------------------

def SaturationMask(image, mask = None):
    start_time = datetime.datetime.now()
    if len(image) == 0: return None
    if type(image[0]) != numpy.ndarray: raise Exception('Input is not valid')
    if mask == None:
        mask = numpy.zeros_like(image[0])
        pass
    bit = 0 # start bit for the Saturation Mask
    for band in image:
        #thisband = numpy.where(band == 1, 1, 0)
        thisband = band == 1
        #thisband |= numpy.where(band == 255, 1, 0)
        thisband |= band == 255
        mask |= thisband << bit
        bit += 1
    end_time   = datetime.datetime.now()
    f_time = end_time - start_time
    print end_time - start_time
    #return mask, f_time
    return f_time

#-------------------------------
# Function: SaturationMask(image)
# Description:
#   To set up Saturation Mask for each band
# Input: 
#   image: an array of all bands of an image, each band is an Numpy Array
# Return:
#   Saturation Mask for all bands: bit 0 for band1, bit 1 for band2, etc.
# History:
# Author:
#--------------------------------

def Contiguity(image, mask = None, bitpos = 8):
    start_time = datetime.datetime.now()
    MASK_CONTIGUITY = 1 << bitpos   # to be checked
    if len(image) == 0: 
        return None
    if type(image[0]) != numpy.ndarray: raise Exception('Input is not valid')
    if mask == None:
        mask = numpy.zeros_like(image[0])
        pass
    notNull = image[0] > 0
    i = 1
    while i < len(image):
        notNull &= image[i] > 0
        i += 1
    mask |= numpy.where(notNull, MASK_CONTIGUITY, 0)
    end_time   = datetime.datetime.now()
    f_time = end_time - start_time
    print end_time - start_time

    #return mask, f_time
    return f_time
  

#========================================



def null(image):
    # The first statement works for multi-band images
    start_time = datetime.datetime.now()
    shape = image.shape
    if len(shape) == 3:
        mask = image != 0
        mask = mask.sum(axis = 0)
        # Return only those pixels that sum equal to the no. of bands
        mask = mask == shape[0]
        fmask = mask << 8
        end_time   = datetime.datetime.now()
        f_time = end_time - start_time
        print end_time - start_time
        
        #return fmask, f_time
        return f_time
    else:
        # Single band images
        mask = image != 0
        end_time   = datetime.datetime.now()
        print end_time - start_time

        return mask.astype('int')
    
    # mask = image != 0
    #return mask.astype('int')


def saturation(image):
    start_time = datetime.datetime.now()
    # A combined search will not work. Need to have two separate searches
    # mask = image == 1 or image == 255
    # USE: mask = numpy.logical_and(image != 1, image != 255)
    #mask = numpy.logical_and(image != 1, image != 255)
    mask = (image != 1) | (image != 255)
    # osat = image != 255
    # usat = image != 1
    # mask = osat * usat
    bit = 0
    fmask = numpy.zeros((image.shape[0],image.shape[1]))
    for band in mask:
         fmask += (mask << bit)
         bit += 1
    end_time   = datetime.datetime.now()
    f_time = end_time - start_time
    print end_time - start_time

    #return fmask, f_time
    return f_time




file = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\stack'
iobj = gdal.Open(file, gdal.gdalconst.GA_ReadOnly)
image = iobj.ReadAsArray()

f1 = SaturationMask(image, mask = None)
f2 = Contiguity(image, mask = None, bitpos = 8)
f3 = null(image)
f4 = saturation(image)


'''
if __name__ == '__main__':

    import unittest

    class NSTester(unittest.TestCase):

        def setUp(self):
            self.array = numpy.arange(18).reshape(2,3,3)

        def test_sat(self):
            #ssum = numpy.sum(saturation(self.array))
            sat = saturation(self.array)
            ssum = numpy.sum(sat)
            self.assertEqual(ssum, 17)
            print ' sat array sum = ', ssum, '\n'
            print sat, '\n'

        def test_null(self):
            nul = null(self.array)
            #nsum = numpy.sum(null(self.array))
            nsum = numpy.sum(nul)
            #self.assertEqual(nsum.l, 8)
            print '\n input array \n'
            print self.array, '\n'
            print ' null array sum = ', nsum, '\n'
            print nul, '\n'


unittest.main()
'''