from osgeo import gdal
from osgeo.gdalconst import *
import os #os.remove, os.path.isfile, os.system...
#import numpy
import time
#===============================================================================








#===============================================================================
def Fill_In_Band_In_New_Output_Image(stack_dir, 
                                     stack_filename, 
                                     new_band_dir, 
                                     new_band_filename, 
                                     stack_band_to_update_num):
    
    # Define pathnames and output filenames
    new_band_pathname = os.path.join(new_band_dir, new_band_filename)
    stack_pathname = os.path.join(stack_dir, stack_filename)
    
    # Get file and new band to be added to new output image file
    new_band_file = gdal.Open(new_band_pathname)
    new_band_band = new_band_file.GetRasterBand(1)
    
    # Define tile height
    tile_height = 5
    
    # Calculate number of tiles in input image
    if new_band_file.RasterYSize%tile_height == 0:
        num_tiles = new_band_file.RasterYSize/tile_height
    else:
        num_tiles = (new_band_file.RasterYSize/tile_height)+1
    
    # Open new output image file
    stack_file = gdal.Open(stack_pathname, GA_Update)
    
    # Get blank band in new output image file to be updated
    stack_band_to_update = stack_file.GetRasterBand(stack_band_to_update_num)
    
    # Cycle through each tile in output image file band to be updated
    for this_tile_num in range(num_tiles):
        
        # Print message to screen indicating current tile
        print 'Currently processing tile number', this_tile_num+1, \
              'of', num_tiles
        
        # If this is the last tile (ie. likely shorter than a full tile)...
        if (this_tile_num+1) == num_tiles:
            
            # Calculate the height of the last tile
            short_tile_height = new_band_file.RasterYSize - (this_tile_num * 
                                                             tile_height)
            
            # Read current tile
            input_array = new_band_band.ReadAsArray(0, 
                                                    this_tile_num*tile_height, 
                                                    new_band_file.RasterXSize, 
                                                    short_tile_height)
            
            # Write current tile to new output image file band
            stack_band_to_update.WriteArray(input_array, 
                                            0, 
                                            this_tile_num*tile_height)
        
        # ...Else this is not the last tile in the image (ie. full tile height)
        else:
            
            # Read current tile
            input_array = new_band_band.ReadAsArray(0, 
                                                    this_tile_num*tile_height, 
                                                    new_band_file.RasterXSize, 
                                                    tile_height)
            
            # Write current tile to new output image file band
            stack_band_to_update.WriteArray(input_array, 
                                            0, 
                                            this_tile_num*tile_height)

    # Release all input and output bands and files
    stack_band_to_update = None
    stack_file = None
    new_band_band = None
    new_band_file = None
#===============================================================================

    






#===============================================================================
# 
#===============================================================================
def Main():

    # Set processing start time
    time_start = time.time()
    
    # Real input data location and names
#    input_dir = r'\\satsan\E\MODIS-LandCover\Data\Optical\MODIS-EVI-2000-2011'
#    output_dir = r'\\satsan\D\Landcover_Temp_Steven'
#    input_filename = '2000-2011_250m_EVI_stack.img'
    
    # Test input data location and names
    stack_dir = r'C:\Landcover'
    stack_filename = '2000-2011_250m_EVI_stack_large_new.tif'
    new_band_dir = r'C:\Landcover'
    new_band_filename = '2000-2011_250m_EVI_stack_large_new_band.tif'
    stack_band_to_update_num = 275
    
    Fill_In_Band_In_New_Output_Image(stack_dir, 
                                     stack_filename, 
                                     new_band_dir, 
                                     new_band_filename, 
                                     stack_band_to_update_num)
    
    # Calculate time at moment of completion of processing
    time_end = time.time()

    # Calculate time taken to complete processing and print results
    print 'time = ', ((time_end-time_start)/60), 'minutes'
    print 'time = ', ((time_end-time_start)/60)/60, 'hours'
#===============================================================================








#===============================================================================
# 
#===============================================================================
if __name__ == "__main__":

    Main()
