'''
Created on 01/11/2011

@author: u08087
'''

import sys
import os
import numpy
from osgeo import gdal
import fnmatch
import osr
#import string
import pdb


gdal.UseExceptions()

# ------------------------------------------------------------------

# Need to get a list of the directories
def listdirs(folder):
    
    return [
            d for d in (os.path.join(folder, d1) for d1 in os.listdir(folder))
            if os.path.isdir(d)
            ]

# ------------------------------------------------------------------

# Need to search a folder from the list for valid images
def locate(pattern, root):
    
    matches = []
 
    for path, dirs, files in os.walk(os.path.abspath(root)):
        for filename in fnmatch.filter(files, pattern):
            matches.append(os.path.join(path, filename))
 
    return matches

# ------------------------------------------------------------------

# The null function
def null(image):
    # Need to reverse the selection
    # mask = image == 0
    # Could incorporate multi-band files
    # shape = image.shape
    # if len(shape) = 3:
    #     mask = image != 0
    #     mask = image.sum(axis = 0)
    #     mask = image == shape[0]
    #     return mask
    # else:
    #     mask = image != 0
    #     return mask
    mask = image != 0
    return mask

# ------------------------------------------------------------------

# The saturation function
def saturation(image):
    # The combined search will not work. Need to have two separate searches
    # mask = image == 1 or image == 255
    # Need to reverse the selection
    # osat = image == 255
    # usat = image == 1
    # mask = osat + usat
    osat = image != 255
    usat = image != 1
    mask = osat * usat
    return mask

# ------------------------------------------------------------------

# Need to read the images from the folder
#def openimages(imgpath = '', band_number=1, mode=gdal.gdalconst.GA_ReadOnly):
    
    # Error handling
#    if not imgpath:
#        print 'ERROR: imgpath unspecified'
#        return

#    if not os.path.exists(imgpath):
#        print 'ERROR: file not found (%s)' % imgpath
#        return
    
    # Retrieve the image object
#    iobj = gdal.Open(imgpath, mode)
    
    # Retrieve image information
#    metadata = iobj.GetMetadata_Dict()
#    prj      = iobj.GetProjection()
#    spt_ref  = osr.SpatialReference()
#    columns  = iobj.RasterXSize
#    rows     = iobj.RasterYSize
#    band     = iobj.GetRasterBand(band_number)
    
    # Read the image into an array
#    image = band.ReadAsArray()
    
#    return image
# ------------------------------------------------------------------
# Need to try and incorporate a looping structure

# Set up the input and output directories
input_dir = 'C:\WINNT\Profiles\u08087\My Documents\Imagery'
out_dir   = os.path.join(input_dir + 'Processed')
if not os.path.isdir(out_dir):
    os.makedirs(out_dir)
dir_stack = listdirs(input_dir)

ext = '*.tif'

