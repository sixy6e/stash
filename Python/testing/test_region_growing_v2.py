'''
Created on 20/12/2011

@author: u08087
'''


import numpy
from scipy import ndimage
from osgeo import gdal
import osr



'''
ci = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\full_scene\ACCA_Script_run_mask'
iobj  = gdal.Open(ci, gdal.gdalconst.GA_ReadOnly)
array = iobj.ReadAsArray()
metadata     = iobj.GetMetadata_Dict()
geoTransform = iobj.GetGeoTransform()
prj          = iobj.GetProjection()
spt_ref      = osr.SpatialReference()
columns      = iobj.RasterXSize
rows         = iobj.RasterYSize

dims = array.shape
'''


# Dummy seed location in Row/Column format
seed = [95,120]

'''
    Need to include some form of testing to see whether or not the seed
    points are located in the dimensions of the image or not.  Also test
    for NaN/Null values.
'''

# Create a 3x3 array with the seed as the centre cell
x = numpy.arange(9) % 3 + (seed[1] -1)
y = numpy.arange(9) / 3 + (seed[0] -1)

'''
    Need to include some form of testing to see whether or not the neighbour
    points are located in the dimensions of the image or not.  Also test for
    NaN/Null values.
'''


# ROI (Region of Interest)
roi = (y,x)

# Calculate the mean of the roi
mean = numpy.mean(array[roi])

# Calculate the standard deviation of the roi
stdv = numpy.std(array[roi], ddof=1)

# Standard deviation multiplier
limit = 2.5 * stdv

# Create the upper and lower thresholds
hi  = mean + limit
low = mean - limit

# Create the mask via the thresholds
mask = (array >= low) * (array <= hi) # '*' works in place of the logical 'and'

# Create the all neighbours binary structure for use with the labels function
s = [[1,1,1],[1,1,1],[1,1,1]]

# The label function segments the image into contiguous blobs
label_array, num_labels = ndimage.label(mask, structure=s)

# Calculate the histogram of the entire labelled array
hist_labels, bin_edges = numpy.histogram(label_array, bins=numpy.arange(num_labels+1))

# Calculate the histogram of the labelled array using the roi
hist_roi_labels, b_edge = numpy.histogram(label_array[roi], bins=numpy.arange(num_labels+1))

# Retrieve the labels that exist within the roi
roi_labels = numpy.where(hist_roi_labels != 0)

# Total number of pixels with the same label as those found within the roi
# This might have to be refined if more than one label exists within the roi
num_pixels = hist_labels[roi_labels][0]

'''
Maybe something like this?

num_pixels = (hist_labels[roi_labels]).sum() -(hist_labels[roi_labels[0]]*(roi_labels[0] ==0))
'''

# This might have to be refined if more than one label exists within the roi
grown_region = numpy.where(label_array == roi_labels)

cshadow = numpy.zeros(dims, dtype='byte')

cshadow[grown_region] = 1