#! /usr/bin/env python

import os
import sys
import argparse
import numpy
from osgeo import gdal
import ogr
import osr

def img2map(geoTransform, pixel):
    mapx = pixel[1] * geoTransform[1] + geoTransform[0]
    mapy = geoTransform[3] - (pixel[0] * (numpy.abs(geoTransform[5])))
    return (mapx,mapy)

def map2img(geoTransform, location):
    imgx = int(numpy.round((location[0] - geoTransform[0])/geoTransform[1]))
    imgy = int(numpy.round((geoTransform[3] - location[1])/numpy.abs(geoTransform[5])))
    return (imgy,imgx)

if __name__ == '__main__':
    '''
    Extracts a DEM based on the bounding co-ordinates of the input image.
    At this stage assuming the input image is projected in metres and the DEM
    is in geographics. Output will be the extent and co-ordinate system of the
    input file.
    '''

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Extracts the DEM covering the extent of the input file. At this stage assuming the input image is projected in metres and the DEM is in geographics. Output will be the extent and co-ordinate system of the input file.')
 
    parser.add_argument('--DEMfile', required=True, help='The input DEM on which to create the hillshade')
    parser.add_argument('--imgfile', required=True, help='The input image file on which to extract the relevant DEM')
    parser.add_argument('--outfile', required=True, help='The output filename.')
    parser.add_argument('--driver', default='ENVI', help="The file driver type for the output file. See GDAL's list of valid file types. (Defaults to ENVI).")


    parsed_args = parser.parse_args()

    img_ref = osr.SpatialReference()
    dem_ref = osr.SpatialReference()

    ifile = parsed_args.imgfile
    iobj = gdal.Open(ifile, gdal.gdalconst.GA_ReadOnly)
    assert iobj
    
    img_prj  = iobj.GetProjection()
    img_geoT = iobj.GetGeoTransform()
    img_ref.ImportFromWkt(img_prj)
    
    dfile = parsed_args.DEMfile
    dobj = gdal.Open(dfile, gdal.gdalconst.GA_ReadOnly)
    assert dobj

    dem_prj  = dobj.GetProjection()
    dem_geoT = dobj.GetGeoTransform()
    dem_ref.ImportFromWkt(dem_prj)
    dem_cols = dobj.RasterXSize
    dem_rows = dobj.RasterYSize
    band = dobj.GetRasterBand(1)
    dtype = band.DataType

    dims = [iobj.RasterYSize,iobj.RasterXSize]

    box = []
    co_ords = []

    box.append(img2map(geoTransform=img_geoT, pixel=(0,0))) # UL
    box.append(img2map(geoTransform=img_geoT, pixel=(0,dims[1]))) #UR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],dims[1]))) #LR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],0))) # LL

    for corner in box:
        co_ords.append(corner[0])
        co_ords.append(corner[1])

    # Retrieve the image bounding co-ords and create a vector geometry set
    if type(co_ords[0]) == int:
        wkt = 'MULTIPOINT(%d %d, %d %d, %d %d, %d %d)' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])
    else:
        wkt = 'MULTIPOINT(%f %f, %f %f, %f %f, %f %f)' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])

    # Create the vector geometry set and transform the co-ords to match
    # the DEM file
    box_geom = ogr.CreateGeometryFromWkt(wkt)
    tform    = osr.CoordinateTransformation(img_ref, dem_ref)
    box_geom.Transform(tform)

    new_box = []
    for p in range(box_geom.GetGeometryCount()):
        point = box_geom.GetGeometryRef(p)
        new_box.append(point.GetPoint_2D())

    x = []
    y = []
    for c in new_box:
        x.append(c[0])
        y.append(c[1])

    xmin = numpy.min(x)
    xmax = numpy.max(x)
    ymin = numpy.min(y)
    ymax = numpy.max(y)

    # Retrieve the image co_ords of the DEM
    UL = map2img(geoTransform=dem_geoT, location=new_box[0])
    UR = map2img(geoTransform=dem_geoT, location=new_box[1])
    LR = map2img(geoTransform=dem_geoT, location=new_box[2])
    LL = map2img(geoTransform=dem_geoT, location=new_box[3])

    # Compute the offsets in order to read only the portion of the DEM that
    # covers the extents of the image file.
    ix    = numpy.array([UL[1],UR[1],LR[1],LL[1]])
    iy    = numpy.array([UL[0],UR[0],LR[0],LL[0]])
    ixmin = int(numpy.min(ix))
    ixmax = int(numpy.max(ix))
    iymin = int(numpy.min(iy))
    iymax = int(numpy.max(iy))
    xoff  = ixmin
    yoff  = iymin
    xsize = ixmax - ixmin
    ysize = iymax - iymin

    # Need to read in the subset image then create a gdal memory object
    dem_arr = dobj.ReadAsArray(xoff, yoff, xsize, ysize)
    dem_subs_geoT = (xmin,dem_geoT[1],0.0,ymax,0.0,dem_geoT[5])
    memdriver = gdal.GetDriverByName("MEM")
    memdem = memdriver.Create("", dem_arr.shape[1], dem_arr.shape[0], 1, dtype)
    memdem.SetGeoTransform(dem_subs_geoT)
    memdem.SetProjection(dem_prj)
    outband = memdem.GetRasterBand(1)
    outband.WriteArray(dem_arr)

    drv = parsed_args.driver
    driver = gdal.GetDriverByName(drv)

    out_name = parsed_args.outfile

    outds = driver.Create(out_name,  dims[1], dims[0], 1, dtype)
    outds.SetGeoTransform(img_geoT)
    outds.SetProjection(img_prj)

    proj = gdal.ReprojectImage(memdem, outds, None, None, gdal.GRA_Bilinear)

    memdem = None
    outds = None


