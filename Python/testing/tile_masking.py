#! /usr/bin/env python

'''
Created on 27/08/2012

@author: u08087
'''

import datetime
from osgeo import gdal
from osgeo import ogr
from osgeo import osr

st = datetime.datetime.now()

ifile = r'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\9286\Glen\l5\L5092086_08620080113_B40.TIF'
sfile = r'C:\WINNT\Profiles\u08087\My Documents\GIS\wrs2_descending\wrs2_descending.shp'

driver = ogr.GetDriverByName('ESRI Shapefile')

ds = driver.Open(sfile,0)
lyr = ds.GetLayer()
tile_ref = lyr.GetSpatialRef()

lyr.SetAttributeFilter("PATH = 092 and ROW = 086")

feat = lyr.GetNextFeature()
geom = feat.GetGeometryRef()

iobj = gdal.Open(ifile, gdal.gdalconst.GA_ReadOnly)
img_prj = iobj.GetProjection()
img_ref = osr.SpatialReference()
img_ref.ImportFromWkt(img_prj)
img_geot = iobj.GetGeoTransform()
columns      = iobj.RasterXSize
rows         = iobj.RasterYSize

tform    = osr.CoordinateTransformation(tile_ref, img_ref)
geom.Transform(tform)

pobj = ogr.GetDriverByName('Memory').CreateDataSource('')
layer = pobj.CreateLayer('Tile_Mask',geom_type=lyr.GetGeomType(), srs=img_ref)
feature = ogr.Feature(layer.GetLayerDefn())
feature.SetGeometry(geom)
layer.CreateFeature(feature)

mem_drv = gdal.GetDriverByName('MEM')
outds   = mem_drv.Create("", columns, rows, gdal.GDT_Byte)
outds.SetGeoTransform(img_geot)
outds.SetProjection(img_prj)

burn = gdal.RasterizeLayer(outds, [1], layer, burn_values=[1])

assert (burn == 0)

wt = datetime.datetime.now()
driver   = gdal.GetDriverByName("GTiff")
mask_out = driver.CreateCopy(r'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\9286\Glen\l5\tile_mask.tif', outds)
mask_out = None

et = datetime.datetime.now()
print 'write time taken: ', et - wt
print 'time taken: ', et - st



