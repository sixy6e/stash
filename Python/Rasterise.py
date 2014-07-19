#!/usr/bin/env python

import numpy
from osgeo import gdal
from osgeo import ogr
from osgeo import osr

from IDL_functions import histogram
from IDL_functions import array_indices

def createMemoryDataset(name='Rasterised', samples, lines, Projection=None, GeoTransform=None):
    """
    
    """

    drv = gdal.GetDriverByName("MEM")

    outds = drv.Create(name, samples, lines, 1, gdal.GDT_UInt32)

    if Projection:
        outds.SetGeoTransform(GeoTransform)
    if GeoTransform:
        outds.SetProjection(Projection)

    return outds

def projectVector(from_srs, to_srs):
"""

"""

    tform = osr.CoordinateTransformation(from_srs, to_srs)
    geom.Transform(tform)

class Rasterise:
    """
    
    """

    def __init__(self, RasterFname, VectorFname):
        """
        
        """

        self.RasterFname = RasterFname
        self.VectorFname = VectorFname

        self.RasterInfo = {}
        self.VectorInfo = {}

        self._readRasterInfo()
        self._readVectorInfo()

        self.SameProjection = self.compareProjections(self.RasterInfo["Projection"], self.VectorInfo["Projection"])

    def _readRasterInfo(self):
        """
        
        """

        # Open the file
        ds = gdal.Open(self.RasterFname)

        samples = ds.RasterXSize
        lines   = ds.RasterYsize
        bands   = ds.RasterCount
        proj    = ds.GetProjection()
        geot    = ds.GetGeoTransform()

        self.RasterInfo["Samples"]      = samples
        self.RasterInfo["Lines"]        = lines
        self.RasterInfo["Bands"]        = bands
        self.RasterInfo["Projection"]   = proj
        self.RasterInfo["GeoTransform"] = geot

        # Close the dataset
        ds = None

    def _readVectorInfo(self):
        """
        
        """

        # Open the file
        vec_ds = ogr.Open(self.VectorFname)

        lyr_cnt  = vec_ds.GetLayerCount()
        layer    = vec_ds.GetLayer()
        feat_cnt = layer.GetFeatureCount()
        proj     = layer.GetSpatialRef().ExportToWkt()

        self.VectorInfo["LayerCount"]   = lyr_cnt
        self.VectorInfo["FeatureCount"] = feat_cnt
        self.VectorInfo["Projection"]   = proj

        # Close the file
        vec_ds = None

    def compareProjections(proj1, proj2):
        """
        
        """

        srs1 = osr.SpatialReference()
        srs2 = osr.SpatialReference()

        srs1.ImportFromWKT()
        srs2.ImportFromWKT()

        result = bool(srs1.IsSame(srs2))

        return result

    def _project():
        """
        
        """

    def _rasterise():
        """
        
        """