# Loops
for i in range(len(dir_stack)):
    img_list = locate(ext, dir_stack[i])
    
    # Need to account for the case of no images found
    if len(img_list) != 0:
        
        # Create the output directory for only those folders with images
        out_fdir = os.path.join(out_dir, os.path.basename(dir_stack[i]))
        if not os.path.isdir(out_fdir):
            os.makedirs(out_fdir)
        
        # For the first instance, create the output files & get image info;
        # doing this will remove an "IF block" statement
        iobj = gdal.Open(img_list[0], gdal.gdalconst.GA_ReadOnly)
        
        # Retrieve image information
        metadata     = iobj.GetMetadata_Dict()
        geoTransform = iobj.GetGeoTransform()
        prj          = iobj.GetProjection()
        spt_ref      = osr.SpatialReference()
        columns      = iobj.RasterXSize
        rows         = iobj.RasterYSize
        
        # Get the filename; will be used to create the output filename
        fname = os.path.splitext(os.path.basename(img_list[0]))[0]
        
        # Create the filenames for both null and sat
        # CHANGE TO OS.PATH.STRJOIN. Don't use string concatenation
        null_out_fname = os.path.join(out_fdir, fname) + '_null.tif'
        sat_out_fname  = os.path.join(out_fdir, fname) + '_sat.tif'
        
        # Set an output file for the multi-band image file
        # Need to create an auto filename
        driver = gdal.GetDriverByName("GTiff")
        
        # Set the number of bands
        # Need to change string.find to fname.find(), then won't need import
        # string
        if fname.find('LS7') != -1:
            Null_outDataset = driver.Create(null_out_fname, columns,\
                                        rows, bands = 8)
        else:
            Null_outDataset = driver.Create(null_out_fname, columns,\
                                        rows, bands = 7)        
        
        Sat_outDataset = driver.Create(sat_out_fname, columns,\
                                        rows, bands = 8)
        
        
        # Don't want to process the panchromatic band
        for j in range(len(img_list)):
            # Retrieve the image object
            iobj = gdal.Open(img_list[j], gdal.gdalconst.GA_ReadOnly)
            assert iobj
                      
            # Also need to do a case for building a blank array
            # for L5TM that corresponds to L7ETM b62 
            
            # Get the filename; will be used for finding L5*b6
            # Also used to create the output filename
            fname = os.path.splitext(os.path.basename(img_list[j]))[0]
            
            # Generate the number of bands needed for null output
            # Process L7ETM data
            if fname.find('LS7') != -1:
                #bands = 8
                # Stop the process at the panchro band
                if fname.find('_b8') == -1:
                    #if j == 0:
                        # Retrieve image information
                        #metadata     = iobj.GetMetadata_Dict()
                        #geoTransform = iobj.GetGeoTransform()
                        #prj          = iobj.GetProjection()
                        #spt_ref      = osr.SpatialReference()
                        #columns      = iobj.RasterXSize
                        #rows         = iobj.RasterYSize
                
                        # Create the filenames for both null and sat
                        #null_out_fname = out_fdir + '\\' + fname + '_null.tif'
                        #sat_out_fname  = out_fdir + '\\' + fname + '_sat.tif'
                               
                        # Set an output file for the multi-band image file
                        # Need to create an auto filename
                        #driver = gdal.GetDriverByName("GTiff")
                        #Null_outDataset = driver.Create(null_out_fname, columns,\
                        #                             rows, bands = bands)
                        #Sat_outDataset = driver.Create(sat_out_fname, columns,\
                        #                            rows, bands = bands)
                
                    band = iobj.GetRasterBand(1)
                    # Read the image into an array
                    image = band.ReadAsArray()
            
                    # Processing steps
                    sat_mask  = saturation(image)
                    null_mask = null(image)
            
                    # Write the dataset to file
                    Null_outBand = Null_outDataset.GetRasterBand(j+1)
                    Null_outBand.WriteArray(null_mask)
                    Sat_outBand = Sat_outDataset.GetRasterBand(j+1)
                    Sat_outBand.WriteArray(sat_mask)
            
                
            else:
                # Process L5TM data
                #bands = 7

                
                #if j == 0:
                    # Retrieve image information
                    #metadata     = iobj.GetMetadata_Dict()
                    #geoTransform = iobj.GetGeoTransform()
                    #prj          = iobj.GetProjection()
                    #spt_ref      = osr.SpatialReference()
                    #columns      = iobj.RasterXSize
                    #rows         = iobj.RasterYSize
                
                    # Create the filenames for both null and sat
                    #null_out_fname = out_fdir + '\\' + fname + '_null.tif'
                    #sat_out_fname  = out_fdir + '\\' + fname + '_sat.tif'
                               
                    # Set an output file for the multi-band image file
                    # Need to create an auto filename
                    #driver = gdal.GetDriverByName("GTiff")
                    #Null_outDataset = driver.Create(null_out_fname, columns,\
                    #                                 rows, bands = bands)
                    #Sat_outDataset = driver.Create(sat_out_fname, columns,\
                    #                                rows, bands = 8)
                
                band = iobj.GetRasterBand(1)
                # Read the image into an array
                image = band.ReadAsArray()
            
                # Processing steps
                sat_mask  = saturation(image)
                null_mask = null(image)
            
                # Write the dataset to file
                if j == 6:
                    # Create a dummy array of ones for the
                    # existent b62 band
                    dummy_array = numpy.ones((rows, columns),\
                                 dtype =numpy.byte)
                    dummy_outBand = Sat_outDataset.GetRasterBand(j+1)
                    dummy_outBand.WriteArray(dummy_array)
                    Sat_outBand = Sat_outDataset.GetRasterBand(j+2)
                    Sat_outBand.WriteArray(sat_mask)
                
                elif j < 6:    
                    Null_outBand = Null_outDataset.GetRasterBand(j+1)
                    Null_outBand.WriteArray(null_mask)
                    Sat_outBand = Sat_outDataset.GetRasterBand(j+1)
                    Sat_outBand.WriteArray(sat_mask)
                    
        # Append the projection information and close the files
        
        assert Null_outDataset
        assert Sat_outDataset
        assert geoTransform
        print '***', geoTransform
        pdb.set_trace()
        
        Null_outDataset.SetGeoTransform(geoTransform)
        Sat_outDataset.SetGeoTransform(geoTransform)
        Null_outDataset.SetProjection(prj)
        Sat_outDataset.SetProjection(prj)
        Null_outDataset = None
        Sat_outDataset  = None


