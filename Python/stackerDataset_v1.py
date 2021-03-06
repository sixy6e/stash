#!/usr/bin/env python

import os
import datetime
import numpy
from osgeo import gdal
from image_tools import get_tiles
from temporal_stats_numexpr_module import temporal_stats


class stackerDataset:
    """
    A class designed for dealing with datasets returned by stacker.py.
    The reason for only handling data returned by stacker.py are due to 
    specific metadata references such as start_datetime and tile_pathname.
    """

    def __init__(self, file):
        """
        Initialise the class structure.

        :param file:
            A string containing the full filepath of a GDAL compliant dataset created by stacker.py.
        """

        self.ds      = gdal.Open(file)
        self.bands   = self.ds.RasterCount
        self.samples = self.ds.RasterXSize
        self.lines   = self.ds.RasterYSize

        self.setAllBandMetadata()
        self.setBandDatetime()
        self.setTiling(xsize=self.samples)
        self.setYearlyIterator()

    def setAllBandMetadata(self):
        """
        Stores the metadata for every single band into a dictionary.
        Each key in the dictionary is referenced by the band index (starting at 1).
        """

        self.bandMetadata = {}

        for i in range(1, self.bands + 1): # GDAL starts at index 1
            band = self.ds.GetRasterBand(i)
            self.bandMetadata[i] = band.GetMetadata()

    def setBandDatetime(self):
        """
        Stores the datetime object for a given band.
        """

        self.BandDatetimes = {}

        for i in range(1, self.bands + 1): # GDAL starts at index 1
            item     = self.getMetadataItem(band_index=i, item='start_datetime')
            start_dt = datetime.datetime.strptime(item, "%Y-%m-%d %H:%M:%S.%f")
            self.BandDatetimes[i] = start_dt

    def getBandMetadata(self, band_index=1):
        """
        Retrives the metadata for a given band_index. (Default is the first band).

        :param band_index:
            The band index of interest. Default is the first band.

        :return:
            A dictionary containing band level metadata.
        """

        metadata = self.bandMetadata[band_index]

        return metadata

    def getBandDatetime(self, band_index=1):
        """
        Retrieves the datetime for a given band index.

        :param band_index:
            The band index of interest. Default is the first band.

        :return:
            A Python datetime object.
        """

        dt = self.BandDatetimes[band_index]

        return dt

    def getMetadataItem(self, band_index=1, item='tile_pathname'):
        """
        Retrieves a specific metadata item from a given band index.

        :param band_index:
            The band index of interest. Default is the first band.

        :param item:
            A valid key identifier. Default is 'tile_pathname'.

        :return:
            The value corresponding to the metadata item.
        """

        metadata_item = self.bandMetadata[band_index][item]

        return metadata_item

    def setTiling(self, xsize=100, ysize=100):
        """
        Sets the tile indices for a 2D array.

        :param xsize:
            Define the number of samples/columns to be included in a single tile.
            Default is 100

        :param ysize:
            Define the number of lines/rows to be included in a single tile.
            Default is 100.

        :return:
            A list containing a series of tuples defining the individual 2D tiles/chunks to be indexed.
            Each tuple contains (ystart,yend,xstart,xend).
        """

        self.tiles  = get_tiles(self.samples, self.lines, xtile=xsize,ytile=ysize)
        self.nTiles = len(self.tiles)

    def getTile(self, index=0):
        """
        Retrieves a tile given an index.

        :param index:
            An integer containing the location of the tile to be used for array indexing.
            Defaults to the first tile.

        :return:
            A tuple containing the start and end array indices, of the form (ystart,yend,xstart,xend).
        """

        tile = self.tiles[index]

        return tile

    def readTile(self, tile, band_index=1, all_bands=True):
        """
        Read an x & y block specified by tile using GDAL. The default is read all bands.
        To only read a single band set all_bands=False and provide a band_index.

        :param tile:
            A tuple containing the start and end array indices, of the form (ystart,yend,xstart,xend).

        :param band_index:
            If reading from a single band, provide which band index to read from.
            Default is band 1.

        :param all_bands:
            A boolean argument regarding whether or not to read all bands.
            Default is True.
        """

        ystart = int(tile[0])
        yend   = int(tile[1])
        xstart = int(tile[2])
        xend   = int(tile[3])
        xsize  = int(xend - xstart)
        ysize  = int(yend - ystart)

        if all_bands:
            subset = self.ds.ReadAsArray(xstart, ystart, xsize, ysize)
            self.ds.FlushCache()
        else:
            band   = self.ds.GetRasterBand(band_index)
            subset = band.ReadAsArray(xstart, ystart, xsize, ysize)
            band.FlushCache()

        return subset

    def setYearlyIterator(self):
        """
        Creates an interative dictionary containing all the band indices available for each year.
        """

        self.yearlyIterator = {}

        band_list = [1] # Initialise to the first band
        yearOne   = self.getBandDatetime().year

        self.yearlyIterator[yearOne] = band_list

        for i in range(2, self.bands + 1):
            year = self.getBandDatetime(band_index=i).year
            if year == yearOne:
                band_list.append(i)
                self.yearlyIterator[yearOne] = band_list
            else:
                self.yearlyIterator[yearOne] = band_list
                yearOne = year
                band_list = [i]

    def getYearlyIterator(self):
        """
        Returns the yearly iterator dictionary created by setYearlyIterator.
        """

        return self.yearlyIterator

    def readBand(self, band_index=1):
        """
        Read the entire 2D block for a given band index.

        :param band_index:
            The band index of interest. Default is the first band.

        :return:
            A NumPy 2D array of the same dimensions and datatype of the band of interest.
        """

        band  = self.ds.GetRasterBand(band_index)
        array = band.ReadAsArray()
        band.FlushCache()

        return array

