#!/usr/bin/env python

import argparse
import numpy
from osgeo import gdal
import numexpr
from skimage import morphology
from python_hillshade import hillshade

def imfill(image):
    """
    Replicates the imfill function available within MATLAB.
    Based on the example provided in http://scikit-image.org/docs/dev/auto_examples/plot_holes_and_peaks.html#example-plot-holes-and-peaks-py.

    :param image):
        A 2D numpy array containing "holes". Darker pixels surrounded by brighter pixels.

    :return:
        A 2D numpy array of type Float with the "holes" from image filled.

    """

    seed = image.copy()

    # Define seed points and the start points for the erosion process.
    seed[1:-1, 1:-1] = image.max()

    # Define the mask; Probably unneeded.
    mask = image

    # Fill the holes
    filled = morphology.reconstruction(seed, mask, method='erosion')

    return filled

def get_terrin_shadow_mask(image, sun_azimuth, sun_elevation, scale_array, scale_factor, projection, geotransform):
    """
    Retrieves the terrain shadow mask.

    :param image:
        A 2D numpy array containing the DEM.

    :param sun_azimuth:
        A floating point number representing the sun azimuthal angle in degrees.

    :param sun_elevation:
        A floating point number representing the sun elevation angle in degrees.

    :param scale_array:
        If True, the process will create an array of scale factors for each row (scale factors change with lattitude).

    :param scale_factor:
        Include a scale factor if the image is in degrees (lat/long), eg 0.00000898. Defaults to 1.

    :param projection:
        A GDAL like object containing the projection parameters of the DEM. A string containing WKT.

    :param geotransform:
        A GDAL like object containing the GeoTransform parameters of the DEM. A tuple (ULx, pix_x_size, rotation, ULy, rotation, pix_y_size).

    :return:
        A 2D numpy array of type UInt8 containing the terrain shadow mask.

    """

    hshade   = hillshade(dem=image, elevation=sun_elevation, azimuth=sun_azimuth, scalearray=scale_array, scalefactor=scale_factor, projection=projection, GeoTransform=geotransform)

    fill     = imfill(hshade)
    t_shadow = (numexpr.evaluate("(hshade - fill) >= 0")).astype('uint8') # Negative values are the holes

    return t_shadow

def input_output_main(infile, outfile, sun_azimuth, sun_elevation, scale_array, scale_factor, driver='ENVI'):
    """
    A function to handle the input and ouput of image files.  GDAL is used for reading and writing files to and from the disk.
    This function also acts as main when called from the command line.

    :param infile:
        A string containing the full filepath of the input image filename.

    :param outfile:
        A string containing the full filepath of the output image filename.

    :param azimuth:
        Sun azimuthal angle in degrees. Defaults to 315 degrees.

    :param elevation:
        Sun elevation angle in degrees. Defaults to 45 degrees.

    :param scale_array:
        If True, the process will create an array of scale factors for each row (scale factors change with lattitude).

    :param scale_factor:
        Include a scale factor if the image is in degrees (lat/long), eg 0.00000898. Defaults to 1.

    :param driver:
        A string containing a GDAL compliant image driver. Defaults to ENVI.

    """

    ds   = gdal.Open(infile)
    img  = ds.ReadAsArray()
    proj = ds.GetProjection()
    geoT = ds.GetGeoTransform()

    dims = img.shape

    shadow_mask = get_terrin_shadow_mask(image=img, sun_azimuth=sun_azimuth, sun_elevation=sun_elevation, scale_array=scale_array, scale_factor=scale_factor, projection=proj, geotransform=geoT)

    drv   = gdal.GetDriverByName(driver)
    outds = drv.Create(outfile, dims[1], dims[0], 1, 1)
    band  = outds.GetRasterBand(1) # We're only outputting a single band
    band.WriteArray(shadow_mask)
    outds.SetProjection(proj)
    outds.SetGeoTransform(geoT)

    outds = None # Close the dataset and flush to disk.
    


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Generates a terrain shadow mask. The method is based on greyscale morphological reconstruction and uses a hillshade as input.')
    parser.add_argument('--infile', required=True, help='The input DEM on which to create extract the terrain shadow.')
    parser.add_argument('--outfile', required=True, help='The output filename.')
    parser.add_argument('--driver', default='ENVI', help="The file driver type for the output file. See GDAL's list of valid file types. (Defaults to ENVI).")
    parser.add_argument('--elev', type=float, default=45.0, help='Sun elevation angle in degrees. Defaults to 45 degrees.')
    parser.add_argument('--azi', type=float, default=315.0, help='Sun azimuthal angle in degrees. Defaults to 315 degrees.')
    parser.add_argument('--sf', type=float, default=1.0, help='Include a scale factor if the image is in degrees (lat/long), eg 0.00000898. Defaults to 1.')
    parser.add_argument('--sarray', action="store_true", help='If set, the process will create an array of scale factors for each row (scale factors change with lattitude).')


    parsed_args = parser.parse_args()

    infile       = parsed_args.infile
    outfile      = parsed_args.outfile
    drv          = parsed_args.driver
    sarray       = parsed_args.sarray
    scale_factor = parsed_args.sf
    azi          = parsed_args.azi
    elev         = parsed_args.elev

    input_output_main(infile, outfile, azi, elev, sarray, scale_factor, drv)

