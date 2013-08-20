#! /usr/bin/env python


import numpy

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
    if len(image) == 0: return None
    if type(image[0]) != numpy.ndarray: raise Exception('Input is not valid')
    if mask == None:
        mask = numpy.zeros_like(image[0])
        pass
    bit = 0 # start bit for the Saturation Mask
    for band in image:
        thisband = numpy.where(band == 1, 1, 0)
        thisband |= numpy.where(band == 255, 1, 0)
        mask |= thisband << bit
        bit += 1
    return mask

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
    return mask
  

#========================================



def null(image):
    # The first statement works for multi-band images
    shape = image.shape
    if len(shape) == 3:
        mask = image != 0
        mask = mask.sum(axis = 0)
        # Return only those pixels that sum equal to the no. of bands
        mask = mask == shape[0]
        return mask.astype('int')
    else:
        # Single band images
        mask = image != 0
        return mask.astype('int')
    # mask = image != 0
    #return mask.astype('int')


def saturation(image):
    # A combined search will not work. Need to have two separate searches
    # mask = image == 1 or image == 255
    # USE: mask = numpy.logical_and(image != 1, image != 255)
    #mask = numpy.logical_and(image != 1, image != 255)
    mask = (image != 1) | (image != 255)
    # osat = image != 255
    # usat = image != 1
    # mask = osat * usat
    return mask.astype('int')


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
