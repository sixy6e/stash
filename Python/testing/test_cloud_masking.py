'''
Created on 14/11/2011

@author: u08087
'''
import os
import numpy
from osgeo import gdal

#-------------------------Functions/Filters-----------------------------------

# Function is only applied to masked data
def water_test(ndvi, array):
    #input
    # water = (ndvi < 0.1) or ((nir < 0.04) and (swir1 < 0.05))
    # swir1 = band 5; array pos = 4
    # nir   = band 4; array pos = 3
    water = numpy.logical_or(ndvi < -01, numpy.logical_or(array[3,:,:]
                                 < 0.04, array[4,:,:] < 0.05))
    return water

# Function is only applied to masked data
# Calculate NDVI
def ndvi(array):
    # ndvi = (nir -red)/(nir + red)
    # nir  = band 4; array pos = 3
    # red  = band 3; array pos = 2
    ndvi = (array[3,:,:] - array[2,:,:])/(array[3,:,:] + array[2,:,:])
    return ndvi

# Function is only applied to masked data
# Calculate NSDI; FILTER 2
def ndsi(array):
    # ndsi = (green - swir1)/(green + swir1)
    ndsi = (array[1,:,:] - array[4,:,:])/(array[1,:,:] + array[4,:,:])
    return ndsi

# Function is only applied to masked data
# Calculate band 5/6 composite; FILTER 4
def comp56(array):
    # c56 = (1 - swir1) * TM6
    c56 = (1 - array[4,:,:])*array[5,:,:]
    return c56

# Function is only applied to masked data
# Calculate band 4/3 ratio; FILTER 5/Simple Ratio
def sr(array):
    # sr = nir/red
    sr = array[3,:,:]/array[2,:,:]
    return sr

# Function is only applied to masked data
# Calculate band 4/2 ratio; FILTER 6
def filt6(array):
    # f6 = nir/green
    f6 = array[3,:,:]/array[1,:,:]
    return f6

# Function is only applied to masked data
# Calculate band 4/5 ratio; FILTER 7
def filt7(array):
    # f6 = nir/swir1
    f7 = array[3,:,:]/array[4,:,:]
    return f7

#-------------------------Apply Quality Flags---------------------------------

# Need to incorporate the use of the null and sat masks
# In order to use the 'masked feature', the 0's and 1's have to be reversed
# Otherwise the good data is removed
def reverse_qual(qflag):
    rqflag = numpy.ma.masked_greater(qflag, 0)
    return ~rqflag.mask

# Once the true/false has been inverted apply the null mask
# rqflag is the reversed quality flag
def apply_null_mask(array, rqflag):
    array = numpy.ma.array(array, mask = rqflag[8])
    return array

#-------------------------LEDAPS Processing-----------------------------------
    
# Function is only applied to masked data
#def ledaps_1st_pass(array):
    # blue = band 1; array pos = 0
    # red  = band 3; array pos = 2
    # vrat = ((blue) -0.5*(red)) > 0.08
    # vrat = visible reflectance threshold
 #   vrat = (array[0] - (0.5*array[2])) > 0.08
    
    # btt = brightness temperature threshold
    # btt = TM6 (ETM61) < airtemp(NCEP) - 20
    # TM6/ETM61; array pos = 5
    
    # NCEP is an external dataset created by NOAA
    # Instead incorporate a threshold similar to ACCA: < 300 K
  #  btt = array[5] < 300
    
    
    # rt = (red > 0.4) or (nir > 0.6)
   # rt = numpy.logical_and(array[2,:,:] > 0.4, array[3,:,:] > 0.6)
    
    # srt = 0.9 < nir/red < 1.3
    #vi = array[3,:,:]/array[2,:,:]
    #srt = numpy.logical_and(sr(array) > 0.9, sr(array) < 1.3)
    
    #return 

#-------------------------ACCA Processing-------------------------------------

# Get the image array and quality flag array and apply masking
#rqflag = reverse_qual(qflag)
#m_array = apply_null_mask(array, rqflag)

imgfile = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\L5_2009_12_04_subs'
iobj = gdal.Open(imgfile, gdal.gdalconst.GA_ReadOnly)

'''
   The python masking procedure works in reverse.
   Those pixels that satisfy the condition are considered masked (invalid).
   As such the queries need to be reversed.  i.e. Find (in other words keep)
   the pixels that have a temperature "less than" 300K: query = pixels > 300K.
   Pixels that are less than 300K are false (zero) and kept, whilst those that
   are true (one) are ignored when doing further analysis.
'''  

# Filter 1; brightness threshold
query    = m_array[2,:,:] < 0.08
cm_array = rqflag[8,:,:] + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)


# Filter 2: NDSI
query    = ndsi(m_array) < 0.7
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)

# TODO Create a tally of snow pixels


# Filter 3; Temp. threshold
query    = m_array[5,:,:] > 300
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)


# Filter 4; Band 5/6 composite
query    = comp56(m_array) < 225
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)

# TODO save pixels that fail this test for ambiguity testing


# Filter 5; Band 4/3 ratio (Simple veg ratio)
query    = sr(m_array) > 2
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)

# TODO save pixels that fail this test for ambiguity testing


# Filter 6; Band 4/2 ratio (Dying/senescing veg)
query    = filt6(m_array) > 2
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)

# TODO save pixels that fail this test for ambiguity testing


# Filter 7; Band 4/5 ratio (Identify highly reflective soils/rocks)
query    = filt7(m_array) > 1
cm_array = cm_array + query.data

m_array  = numpy.ma.array(m_array, mask = cm_array)

# TODO save pixels that fail this test for ambiguity testing
# TODO Create a tally of desert pixels


# Filter 8; Band 5/6 composite (Separate warm/cold clouds)
cold_cloud    = comp56(m_array) > 210
warm_cloud    = comp56(m_array) < 210

#cm_array = cm_array + query.data

#m_array  = numpy.ma.array(m_array, mask = cm_array)
    
