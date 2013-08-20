#! /usr/bin/env python

import pdb

import os
import numpy
import cmath
from scipy import ndimage
from osgeo import gdal
import osr


# Convert the origin pixel co-ordinates to map units
def origin_map(geoTransform, cindex):
    omapx = cindex[1]*geoTransform[1] + geoTransform[0]
    omapy = geoTransform[3] - (cindex[0]*(numpy.abs(geoTransform[5])))
    return omapx, omapy

# Determine the cloud height
def cloud_height(ctherm, surface_temp, lapse_rate=6.6):
    return ((surface_temp - ctherm)/lapse_rate)*1000

# Determine the length of the shadow
def shadow_length(cheight, rad_elev):
    return cheight/numpy.tan(rad_elev)

# Retrieve the x and y location in terms of metres from origin
def rect_xy(shad_length, rad_cor_az, dims):
    rectxy = numpy.empty(shad_length.shape, dtype='complex64')
    for i in xrange(len(shad_length)):
        rectxy[i] = cmath.rect(shad_length[i], rad_cor_az)
    return rectxy

# Convert the rectangular xy locations into map co-ordinates
def mapxy(rect_xy, omapx, omapy):
    new_mapx = omapx + numpy.real(rect_xy)
    new_mapy = omapy + numpy.imag(rect_xy)
    return new_mapx, new_mapy

# Convert the new mapxy locations to image co-ordinates
def map2img(new_mapx, new_mapy, geoTransform):
    imgx = numpy.round((new_mapx - geoTransform[0])/geoTransform[1]).astype('int')
    imgy = numpy.round((geoTransform[3] - new_mapy)/(numpy.abs(geoTransform[5]))).astype('int')
    return (imgy, imgx)


''' The projection of shadow can result in locations existing outside
    the actual dimensions of the image.  To account for these occurrences, 
    find the values and change the image co-ordinate to zero for both axes.
    
    Not really needed anymore, as the region grow function ignores
    pixels/seed locations that exist outside the dimensions of the image.
'''


