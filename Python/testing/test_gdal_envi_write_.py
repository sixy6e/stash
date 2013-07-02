#! /usr/bin/env python

import numpy
import gc
from osgeo import gdal
import osr

def write_img(img):
    drv = gdal.GetDriverByName('ENVI')
    outds = drv.Create(outfname, img.shape[2],img.shape[1],img.shape[0],1)
    #geo_trans = (404175.00, 30.0, 0.0, 6157465.00, 0.0, -30.0)
    #outds.SetGeoTransform(geo_trans)
    prj = osr.SpatialReference()
    prj.SetWellKnownGeogCS("WGS84")
    prj.SetUTM(55, False)
    outds.SetProjection(prj.ExportToWkt())
    for i in range(img.shape[0]):
        band = outds.GetRasterBand(i+1)
        band.WriteArray(img[i])
        band.SetNoDataValue(0)
        band.FlushCache()
        band = None


print 'starting'
outfname = 'test_gdal_envi_write'
img = numpy.random.randint(0,256,(19,10,10)).astype('uint8')
#drv = gdal.GetDriverByName('ENVI')
#outds = drv.Create(outfname, img.shape[2],img.shape[1],img.shape[0],1)
#for i in range(img.shape[0]):
#    band = outds.GetRasterBand(i+1)
#    band.WriteArray(img[i])
#    band.SetNoDataValue(0)
#    band.FlushCache()
#    band = None
#
#band = None
#outds = None

write_img(img)

gc.collect()

print 'finished'

