#!/usr/bin/env python

import numpy
from osgeo import gdal
from osgeo import ogr
from osgeo import osr

from IDL_functions import histogram
from IDL_functions import array_indices

def createMemoryDataset(name='MemoryDataset', samples, lines, Projection=None, GeoTransform=None, dtype=gdal.GDT_UInt32):
    """
    Creates a GDAL dataset contained entirely in memory (format type = "MEM").

    :param name:
        A string containing the name of the "in-memory" dataset.

    :param samples:
        An integer defining the number of samples for the dataset.

    :param lines:
        An integer defining the number of lines for the dataset.

    :param Projection:
        A WKT string containing the projection used by the dataset.

    :param GeoTransform:
        A tuple containing the GeoTransform used by the dataset.  The tuple is
        if the form ().

    :param dtype:
        An integer representing the GDAL datatype. Default datatype is UInt32
        given as gdal.GDT_UInt32 which is represented by the integer 4.

    :return:
        A GDAL dataset of the format type "Memory".
    """

    # Define the Memory driver
    drv = gdal.GetDriverByName("MEM")

    # Create the dataset
    outds = drv.Create(name, samples, lines, 1, dtype)

    # Set the projection and geotransfrom
    if Projection:
        outds.SetGeoTransform(GeoTransform)
    if GeoTransform:
        outds.SetProjection(Projection)

    return outds

def projectVector(vectorLayer, from_srs, to_srs):
    """
    Projects a layer from one co-ordinate system to another. The transformation
    of each features' geometry occurs in-place.

    :param vectorLayer:
        An OGR layer object.

    :param from_srs:
        An OSR spatial reference object containing the source projection.

    :param to_srs:
        An OSR spatial reference object containing the projection in which to
        transform to.

    :return:
        None. The projection transformation is done in place.
    """

    # Define the transformation
    tform = osr.CoordinateTransformation(from_srs, to_srs)

    # Extract the geometry of every feature and transform it
    # Note: Transformation is done in place!!!
    for feat in vectorLayer:
        geom = feat.GetGeometryRef()
        geom.Transform(tform)

def rasteriseVector(imageDataset, vectorLayer):
    """
    Converts a vector to a raster via a process known as rasterisation.

    The process will rasterise each feature separately via a features FID.
    The stored value in the array corresponds to a features FID + 1, eg an FID
    of 10 will be stored in the raster as 11.

    :param imageDataset:
        A GDAL image dataset.

    :param vectorLayer:
        An OGR layer object.

    :return:
        A GDAL image dataset containing the rasterised features
    """

    # Get the number of features contained in the layer
    nfeatures = layer.GetFeatureCount()

    # Rasterise every feature based on it's FID value +1
    for i in range(nfeatures):
        layer.SetAttributeFilter("FID = %d"%i)
        burn = i + 1
        gdal.RasterizeLayer(imageDataset, [1], vectorLayer, burn_values=[burn])
        layer.SetAttributeFilter(None)

    return imageDataset

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

        self.segemented_array = None

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

        samples = self.RasterInfo["Samples"]
        lines   = self.RasterInfo["Lines"]
        proj    = self.RasterInfo["Projection"]
        geot    = self.RasterInfo["GeoTransform"]

        # Create the memory dataset into which the features will be rasterised
        img_ds = createMemoryDataset(samples=samples, lines=lines, Projection=proj, 
                     GeoTransform=proj)

        # Open the vector dataset and retrieve the first layer
        vec_ds = ogr.Open(self.VectorFname)
        layer  = vec_ds.GetLayer(0)

        if self.SameProjection:
            # Rasterise the vector into image segments/rois
            rasteriseVector(image_dataset=img_ds, vector_layer=layer)
        else:
            # Initialise the image and vector spatial reference
            img_srs = osr.SpatialReference()
            vec_srs = osr.SpatialReference()
            img_srs.ImportFromWKT(proj)
            vec_srs.ImportFromWKT(self.VectorInfo["Projection"])

            # Project the vector
            projectVector(layer, from_srs=vec_srs, to_srs=img_srs)

            # Rasterise the vector into image segments/rois
            rasteriseVector(image_dataset=img_ds, vector_layer=layer)

        # Read the segmented array
        self.segemented_array = img_ds.ReadAsArray()

        # Close the image and vector datasets
        img_ds = None
        vec_ds = None

class SegmentVisitor:
    """
    Given a segmented array, SegmentKeeper will find the segments and optionally
    calculate basic statistics. A value of zero is considered to be the background
    and ignored.
    """

    def __init__(self, array):
        """
        
        """

        self.array   = array
        self.array1D = array.ravel()

        self.dims = array.shape

        self.histogram = None
        self.ri        = None

    def _findSegements(self)
        """
        
        """

        h = histogram(self.array1D, min=1, reverse_indices='ri')

        self.histogram = h['histogram']
        self.ri        = h['ri']

    def getSegementData(self, array, segmentID=0):
        """
        Retrieve the data from an array corresponding to a segmentID.
        """

        ri       = self.ri
        i        = segmentID
        arr_flat = array.ravel()

        if ri[i+1] > ri[i]:
            data = arr_flat[ri[ri[i]:ri[i+1]]]
        else:
            data = numpy.array([])

        return data

    def getSegmentLocations(self, segmentID=0):
        """
        Retrieve the pixel locations corresponding to a segmentID.
        """

        ri = self.ri
        i  = segmentID

        if ri[i+1] > ri[i]:
            idx = ri[ri[i]:ri[i+1]]
        else:
            idx = numpy.array([])

        idx = array_indices(self.dims, idx, dimensions=True)

        return idx

    def segmentMean(self, array):
        """
        Calculates the mean value per segment given an array containing data.
        """

        arr_flat = array.ravel()
        hist     = self.histogram
        ri       = self.ri

        mean_seg = {}

        for i in numpy.arange(hist.shape[0]):
            if (hist[i] == 0):
                continue
            xbar        = numpy.mean(arr_flat[ri[ri[i]:ri[i+1]]])
            mean_seg[i] = xbar

        return mean_seg

     def segmentMax(self, array):
        """
        Calculates the max value per segment given an array containing data.
        """

        arr_flat = array.ravel()
        hist     = self.histogram
        ri       = self.ri

        max_seg = {}

        for i in numpy.arange(hist.shape[0]):
            if (hist[i] == 0):
                continue
            mx_        = numpy.max(arr_flat[ri[ri[i]:ri[i+1]]])
            max_seg[i] = mx_

        return max_seg

     def segmentMin(self, array):
        """
        Calculates the min value per segment given an array containing data.
        """

        arr_flat = array.ravel()
        hist     = self.histogram
        ri       = self.ri

        min_seg = {}

        for i in numpy.arange(hist.shape[0]):
            if (hist[i] == 0):
                continue
            mn_        = numpy.max(arr_flat[ri[ri[i]:ri[i+1]]])
            min_seg[i] = mn_

        return min_seg

