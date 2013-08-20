'''
Created on 16/12/2011

@author: u08087
'''

''' Stopped working on this version, it didn't seem like it would do the job.
    Going to try another method involving the labels function in scipy (ndimage).
'''

import numpy
from osgeo import gdal
import osr


# 4 neighbours (row,coloumn), top-centre, left, right, bottom-centre
nbhood = [(-1,0),(0,-1),(0,1),(1,0)]

# 8 neighbours (row,column), top-left, top-centre, top-right, left, right
# bottom-left, bottom-centre, bottom-right
nbhood_all = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]

'''
        8 cell
        (-1,-1)|(-1,0) |(-1,1)
        -------|-------|-------
        (0,-1) |   x   |(0,1) 
        -------|-------|-------
        (1,-1) | (1,0) |(1,1)
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


# Seed = (row,column) aka (line,sample)
seed = [mapy, mapx]

# Segmented area
seg = numpy.zeros((rows,columns), dtype='byte')

# Threshold list for neighbour co-ordinates
thresh_list = []

# Data values of neighbours
thresh_values = []

# Insert the initial seed point into the threshold co-ordinate list
thresh_list.append(seed)

# Insert the initial seed point into the threshold values list
thresh_values.append(array[seed[0]],array[seed[1]])



# Determine the threshold
for i in range(4):
    thresh_pix = [seed[0] + nbood[i][0], seed[1] + nbhood[i][1]]
    
    # Check if pixel exists within the image
    thresh_inside = rows > thresh_pix[0] > 0 and columns > thresh_pix[1] > 0
    
    # Add the neighbouring pixel if it exists within the image
    # and isn't already part of the segmented area
    if (thresh_inside and (seg[thresh_pix[0],thresh_pix[1]] == 0)):
        thresh_list.append(thresh_pix)
        thresh_values.append(array[thresh_pix[0]], array[thresh_pix[1]])

    #endif
#endfor


# Region mean and standard deviation
rmean = numpy.mean(thresh_values)
rstdv = numpy.std(thresh_values)

# Standard deviation multiplier
mult = 2

# Compute the upper and lower thresholds
rupper = rmean + (rstdv * mult)
rlower = rmean - (rstdv * mult)

# rsize isn't needed as the new region mean is computed differently
#rsize = 1


# List for neighbour co-ordinates
nb_list = []

# Data values of neighbours
nb_values = []


# Add neighbouring pixels
for i in range(4):
    n_pix = [seed[0] + nbood[i][0], seed[1] + nbhood[i][1]]
    
    # Check if pixel exists within the image
    inside = rows > n_pix[0] > 0 and columns > n_pix[1] > 0
    
    # Add the neighbouring pixel if it exists within the image
    # and isn't already part of the segmented area
    if (inside and (seg[n_pix[0],n_pix[1]] == 0)):
        nb_list.append(n_pix)
        nb_values.append(array[n_pix[0]], array[n_pix[1]])
        
        # Initially set to 128 to mark that it has been visited
        ''' Ignore at this stage.  It doesn't make sense to mark it as
        visited, as it won't be selected in later stages (I think).'''
        #seg[n_pix][0], seg[n_pix[1]] = 128
        
    #endif
#endfor

# Add the pixel with value nearest to the mean of the region
#nb_dist = numpy.abs(numpy.asarray(nb.values) - rmean)
nb_dist = [abs(x - rmean) for x in nb_values]
#dist = numpy.min(nb_dist)
dist = min(nb_dist)
# Get the index of the minimum
index_nb_dist = nb_dist.index(min(nb_dist))

# rsize isn't needed as the new region mean is computed differently
#rsize += 1

# Set the seed location to 255; i.e. segmented
seg[seed[0],seed[1]] = 255

# Update the region mean
seg_index = numpy.where(seg == 1)
total = array[seg_index].sum()
n_elements = array[seg_index].size
rmean = (total + nb_values[seg_index])/(n_elements + 1)

    