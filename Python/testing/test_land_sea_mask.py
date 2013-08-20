#! /usr/bin/env python

import os
import numpy
import ogr
from osgeo import gdal
import osr

# imgfile and vecfile are full file path names
def land_sea(imgfile=None, vecfile=None):
    
    if not imgfile:
        print 'ERROR: Image File Unspecified'
        return

    if not os.path.exists(imgfile):
        print 'ERROR: File Not Found (%s)' % imgfile
        return
    
    if not vecfile:
        print 'ERROR: Vector File Unspecified'
        return

    if not os.path.exists(vecfile):
        print 'ERROR: File Not Found (%s)' % vecfile
        return
    
    
    iobj = gdal.Open(imgfile, gdal.gdalconst.GA_ReadOnly)
    assert iobj
    vobj = ogr.Open(vecfile)
    assert vobj
    
    # Get image info
    metadata     = iobj.GetMetadata_Dict()
    geoTransform = iobj.GetGeoTransform()
    prj          = iobj.GetProjection()
    spt_ref      = osr.SpatialReference()
    columns      = iobj.RasterXSize
    rows         = iobj.RasterYSize

    # Create a memory raster to rasterize the vector into
    mem_drv = gdal.GetDriverByName('MEM')
    outds   = mem_drv.Create("", columns, rows, gdal.GDT_Byte)
    outds.SetGeoTransform(geoTransform)
    outds.SetProjection(prj)
    
    burn = gdal.RasterizeLayer(outds, [1], vobj.GetLayer(0), burn_values=[1])
    
    if burn != 0:
        raise RuntimeError,  "Error Rasterizing Layer: %s" % burn
        return 'Fail'

    
    return outds




"""
   Only used for testing purposes!!!
   
   The dummy image is created using gdal's memory driver.
   Basically just a blank image.
   Just wanted to see how it works.
   Location is over part of the Coleambally Irrigation Area.
"""    

def dummy_img(samples=1000, lines=900, Driver='MEM'):
    d_img = gdal.GetDriverByName(Driver).Create("", samples, lines, 
                                                gdal.GDT_Byte)
    
    # Give the image starting co-ordinates
    geo_trans = (404175.00, 30.0, 0.0, 6157465.00, 0.0, -30.0) 
    d_img.SetGeoTransform(geo_trans)
    
    # Set the projection
    iproj = osr.SpatialReference()
    iproj.SetWellKnownGeogCS("WGS84")
    iproj.SetUTM(55, False)
    d_img.SetProjection(iproj.ExportToWkt())
    
    # Write the dummy image to file
    tif_drv = gdal.GetDriverByName("GTiff")
    i_out   = out = tif_drv.CreateCopy('Dummy_image.tif', d_img)
    i_out   = None
    
    return d_img




"""
   Only used for testing purposes!!!
   
   The dummy vector is created using ogr's memory driver.
   Just wanted to see how it works.
   One could create the vector using the shapefile driver,
   rather than the method here which creates a vector in-memory, which
   then writes it to a file.
   Location is over part of the Coleambally Irrigation Area.
"""    

def dummy_vec():

    # Create a polygon that exists within and outside the extents of the image
    wkt = 'POLYGON((404175 6157465, 419175 6143965, 404175 6130465, 389175 6143965, 407925 6150715, 404175 6157465))'
    
    # Set the Spatial Reference System
    vproj = osr.SpatialReference()
    vproj.SetWellKnownGeogCS("WGS84")
    vproj.SetUTM(55, False)
    
    # Create the vector file in memory
    pobj = ogr.GetDriverByName('Memory').CreateDataSource('')
    layer = pobj.CreateLayer('Mask',geom_type=ogr.wkbPolygon, srs=vproj)
    
    feature = ogr.Feature(layer.GetLayerDefn())
    polygon = ogr.CreateGeometryFromWkt(wkt)
    feature.SetGeometry(polygon)
    layer.CreateFeature(feature)
    
    shp_drv = ogr.GetDriverByName('ESRI Shapefile')
    v_out = shp_drv.CopyDataSource(pobj,'Vector_Mask.shp')
    v_out = None
    
    return pobj
    
    
    
if __name__ == '__main__':    
    
    image_object  = dummy_img()
    vector_object = dummy_vec()
    
    #land_sea_mask = land_sea(imgfile=image_object, vecfile=vector_object)
    land_sea_mask = land_sea(imgfile='Dummy_image.tif', 
                             vecfile='Vector_Mask.shp')
    
    driver   = gdal.GetDriverByName("GTiff")
    mask_out = driver.CreateCopy('Land_Sea_Mask.tif', land_sea_mask)
    mask_out = None
    
    