# The region grow function; feed in band 4 (NIR).
def region_grow(array, seed, cloud, green):
    
    dims = array.shape
    
    # For Testing
    print dims
    
    # Create the array that will hold the cloud shadow
    cshadow = numpy.zeros(dims, dtype='byte')
    
    # Create the neighbourhood to search
    s = [[1,1,1],[1,1,1],[1,1,1]]
    
    # Fir Testing
    print len(seed[0])
    
    #d1range = range(0, dims[1])
    #d0range = range(0, dims[0])
        
    # Need to loop over the list of seed values/locations
    for i in xrange(len(seed[0])):
        
        # Find the seed's neighbours
        x   = numpy.arange(9) % 3 + (seed[1][i] - 1)
        y   = numpy.arange(9) / 3 + (seed[0][i] - 1)
        roi = (y,x)
        
        # Need to check if the co-ordinate exists within the image
        if ((seed[1][i] >=0 and seed[1][i] < dims[1]) and
             (seed[0][i] >= 0 and seed[0][i] < dims[0])):
            
        #if seed[1][i] in d1range and seed[0][i] in d0range:
            
            # Check to see if the pixel has already been assigned, and is below
            # a relatively generous threshold for shadow
            if ((cshadow[seed[0][i],seed[1][i]] == 0) and 
                (array[seed[0][i],seed[1][i]] < 0.12) and
                (green[seed[0][i],seed[1][i]] < 0.045)):
            #if ((cshadow[roi] == 0) * (array[roi] < 0.1)):
            
            
                # TODO Check the co-ordinates of the ROI. If any pixels are
                # outside of the image, +- respectively. This will just 
                # duplicate some pixels in the ROI, and reduce the variability
                # of the statistics.
                
                # Find the bounds
                bxmin = numpy.where(roi[1] < 0)
                bymin = numpy.where(roi[0] < 0)
                bxmax = numpy.where(roi[1] >= dims[1])
                bymax = numpy.where(roi[0] >= dims[0])
                
                # Change if roi co-ordinates exist outside the image domain.
                roi[1][bxmin] = 0
                roi[0][bymin] = 0
                roi[1][bxmax] = dims[1]-1
                roi[0][bymax] = dims[0]-1
            
                # Calculate the mean of the roi
                mean = numpy.mean(array[roi])
                
                # Calculate the standard deviation of the roi
                stdv = numpy.std(array[roi], ddof=1)
                
                # Max value of the roi
                mx = numpy.max(array[roi])
                
                # Check if the roi has a cloud pixel
                ssum = numpy.sum(cloud[roi])

                # Test for stats exceedance
                #if ((mean <= 0.15) and (stdv <= 0.08)):
                #if (mx <= 0.25):
                #if (stdv <= 0.08):
                if ((ssum == 0) and (stdv <= 0.07) and (mx <= 0.13)):
                    
                    # Standard deviation multiplier
                    limit = 2.5 * stdv

                    # Create the upper and lower thresholds
                    hi  = mean + limit
                    low = mean - limit
                    
                    if hi > 0.17:
                        hi = 0.17

                    # Create the mask via the thresholds
                    mask = (array >= low) & (array <= hi) 
        
                    # The label function segments the image into contiguous blobs
                    label_array, num_labels = ndimage.label(mask, structure=s)
                    
                    # Test using a 4 element structure for labelling
                    #label_array, num_labels = ndimage.label(mask)

                    # Calculate the histogram of the entire labelled array
                    hist_labels, bin_edges = numpy.histogram(label_array, bins=
                                                         numpy.arange(num_labels+1))

                    # Calculate the histogram of the labelled array using the roi
                    hist_roi_labels, b_edge = numpy.histogram(label_array[roi], bins=
                                                          numpy.arange(num_labels+1))

                    # Retrieve the labels that exist within the roi
                    roi_labels = numpy.where(hist_roi_labels != 0)
                    
                    # For Testing
                    print "i = ", i
                    print "ROI Labels: ", roi_labels

                    # Total number of pixels with the same label as those found within the roi
                    # This might have to be refined if more than one label exists within the roi
            
                    num_pixels2 = hist_labels[roi_labels][0]
                    
                    # For Testing
                    print "No. Pixels v1: ", num_pixels2
                    
                    num_pixels3 = hist_labels[roi_labels[0]]
                    
                    # For Testing
                    print "No. Pixels v2: ", num_pixels3
                    

                    '''
                    Maybe something like this?

                    num_pixels = (hist_labels[roi_labels]).sum() -(hist_labels[roi_labels[0]]*(roi_labels[0] ==0))
                    '''
                    # Num pixels could be used as an iterative threshold
                    # eg if num_pixels[i+1] - num_pixels <10 then stop?
                    num_pixels = (hist_labels[roi_labels]).sum() -(hist_labels[roi_labels[0]]*
                                                               (roi_labels[0] ==0))[0]
                    
                    # For Testing
                    print "No. Pixels v3: ", num_pixels
                    
                    '''
                    Num pixels version 3 works best.  Still at this stage num pixels 
                    isn't used.
                    '''
                    
                    # For the case of more than 1 label existing within the roi
                    num_roi_labels = len(roi_labels[0])
                    for j in range(num_roi_labels):
                        if roi_labels[0][j] != 0:
                            grown_region = numpy.where(label_array == roi_labels[0][j])
                            cshadow[grown_region] = 1
                    

                    # This *WILL* have to be refined if more than one label exists within the roi
                    #grown_region = numpy.where(label_array == roi_labels)
                    print
                    #print 'GROWN_REGION', grown_region
                    #pdb.set_trace()
      
                    #cshadow[grown_region] = 1
                    
                    '''
                    # Iteration Testing
                    mask_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\mask' + str(i) + '.tif'
                    driver = gdal.GetDriverByName("GTiff")
                    outDataset = driver.Create(mask_fname, dims[1], dims[0])
                    outBand = outDataset.GetRasterBand(1)
                    outBand.WriteArray(mask)
                    outDataset = None
                
                    shad_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\shadow' + str(i) + '.tif'
                    outDataset = driver.Create(shad_fname, dims[1], dims[0])
                    outBand = outDataset.GetRasterBand(1)
                    outBand.WriteArray(cshadow)
                    outDataset = None
                
                    roi_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\roi' + str(i) + '.tif'
                    outDataset = driver.Create(roi_fname, dims[1], dims[0])
                    outBand = outDataset.GetRasterBand(1)
                    roi_mask = numpy.zeros(dims, dtype='byte')
                    roi_mask[roi] = 1
                    outBand.WriteArray(roi_mask)
                    outDataset = None
                
                    label_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\label' + str(i) + '.tif'
                    outDataset = driver.Create(label_fname, dims[1], dims[0])
                    outBand = outDataset.GetRasterBand(1)
                    outBand.WriteArray(label_array)
                    outDataset = None
                    '''





    return cshadow




