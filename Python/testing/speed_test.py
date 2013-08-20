'''
Created on 15/11/2011

@author: u08087
'''
import os
import datetime
import numpy
from osgeo import gdal
import psutil

ifile = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\EODS_20111011_10_36_39\LS7_ETM_OTH_P51_GLS2000_092_084_19990824_1\scene01\LS7_ETM_OTH_P51_GLS2000_092_084_19990824_b7.tif'

iobj = gdal.Open(ifile, gdal.gdalconst.GA_ReadOnly)
band = iobj.GetRasterBand(1)
a = band.ReadAsArray()
print psutil.phymem_usage()
#a = numpy.random.rand(2,4600,4600)

# TEST 4
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
mask = (a < 50) | (a > 50) 

end_time   = datetime.datetime.now()

print 'Test 4: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask
print psutil.phymem_usage()


# TEST 1
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
b = a < 50
c = a > 50
mask = b + c

end_time   = datetime.datetime.now()

print 'Test 1: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask, b, c
print psutil.phymem_usage()


# TEST 2
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
mask = numpy.logical_or(a < 50, a > 50)

end_time   = datetime.datetime.now()

print 'Test 2: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask
print psutil.phymem_usage()


# TEST 3
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
b = numpy.where(a < 50, 1, 0)
c = numpy.where(a > 50, 1, 0)
mask = b + c

end_time   = datetime.datetime.now()

print 'Test 3: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask, b, c
print psutil.phymem_usage()


# TEST 4
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
mask = (a < 50) | (a > 50) 

end_time   = datetime.datetime.now()

print 'Test 4: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask
print psutil.phymem_usage()

# TEST 5
start_time = datetime.datetime.now()

#a = numpy.random.rand(2,4600,4600)
mask = numpy.where(((a < 50) | (a > 50)), 1, 0)

end_time   = datetime.datetime.now()

print 'Test 3: ', 'Time = ', end_time - start_time, 'Sum = ', mask.sum()
print psutil.phymem_usage()
del mask
print psutil.phymem_usage()


