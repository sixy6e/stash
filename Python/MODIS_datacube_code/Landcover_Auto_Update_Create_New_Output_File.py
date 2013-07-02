from osgeo import gdal
#from osgeo.gdalconst import *
import os #os.remove, os.path.isfile, os.system...
import numpy
import time
#===============================================================================








#===============================================================================
def Create_And_Fill_New_Output_File(input_dir, output_dir, input_filename):
    
    # Define pathnames and output filenames
    input_pathname = os.path.join(input_dir, input_filename)
    output_filename = ''.join([input_filename[:-4], '_new'])
    output_pathname = os.path.join(output_dir, output_filename)
    
    # Open input file
    input_file = gdal.Open(input_pathname)
    
    # Define Tile height
    tile_height = 10
    
    # Calculate number of tiles in input image
    if input_file.RasterYSize%tile_height == 0:
        num_tiles = input_file.RasterYSize/tile_height
    else:
        num_tiles = (input_file.RasterYSize/tile_height)+1
    
    
    full_year_bands = 23
    number_of_years_to_add = 2 # Including last incomplete year
    number_of_bands_already_in_last_year = 6
    num_bands_to_add = full_year_bands * \
                       number_of_years_to_add - \
                       number_of_bands_already_in_last_year
    
    # Define number of bands to be in new output image file
    num_bands = input_file.RasterCount + num_bands_to_add
    
    # If new output file already exists, delete it
    if os.path.isfile(output_pathname):
        os.remove(output_pathname)
    
    # Create new output image file
    output_file = Create_Output_File(output_dir,
                                     output_filename,
                                     input_file, 
                                     num_bands)
    
    # Cycle through each tile
    for this_tile_num in range(num_tiles):
        
        # If this is the last tile (ie. likely shorter than a full tile)...
        if (this_tile_num+1) == num_tiles:
            
            # Calculate the height of the last tile
            short_tile_height = input_file.RasterYSize - (this_tile_num * 
                                                        tile_height)
            
            # Read current whole tile
            input_array = input_file.ReadAsArray(0, 
                                                 this_tile_num * tile_height, 
                                                 input_file.RasterXSize, 
                                                 short_tile_height)
            
            # Cycle through each band in current tile in original image file
            for this_band_num in range(input_file.RasterCount):
                
                # Print message to screen indicating current tile and band
                print 'Currently processing tile number', this_tile_num+1, \
                      'of', num_tiles, 'and band number', this_band_num+1, \
                      'of', input_file.RasterCount 
                
                # Define current band number
                output_band = output_file.GetRasterBand(this_band_num+1)
                
                # Write current band of current tile to new output image file
                output_band.WriteArray(input_array[this_band_num, :, :], 
                                       0, 
                                       this_tile_num*tile_height)

            # Cycle through each new band in current tile in new image file
            for this_extra_band_num in range(output_file.RasterCount - 
                                             input_file.RasterCount):
                
                # Define current band number
                this_band_num = this_extra_band_num+input_file.RasterCount
                
                # Print message to screen indicating current tile and band
                print 'Currently processing tile number', this_tile_num+1, \
                      'of', num_tiles, 'and band number', this_band_num+1, \
                      'of', output_file.RasterCount 
                
                # Define current band number
                output_band = output_file.GetRasterBand(this_band_num+1)
                
                # Write current band of current tile to new output image file
                output_band.WriteArray(numpy.zeros((short_tile_height, 
                                                    input_file.RasterXSize)), 
                                       0, 
                                       this_tile_num*tile_height)
        
        # ...Else this is not the last tile in the image (ie. full tile height)
        else:
            
            # Read current whole tile
            input_array = input_file.ReadAsArray(0, 
                                                 this_tile_num*tile_height, 
                                                 input_file.RasterXSize, 
                                                 tile_height)
            
            # Cycle through each band in current tile in original image file
            for this_band_num in range(input_file.RasterCount):
                
                # Print message to screen indicating current tile and band
                print 'Currently processing tile number', this_tile_num+1, \
                      'of', num_tiles, 'and band number', this_band_num+1, \
                      'of', input_file.RasterCount 
                
                # Define current band number
                output_band = output_file.GetRasterBand(this_band_num+1)
                
                # Write current band of current tile to new output image file
                output_band.WriteArray(input_array[this_band_num, :, :], 
                                       0, 
                                       this_tile_num*tile_height)

            # Cycle through each new band in current tile in new image file
            for this_extra_band_num in range(output_file.RasterCount - 
                                             input_file.RasterCount):
                
                # Define current band number
                this_band_num = this_extra_band_num+input_file.RasterCount
                
                # Print message to screen indicating current tile and band
                print 'Currently processing tile number', this_tile_num+1, \
                      'of', num_tiles, 'and band number', this_band_num+1, \
                      'of', output_file.RasterCount 
                
                # Define current band number
                output_band = output_file.GetRasterBand(this_band_num+1)
                
                # Write current band of current tile to new output image file
                output_band.WriteArray(numpy.zeros((tile_height, 
                                                    input_file.RasterXSize)), 
                                       0, 
                                       this_tile_num*tile_height)
    
    # Release input and output image files
    input_file = None
    output_file = None
#===============================================================================








#===============================================================================
# Take output filename, template dataset from which to take output attributes
# and the number of bands in the output dataset and create output dataset
#===============================================================================

def Create_Output_File(output_dir,
                       output_filename,
                       template_dataset, 
                       num_bands):
    """
    Take output filename, template dataset from which to take output attributes
    and the number of bands in the output dataset and create output dataset
    """
   
    # Define full directory path and filename
    full_path_and_filename = os.path.join(output_dir, output_filename)
    
    # Get driver with which to create output file
    format = "ENVI"
    driver = gdal.GetDriverByName(format)
    
    # Get datatype to create output file
    band1 = template_dataset.GetRasterBand(1)
    datatype = band1.DataType
   
    # Create output file
    output_dataset = driver.Create(full_path_and_filename, 
                                   template_dataset.RasterXSize, 
                                   template_dataset.RasterYSize, 
                                   num_bands, 
                                   datatype)

    # Set output projection and geotransform from template dataset
    output_dataset.SetProjection(template_dataset.GetProjection())
    output_dataset.SetGeoTransform(template_dataset.GetGeoTransform())

    if not os.path.isfile(full_path_and_filename):
        print ''.join(['Error: Failed to create file ',
                       full_path_and_filename])
      
    return output_dataset
#===============================================================================








#===============================================================================
# 
#===============================================================================
def Main():

    # Set processing start time
    time_start = time.time()
    
    # Test data location and names
#    input_dir = r'\\satsan\E\MODIS-LandCover\Data\Optical\MODIS-EVI-2000-2011'
#    output_dir = r'\\satsan\D\Landcover_Temp_Steven'
#    input_filename = '2000-2011_250m_EVI_stack.img'
    
    # Real input data location and names
    input_dir = r'\\satsan\E\MODIS-LandCover\Data\Optical\MODIS-EVI-2000-2011'
    output_dir = r'\\satsan\D\Landcover_Temp_Steven'
    input_filename = '2000-2011_250m_EVI_stack.img'
    
    # Create and fill in data for new output file
    Create_And_Fill_New_Output_File(input_dir, output_dir, input_filename)
    
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