elevation    = 59.2570764
rad_elev     = numpy.radians(elevation)
azimuth      = 122.1870698
corrected_az = 360 - azimuth - 180 + 90
rad_cor_az   = numpy.radians(corrected_az)

#ci = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\full_scene\ACCA_Script_run_mask'
#ti = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\full_scene\L5_2009_12_04_correct_units'

ci = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\ACCA_Script_run_subs.tif'
ti = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\subs'

ciobj  = gdal.Open(ci, gdal.gdalconst.GA_ReadOnly)
tiobj  = gdal.Open(ti, gdal.gdalconst.GA_ReadOnly)
cloud  = ciobj.ReadAsArray()
tband  = tiobj.GetRasterBand(6)
therm  = tband.ReadAsArray()


metadata     = ciobj.GetMetadata_Dict()
geoTransform = ciobj.GetGeoTransform()
prj          = ciobj.GetProjection()
spt_ref      = osr.SpatialReference()
columns      = ciobj.RasterXSize
rows         = ciobj.RasterYSize

# Get the image dimensions
dims = therm.shape

# Get the indices of cloud
cindex = numpy.where(cloud == 1)
ctherm = therm[cindex]
del therm

# How to get the surface temperature?
'''
Maybe a combination of non-cloud pixels, non-null pixels, non-sea pixels,
and NDVI > 0.5 and then find the mean?
'''

cheight = cloud_height(ctherm, surface_temp=298)
omapx, omapy = origin_map(geoTransform, cindex)
shad_length = shadow_length(cheight, rad_elev)
rectxy = rect_xy(shad_length, rad_cor_az, dims)
new_mapx, new_mapy = mapxy(rectxy, omapx, omapy)
sindex = map2img(new_mapx, new_mapy, geoTransform)

b4band = tiobj.GetRasterBand(4) 
nir    = b4band.ReadAsArray()
b2band = tiobj.GetRasterBand(2) 
grn    = b2band.ReadAsArray()

# Cleaning up to save memory
del cheight, omapx, omapy, shad_length, rectxy, new_mapx, new_mapy, ctherm

cshadow = region_grow(array=nir, seed=sindex, cloud=cloud, green=grn)

bounds_miny = numpy.where(sindex[0] <0)
bounds_minx = numpy.where(sindex[1] <0)
bounds_maxy = numpy.where(sindex[0] >= dims[0])
bounds_maxx = numpy.where(sindex[1] >= dims[1])
sindex[0][bounds_miny] = 0
sindex[1][bounds_minx] = 0
sindex[0][bounds_maxy] = 0
sindex[1][bounds_maxx] = 0

cshadow2 = numpy.zeros(dims, dtype='byte')
cshadow2[sindex] = 1

# Where a shadow pixel is a cloud pixel, change to no shadow
cshadow[cindex] = 0
cshadow2[cindex] = 0


out_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\Cloud_Shadowsubs4.tif'
driver = gdal.GetDriverByName("GTiff")
outDataset = driver.Create(out_fname, columns, rows)
outBand = outDataset.GetRasterBand(1)
outBand.WriteArray(cshadow)

outDataset.SetGeoTransform(geoTransform)
outDataset.SetProjection(prj)
outDataset = None


out_fname = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\2009_12_04\Other_Test_Subs\Cloud_Projfsubs4.tif'
driver = gdal.GetDriverByName("GTiff")
outDataset = driver.Create(out_fname, columns, rows)
outBand = outDataset.GetRasterBand(1)
outBand.WriteArray(cshadow2)

outDataset.SetGeoTransform(geoTransform)
outDataset.SetProjection(prj)
outDataset = None

