'''
Created on 08/11/2011

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
gdal.AllRegister()

# ------------------------------------------------------------------

# Need to get a list of the directories
def listdirs(folder):
    
    return [
            d for d in (os.path.join(folder, d1) for d1 in os.listdir(folder))
            if os.path.isdir(d)
            ]

# ------------------------------------------------------------------

# Need to search a folder from the list for valid images
# Is also used to find specific files, i.e. 'QACheckList.txt'
def locate(pattern, root):
    
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

# ------------------------------------------------------------------

# Returns the required line from a list of strings
def linefinder(array, string = ""):
    for line in array:
        if string in str(line):
            return line

# ------------------------------------------------------------------

# The null function
def null(image):
    # The first statement works for multi-band images
    shape = image.shape
    if len(shape) == 3:
        mask = image != 0
        mask = image.sum(axis = 0)
        # Return only those pixels that sum equal to the no. of bands
        mask = image == shape[0]
        return mask
    else:
        # Single band images
        mask = image != 0
        return mask
    # mask = image != 0
    return mask.astype('int')

# ------------------------------------------------------------------

# The saturation function
def saturation(image):
    # A combined search will not work. Need to have two separate searches
    # mask = image == 1 or image == 255
    # USE: mask = numpy.logical_and(image != 1, image != 255)
    mask = numpy.logical_and(image != 1, image != 255)
    # osat = image != 255
    # usat = image != 1
    # mask = osat * usat
    return mask.astype('int')

# ------------------------------------------------------------------

# Retrieve image info from the 'QACheckList.txt'
def image_info(mfile):
    
    f = open(mfile, 'r')
    array = f.readlines()

    # Find the data format
    ffind = linefinder(array, 'Product Type/Format')
    ob     = ffind.find('[')
    sl     = ffind.find('/', ob)
    cb     = ffind.find(']')
    sub    = ffind[sl+1:cb]
    dformat = sub.strip()

    # Find the sensor
    sfind  = linefinder(array, 'Satellite/Sensor')
    ob     = sfind.find('[')
    cb     = sfind.find(']')
    sensor = sfind[ob+1:cb].split()[0]

    # Find the image size in pixels; lines(rows), samples(columns)
    ifind   = linefinder(array, 'Image Size(Lines/Pixels)')
    ob      = ffind.find('[')
    cb      = ffind.find(']')
    sub     = ifind[ob+1:cb].split()
    lines   = int(sub[0])
    samples = int(sub[2])
    
    # Find the path and row
    prfind = linefinder(array, 'Path/Row')
    ob     = prfind.find('[')
    cb     = prfind.find(']')
    sl     = prfind.find('/', ob)
    path   = prfind[ob+1:sl].strip()
    row    = prfind[sl+1:cb].strip()
    
    # Find the acquisition date
    dfind = linefinder(array, 'Scene Date/SceneID')
    ob    = dfind.find('[')
    cb    = dfind.find(']')
    sub   = dfind[ob+1:cb].split()
    year  = sub[0]
    month = sub[1]
    day   = sub[2]
    
    f.close()
    
    return {
                'Satellite' : sensor,
                'Format'    : dformat,
                'Lines'     : lines,
                'Samples'   : samples,
                'Path'      : path,
                'Row'       : row,
                'Year'      : year,
                'Month'     : month,
                'Day'       : day,
            }

# ------------------------------------------------------------------

# Need to incorporate something that will look for any type of image file
# The *HRF.FST, *HTM.FST for LS7 and header.dat for LS5, for fast file format
# TIFF, flat binary (look for *.hdr, if found remove the .hdr to open the file)
# IMG (ERDAS Imagine)

input_dir = 'C:\WINNT\Profiles\u08087\My Documents\Imagery'
out_dir   = os.path.join(input_dir + 'Processed')
if not os.path.isdir(out_dir):
    os.makedirs(out_dir)

# Look for QACheckList.txt
# Get the sensor name, pixel dimensions, product format 
dir_stack = listdirs(input_dir)

for i in range(len(dir_stack)):

# Re-use the locate function.  It will return a list
# and the file if found will be list[0] otherwise
# the length will be zero which you can use to decide which step to take
    mfile = locate('QACheckList.txt', dir_stack[i])
    if len(mfile) != 0:
        # Open the QACheckList file and extract sensor name, scene dimensions,
        # product format, acquisition date, path/row, etc
        Image_Info = image_info(mfile)
        if image_info['Format'] == 'EOSAT Fast Format':
            img_list = locate('header.dat', dir_stack[i])
            
            # Create the output directory for only those folders with images
            out_fdir = os.path.join(out_dir, os.path.basename(dir_stack[i]))
            if not os.path.isdir(out_fdir):
                os.makedirs(out_fdir)
            
            # Get the image object
            iobj = gdal.Open(img_list[0], gdal.gdalconst.GA_ReadOnly)
            assert iobj

            # Retrieve image information
            metadata     = iobj.GetMetadata_Dict()
            geoTransform = iobj.GetGeoTransform()
            prj          = iobj.GetProjection()
            spt_ref      = osr.SpatialReference()
            
            # Open the image data into the variable image
            image = iobj.ReadAsArray()
            
            # Find saturation
            mask  = saturation(image)
            
            # Dummy array for LS5 band62
            dmy = numpy.ones((Image_Info['Lines'], Image_Info['Samples']),
                             dtype=numpy.byte)
            # Insert the dummy array before band 7 (pos = 6)
            # into the quality mask
            qmask = numpy.insert(mask, 6, dmy, axis=0)
            
            # Find nulls and produce contiguity
            mask = null(image)
            
            # Append the contiguity mask to the quality mask
            qmask = numpy.append(qmask, mask, axis=0)
            
            # Need to add the bit manipulator in here
            
            
    
        elif image_info['Format'] == 'FastL7A':
            img_list = locate(['*HRF.FST','*HTM.FST'], dir_stack[i])
            
            # Create the output directory for only those folders with images
            out_fdir = os.path.join(out_dir, os.path.basename(dir_stack[i]))
            if not os.path.isdir(out_fdir):
                os.makedirs(out_fdir)
            
            # Get the image object for 'HRF.FST'
            rfobj = gdal.Open(img_list[0], gdal.gdalconst.GA_ReadOnly)
            assert rfobj
            
            # Get the image object for 'HTM.FST'
            tmobj = gdal.Open(img_list[1], gdal.gdalconst.GA_ReadOnly)
            assert tmobj

            # Retrieve image information for 'HRF.FST'
            rfmetadata     = rfobj.GetMetadata_Dict()
            rfgeoTransform = rfobj.GetGeoTransform()
            rfprj          = rfobj.GetProjection()
            rfspt_ref      = osr.SpatialReference()
  
            # Retrieve image information for 'HTM.FST'
            tmmetadata     = tmobj.GetMetadata_Dict()
            tmgeoTransform = tmobj.GetGeoTransform()
            tmprj          = tmobj.GetProjection()
            tmspt_ref      = osr.SpatialReference()
            columns        = tmobj.RasterXSize
            rows           = tmobj.RasterYSize
            
            # Need to test the number of pixels for the thermal bands
            # If they're not the same, need to re-sample
                        
            # Open the image data into the variable image
            image = rfobj.ReadAsArray()
            
            # Find saturation
            mask  = saturation(image)

            # Find nulls and produce contiguity
            mask = null(image)

        
        # And whatever other formats may be needed.

    else:
        # Scan for other possible file types
        extensions = ['*.tif*', '*.hdr', '*.img']
        img_list = locate(extensions, dir_stack[i])

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

        # Get the filename; will be used to create the output filename
        fname = os.path.splitext(os.path.basename(img_list[0]))[0]
        
        if fname.find('LS7') != -1:
            # Process Landsat 7 data
            
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
            
            # Going to create an n-band array (-1 for panchromatic band)
            nbands = len(img_list)-1
            image  = numpy.zeros((nbands,rows,columns), dtype=numpy.byte)

            # Create the filenames for both null and sat
            # CHANGE TO OS.PATH.STRJOIN. Don't use string concatenation
            out_fname = os.path.join(out_fdir, fname) + '_sat_null.tif'
            
            # Set an output file for the multi-band image file
            # Need to create an auto filename
            driver = gdal.GetDriverByName("GTiff")
            outDataset = driver.Create(out_fname, columns, rows, bands = 9)
            
            # Don't want to process the panchromatic band; set -1 to loop
            for j in range(len(img_list)-1):
                # Retrieve the image object
                iobj = gdal.Open(img_list[j], gdal.gdalconst.GA_ReadOnly)
                assert iobj
                
                band = iobj.GetRasterBand(1)
                # Read the image into an array
                image[j,:,:] = band.ReadAsArray()
                
            # Find saturation
            mask  = saturation(image)
                
            # Write out the saturation mask to file
            # This allows the re-use of the mask variable and
            # conserves memory
            for b in range(len(mask)):
                outBand = outDataset.GetRasterBand(b+1)
                outBand.WriteArray(mask[b,:,:])
                
            # Find nulls and produce contiguity
            mask = null(image)
                
            # Write out the null mask to file
            # The last band is the null/pixel contiguity
            outBand = outDataset.GetRasterBand(9)
            outBand.WriteArray(mask)
            
            # Append the projection info and close the file 
            outDataset.SetGeoTransform(geoTransform)
            outDataset.SetProjection(prj)
            outDataset = None    

        else:
            # Process Landsat 5 data
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
            
            # Going to create an n-band array
            # The no. of bands has to match LS7. To account for b62
            nbands = len(img_list)
            image  = numpy.zeros((nbands +1,rows,columns), dtype=numpy.byte)

            # Create the filenames for both null and sat
            # CHANGE TO OS.PATH.STRJOIN. Don't use string concatenation
            out_fname = os.path.join(out_fdir, fname) + '_sat_null.tif'
            
            # Set an output file for the multi-band image file
            # Need to create an auto filename
            driver = gdal.GetDriverByName("GTiff")
            outDataset = driver.Create(out_fname, columns, rows, bands = 9)
            
            # Open the list of images into a single array
            # TODO, insert an array of ones into the b62 pos
            # this is so LS5 matches with LS7 in terms of no. bands
            for j in range(len(img_list)):
                # Retrieve the image object
                iobj = gdal.Open(img_list[j], gdal.gdalconst.GA_ReadOnly)
                assert iobj
                
                # Need to create the dummy array for b62
                if j == 6:
                    band           = iobj.GetRasterBand(1)
                    image[j,:,:]   = 1
                    image[j+1,:,:] = band.ReadAsArray()
                    
                else:
                    band = iobj.GetRasterBand(1)
                    # Read the image into an array
                    image[j,:,:] = band.ReadAsArray()
                    
                band = iobj.GetRasterBand(1)
                # Read the image into an array
                image[j,:,:] = band.ReadAsArray()
                
            # Find saturation
            mask  = saturation(image)
            
            # Account for the saturation detected for the dummy band b62
            # and change the values back to one (good pixels)
            mask[6,:,:] = 1
                
            # Write out the saturation mask to file
            # This allows the re-use of the mask variable and
            # conserves memory
            for b in range(len(mask)):
                outBand = outDataset.GetRasterBand(b+1)
                outBand.WriteArray(mask[b,:,:])
                
            # Find nulls and produce contiguity
            mask = null(image)
                
            # Write out the null mask to file
            # The last band is the null/pixel contiguity
            outBand = outDataset.GetRasterBand(9)
            outBand.WriteArray(mask)
            
            # Append the projection info and close the file 
            outDataset.SetGeoTransform(geoTransform)
            outDataset.SetProjection(prj)
            outDataset = None    
