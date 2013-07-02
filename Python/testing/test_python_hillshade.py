#! /usr/bin/env python
import sys
import argparse
import numpy
from scipy import ndimage
from osgeo import gdal
from scipy import interpolate

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

def slope_aspect(array, pix_size, scale):
    dzdx = ndimage.sobel(array, axis=1)/(8.*pix_size)
    dzdy = ndimage.sobel(array, axis=0)/(8.*pix_size)
    #slp = numpy.arctan(numpy.hypot(dzdx,dzdy)) # include scale factor for 
    # Lat/Lon data
    # eg numpy.hypot(dzdx,dzdy)*0.00000898 
    # or
    # numpy.hypot(dzdx,dzdy)/111120
    #slp = numpy.arctan(numpy.hypot(dzdx,dzdy)/scale)  
    slp = numpy.arctan(numpy.hypot(dzdx,dzdy)*scale)  
    asp = numpy.arctan2(dzdy, -dzdx)
    return slp, asp

def hillshade(slope, aspect, azimuth, elevation):

    az   = numpy.deg2rad(360 - azimuth + 90)
    elev = numpy.deg2rad(90 - elevation)
    hs   = numpy.cos(elev) * numpy.cos(slope) + (numpy.sin(elev)*numpy.sin(slope)*numpy.cos(az-aspect))

    hs_scale = numpy.round(254 * hs +1)
    return hs_scale.astype('int')

def img2map(geoTransform, pixel):
    mapx = pixel[1] * geoTransform[1] + geoTransform[0]
    mapy = geoTransform[3] - (pixel[0] * (numpy.abs(geoTransform[5])))
    return (mapx,mapy)

def map2img(geoTransform, location):
    imgx = int(numpy.round((location[0] - geoTransform[0])/geoTransform[1]))
    imgy = int(numpy.round((geoTransform[3] - location[1])/numpy.abs(geoTransform[5])))
    return (imgy,imgx)

# TODO
# Create something that will take arguments from the command line.
# Allow a scale factor to be used for scenes that are not in metres ie. Lat/Lon 

if __name__ == '__main__':
    '''
    # sys.argv inputs are strings. Convert to float where necessary.
    elevation = numpy.deg2rad(90 - float(sys.argv[1]))
    azimuth = numpy.deg2rad(360 - float(sys.argv[2]) + 90)
    scale = float(sys.argv[3])
    image_fname = sys.argv[4]
    out_fname =i sys.argv[5]
    '''

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Calculates a hillshade from a DEM.')
    parser.add_argument('--elev', type=float, default=45.0, help='Sun elevation angle in degrees. Defaults to 45 degrees.')
    parser.add_argument('--azi', type=float, default=315.0, help='Sun azimuthal angle in degrees. Defaults to 315 degrees.')
    parser.add_argument('--sf', type=float, default=1.0, help='Include a scale factor if the image is in degrees (lat/long), eg 0.00000898. Defaults to 1.')
    parser.add_argument('--zf', type=float, default=1.0, help='Multiply the image by the zfactor prior to hillshading.')

    parser.add_argument('--sarray', action="store_true", help='If set, the process will create an array of scale factors for each row (scale factors change with lattitude).')

    parser.add_argument('--infile', required=True, help='The input DEM on which to create the hillshade')   
    parser.add_argument('--outfile', required=True, help='The output filename.')
    parser.add_argument('--driver', default='ENVI', help="The file driver type for the output file. See GDAL's list of valid file types. (Defaults to ENVI).")

    parsed_args = parser.parse_args()

    ifile = parsed_args.infile
    iobj = gdal.Open(ifile, gdal.gdalconst.GA_ReadOnly)
    assert iobj
    image = iobj.ReadAsArray()
    geoT = iobj.GetGeoTransform()
    prj = iobj.GetProjection() 
    dims = image.shape

    if parsed_args.sarray == True:
        latlist = []
        for row in range(image.shape[0]):
            latlist.append(img2map(geoT, pixel=(row,0))[1])
        latarray = numpy.abs(numpy.array(latlist))

        # Approx lattitude scale factors from ESRI help
        # http://webhelp.esri.com/arcgisdesktop/9.2/index.cfm?TopicName=Hillshade
        x = numpy.array([0,10,20,30,40,50,60,70,80])
        y = numpy.array([898,912,956,1036,1171,1395,1792,2619,5156])/100000000.
        yf   = interpolate.splrep(x,y)
        yhat = interpolate.splev(latarray, yf)

        scalef_array = numpy.ones((dims[0],dims[1]), dtype=float)
        for col in range(image.shape[1]):
            scalef_array[:,col] *= yhat
        scale_factor = scalef_array
    else:
        scale_factor = parsed_args.sf

    slope, aspect = slope_aspect(array=image, pix_size=geoT[1], scale=scale_factor)
    azi = parsed_args.azi
    elev = parsed_args.elev
    hshade = hillshade(slope, aspect, azimuth=azi, elevation=elev)

    drv = parsed_args.driver

    driver = gdal.GetDriverByName(drv)
    out_name = parsed_args.outfile
    outds  = driver.Create(out_name, dims[1], dims[0],1, gdal.GDT_Byte)
    outds.SetGeoTransform(geoT)
    outds.SetProjection(prj)
    outband = outds.GetRasterBand(1)
    outband.WriteArray(hshade)
    outds = None



