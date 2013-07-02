#! /usr/bin/env python

import os
import sys
import argparse
import numpy
from scipy import ndimage
from osgeo import gdal
import ogr
import osr
import pdb

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

def img2map(geoTransform, pixel):
    '''Converts a pixel (image) co-ordinate into a map co-ordinate.

    '''

    mapx = pixel[1] * geoTransform[1] + geoTransform[0]
    mapy = geoTransform[3] - (pixel[0] * (numpy.abs(geoTransform[5])))
    return (mapx,mapy)

def map2img(geoTransform, location):
    '''Converts a map co-ordinate into a pixel (image) co-ordinate.

    '''

    imgx = int(numpy.round((location[0] - geoTransform[0])/geoTransform[1]))
    imgy = int(numpy.round((geoTransform[3] - location[1])/numpy.abs(geoTransform[5])))
    return (imgy,imgx)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Creates a shapefile based on image extents.')

    parser.add_argument('-imgfile', help='The input image on which to derive the extents.')
    parser.add_argument('-outfile', default='image_extent.shp', help='The output filename.  Defaults to image_extent.shp.')

    parsed_args = parser.parse_args()
    file = parsed_args.imgfile

    if os.path.isfile(file):
        iobj = gdal.Open(file, gdal.gdalconst.GA_ReadOnly)
        assert iobj

    box = []
    co_ords = []
    
    img_ref = osr.SpatialReference()
    img_prj  = iobj.GetProjection()
    img_geoT = iobj.GetGeoTransform()
    
    img_ref.ImportFromWkt(img_prj)

    dims = [iobj.RasterYSize,iobj.RasterXSize]

    
    box.append(img2map(geoTransform=img_geoT, pixel=(0,0))) # UL
    box.append(img2map(geoTransform=img_geoT, pixel=(0,dims[1]))) #UR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],dims[1]))) #LR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],0))) # LL
    
    for corner in box:
        co_ords.append(corner[0])
        co_ords.append(corner[1])
    
    
    # Retrieve the image bounding co-ords and create a vector geometry set
    if type(co_ords[0]) == int:
        wkt = 'POLYGON((%d %d, %d %d, %d %d, %d %d))' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])
    else:
        wkt = 'POLYGON((%f %f, %f %f, %f %f, %f %f))' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])
    
    
    # Create the vector file in memory
    #pobj = ogr.GetDriverByName('Memory').CreateDataSource('')
    #layer = pobj.CreateLayer('Mask',geom_type=ogr.wkbPolygon, srs=vproj)
    
    #feature = ogr.Feature(layer.GetLayerDefn())
    #polygon = ogr.CreateGeometryFromWkt(wkt)
    #feature.SetGeometry(polygon)
    #layer.CreateFeature(feature)

    out_name = parsed_args.outfile    

    shp_drv = ogr.GetDriverByName('ESRI Shapefile')
    pobj = shp_drv.CreateDataSource(out_name)
    layer = pobj.CreateLayer('Mask',geom_type=ogr.wkbPolygon, srs=img_ref)
    feature = ogr.Feature(layer.GetLayerDefn())
    polygon = ogr.CreateGeometryFromWkt(wkt)
    feature.SetGeometry(polygon)
    layer.CreateFeature(feature)
    pobj = None
    layer = None
    
    
    #v_out = shp_drv.CopyDataSource(pobj,'Vector_Mask.shp')
    #v_out = None

