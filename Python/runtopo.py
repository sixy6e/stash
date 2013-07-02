#! /usr/bin/env python

import numpy
from osgeo import gdal

import new_topo_shadow

#ifile = '/short/v10/tmp/temp_stuff/topotest/L5100078_07820100111_B40.TIF'
ifile = '/short/v10/tmp/temp_stuff/topotest/L71091081_08120090609_B40.TIF'
dfile = 'DEM_3sec_mosaic.vrt'
#mfile = '/short/v10/tmp/temp_stuff/L1T/LS5__100_078_20100111/scene01/L5100078_07820100111_MTL.txt'
mfile = '/short/v10/tmp/temp_stuff/topotest/L71091081_08120090609_MTL.txt'

outname = '/short/v10/tmp/temp_stuff/topotest/test_topo_shad_2.tif'

iobj = gdal.Open(ifile, gdal.gdalconst.GA_ReadOnly)
#dobj = gdal.Open(dfile, gdal.gdalconst.GA_ReadOnly)
iprj = iobj.GetProjection()
igeot = iobj.GetGeoTransform()

image = iobj.ReadAsArray()
dims = image.shape

# some ancillary data
lat_file = '/short/v10/tmp/temp_stuff/topotest/LAT.bin'
sat_az_file = '/short/v10/tmp/temp_stuff/topotest/SAT_AZ.bin'
sat_view_file = '/short/v10/tmp/temp_stuff/topotest/SAT_V.bin'
sol_azi_file = '/short/v10/tmp/temp_stuff/topotest/SOL_AZ.bin'
sol_zen_file = '/short/v10/tmp/temp_stuff/topotest/SOL_Z.bin'

lat = numpy.fromfile(lat_file, dtype='float32').reshape(dims)
sensor_azi_angle = numpy.fromfile(sat_az_file, dtype='float32').reshape(dims)
sensor_view_angle = numpy.fromfile(sat_view_file, dtype='float32').reshape(dims)
solar_azi = numpy.fromfile(sol_azi_file, dtype='float32').reshape(dims)
solar_zen = numpy.fromfile(sol_zen_file, dtype='float32').reshape(dims)

#TopographicShadow(image, img_geoT, img_prj, DEM, metafile, lat, sensor_azi_angle, sensor_view_angle, solar_azi, solar_zen, bitpos=14)

topo = new_topo_shadow.TopographicShadow(image, igeot, iprj, dfile, mfile, lat, sensor_azi_angle, sensor_view_angle, solar_azi, solar_zen, bitpos=14)

driver = gdal.GetDriverByName("GTiff")
outds = driver.Create(outname,  dims[1], dims[0], 1, 1)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(topo)
outds = None
'''
driver = gdal.GetDriverByName("ENVI")
outds = driver.Create('lat',  dims[1], dims[0], 1, 6)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(lat)
outds = None
outds = driver.Create('sensor_azi_angle',  dims[1], dims[0], 1, 6)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(sensor_azi_angle)
outds = None
outds = driver.Create('sensor_view_angle',  dims[1], dims[0], 1, 6)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(sensor_view_angle)
outds = None
outds = driver.Create('solar_azi',  dims[1], dims[0], 1, 6)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(solar_azi)
outds = None
outds = driver.Create('solar_zen',  dims[1], dims[0], 1, 6)
outband = outds.GetRasterBand(1)
outds.SetGeoTransform(igeot)
outds.SetProjection(iprj)
outband.WriteArray(solar_zen)
outds = None
'''
