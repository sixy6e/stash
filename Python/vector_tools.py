#!/usr/bin/env python

import numpy
from osgeo import gdal
from osgeo import ogr
from osgeo import osr

class vectorDataset:
    """
    A class for accessing data from an OGR supported vector dataset.
    """

    def __init__(self, fname):
        self.vecDS = ogr.Open(fname)
        self.layerCount = self.getLayerCount()
        # The feature count and fields depend on which layer is used
        # It might not be practical to declare it here
        self.featureCount = self.getFeatureCount()
        self.fields = self.getFields()

    def getLayerCount(self):
        """
        
        """
        lyrCount = self.vecDS.GetLayerCount()
        return lyrCount

    def getLayer(self, index=0):
        """
        Retrieves a layer specified by index. Default is index=0 (1st layer).
        """
        #self.layer = self.vecDS.GetLayer(index)
        layer = self.vecDS.GetLayer(index)
        return layer

    def getFields(self):
        """
        Retrieves the attribute field names.
        """
        fields = []
        layer = self.getLayer()
        defn  = layer.GetLayerDefn()
        for i in range(defn.GetFieldCount()):
            name = defn.GetFieldDefn(i).GetName()
            fields.append(name)
        return fields

    def getFeatureCount(self, layer=None):
        """
        
        """
        if not layer:
            layer  = self.getLayer()
        fcount = layer.GetFeatureCount()
        return fcount

    def attributeQuery(self, layer=None, query=None):
        """
        
        """
        if not layer:
            layer  = self.getLayer()
        layer.SetAttributeFilter(query)
        return layer
