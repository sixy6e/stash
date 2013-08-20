#!/usr/bin/env python

import os
import sys
import optparse
import pprint
import math

import numpy
import numpy.random

from osgeo import gdal
from osgeo import osr


DTYPE_MAP = {
    gdal.GDT_Int16: numpy.int16,
    gdal.GDT_Int32: numpy.int32,
    gdal.GDT_Float32: numpy.float32,
    gdal.GDT_Float64: numpy.float64,
}


class GeoRef(object):
    """Basic georeference class.
    
    Used to hold origin, range and shape (resolution) and to generate
    affine geotransform array.
    """

    def __init__(self, origin=(0.0, 0.0), range=(10.0, 10.0), shape=(2, 2)):
        """Initialize a GeoRef instance.

        Arguments:
            origin: region origin (usually NW corner)
            range: region size (lon, lat)
            shape: lon, lat subdivisions (resolution)
        """

        self.origin = origin
        self.range = range
        self.shape = shape

    @property
    def geotransform(self):
        """Get affine geotransform array.
         
        Returns:
            geotransform (6-tuple)
        """

        return (
            self.origin[0],
            (self.range[0] - self.origin[0]) / self.shape[0],
            0.0,
            self.origin[1],
            0.0,
            -(self.range[1] - self.origin[1]) / self.shape[1]
        )

    def __str__(self):
        """Creates printable representation of the instance.

        Returns:
            Pretty string.
        """

        return '\n'.join([
                   '<%s object at %#x>' % (self.__class__.__name__, id(self)),
                   '    origin = %s' % str(self.origin), 
                   '    range  = %s' % str(self.range), 
                   '    shape  = %s' % str(self.shape), 
                   '    xform  = %s' % str(self.geotransform), 
               ])



def prep_dir(path):
    """Creates directory components for a given path.

    Arguments:
        path: directory path
    """

    d, f = os.path.split(path)
    if d:
        if os.path.exists(d):
            if not os.path.isdir(d):
                print 'ERROR: bad path (%s)' % d
        else:
            os.makedirs(d)


def new_rband_array(shape=(8,8), value_range=(0,4096), data_type=gdal.GDT_Int16,
                    all_null=False, null_value=9999):
    """
    """

    # numpy data type
    _dtype = DTYPE_MAP[data_type]

    if all_null:
        a = numpy.ones(shape, dtype=_dtype)
        a.fill(null_value)
    else:
        a = numpy.random.random_integers(value_range[0], value_range[1], shape)
        a = numpy.cast[_dtype](a)

    return a


def generate_rpi(path, format='GTiff', nbands=1, shape=(8, 8),
                       geotransform=None, value_range=(0, 10000),
                       data_type=gdal.GDT_Int16):
    """Creates an image containing random pixel values.

    Arguments:
        path: image path
        format: format specifier (GDAL driver type)
        nbands: number of bands
        shape: image dimensions (2-tuple)
        geotransform: geotransform array (6-tuple)
        value_range: range for random pixel values (2-tuple)
        data_type: pixel data type (GDAL type, e.g. gdal.GDT_Int16) 
    """

    prep_dir(path)

    driver = gdal.GetDriverByName(format)
    assert driver

    fd = driver.Create(path, shape[0], shape[1], nbands, data_type)
    assert fd

    # Georeference

    assert geotransform and isinstance(geotransform, (tuple, list))
    fd.SetGeoTransform(geotransform)
    spref = osr.SpatialReference()
    spref.SetWellKnownGeogCS('WGS84')
    fd.SetProjection(spref.ExportToWkt())

    # Pixel data

    for i in xrange(1, nbands + 1):

        # TEST create band 7 containing all nulls

        nulls = (i == 7)
        pixels = new_rband_array(shape, value_range, data_type, all_null=nulls)
        band = fd.GetRasterBand(i)
        band.WriteArray(pixels.transpose())
        del pixels

    del fd
    print 'generate_rpi: created image [%s]' % path


def generate_rpi_block_centre(path, format='GTiff', nbands=1, shape=(8, 8),
                                    geotransform=None, value_range=(0, 10000),
                                    data_type=gdal.GDT_Int16, 
                                    block_radius=1, block_value=9999):
    """Creates an image containing random pixel values.

    Arguments:
        path: image path
        format: format specifier (GDAL driver type)
        nbands: number of bands
        shape: image dimensions (2-tuple)
        geotransform: geotransform array (6-tuple)
        value_range: range for random pixel values (2-tuple)
        data_type: pixel data type (GDAL type, e.g. gdal.GDT_Int16) 
    """

    prep_dir(path)

    driver = gdal.GetDriverByName(format)
    assert driver

    fd = driver.Create(path, shape[0], shape[1], nbands, data_type)
    assert fd

    # Georeference

    assert geotransform and isinstance(geotransform, (tuple, list))
    fd.SetGeoTransform(geotransform)
    spref = osr.SpatialReference()
    spref.SetWellKnownGeogCS('WGS84')
    fd.SetProjection(spref.ExportToWkt())

    # Center "cloud" block indices

    xmid = float(shape[0]) / 2.0
    xmin = int(math.floor(xmid - (block_radius - 1)))
    xmax = int(math.ceil(xmid + (block_radius - 1)))

    ymid = float(shape[1]) / 2.0
    ymin = int(math.floor(ymid - (block_radius - 1)))
    ymax = int(math.ceil(ymid + (block_radius - 1)))

    # Pixel data

    for i in xrange(1, nbands + 1):
        pixels = numpy.random.random_integers(value_range[0],
                                              value_range[1],
                                              shape)
        pixels[xmin:xmax, ymin:ymax] = block_value
        pixels = numpy.cast[dtype_map[data_type]](pixels)
        band = fd.GetRasterBand(i)
        band.WriteArray(pixels.transpose())
        del pixels

    del fd
    print 'generate_rpi_block_centre: created image [%s]' % path






if __name__ == '__main__':

    numpy.random.seed([1010101])

    georef = GeoRef(shape=(16, 16))

    print georef

    generate_rpi(
        'foo.tif', 
        nbands=7,
        shape=georef.shape,
        geotransform=georef.geotransform
    )

    #generate_rpi_block_centre(
    #    'foo2.tif',
    #     shape=georef.shape,
    #     geotransform=georef.geotransform,
    #     block_radius=2
    #)

