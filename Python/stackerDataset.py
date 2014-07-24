#!/usr/bin/env python

import os
import datetime
import numpy
from osgeo import gdal
from image_tools import get_tiles
from temporal_stats_numexpr_module import temporal_stats


class StackerDataset:
    """
    A class designed for dealing with datasets returned by stacker.py.
    The reason for only handling data returned by stacker.py are due to 
    specific metadata references such as start_datetime and tile_pathname.

    File access to the image dataset is acquired upon request, for example
    when reading the image data.  Once the request has been made the file
    is closed.

    Example:

        >>> fname = 'FC_144_-035_BS.vrt'
        >>> ds = StackerDataset(fname)
        >>> # Get the number of bands associated with the dataset
        >>> ds.bands
        22
        >>> # Get the number of samples associated with the dataset
        >>> ds.samples
        4000
        >>> # Get the number of lines associated with the dataset
        >>> ds.lines
        4000
        >>> # Initialise the yearly iterator
        >>> ds.initYearlyIterator()
        >>> # Get the yearly iterator dictionary
        >>> ds.getYearlyIterator()
        {1995: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            1996: [16, 17, 18, 19, 20, 21, 22]}
        >>> # Get the datetime of the first raster band
        >>> ds.getRasterBandDatetime()
        datetime.datetime(1995, 7, 2, 23, 19, 48, 452050)
        >>> # Get the metadata of the first raster band
        >>> ds.getRasterBandMetadata()
        {'start_datetime': '1995-07-02 23:19:48.452050', 'sensor_name': 'TM',
         'start_row': '83', 'end_row': '83', 'band_name': 'Bare Soil',
         'satellite_tag': 'LS5', 'cloud_cover': 'None', 'tile_layer': '3',
         'end_datetime': '1995-07-02 23:20:12.452050',
         'tile_pathname':
         '/g/data1/rs0/tiles/EPSG4326_1deg_0.00025pixel/LS5_TM/144_-035/1995/
          LS5_TM_FC_144_-035_1995-07-02T23-19-48.452050.tif',
         'gcp_count': '52', 'band_tag': 'BS', 'path': '94', 'level_name': 'FC',
         'y_index': '-35', 'x_index': '144', 'nodata_value': '-999'}
        >>> # Initialise the x & y block tiling sequence, using a block size
        >>> # of 400x by 400y
        >>> ds.initTiling(400,400)
        >>> # Number of tiles
        >>> ds.nTiles
        100
        >>> # Get the 11th tile (zero based index)
        >>> ds.getTile(10)
        (400, 800, 0, 400)
        >>> # Read a single raster band. The 10th raster band (one based index)
        >>> img = ds.readRasterBand(10)
        >>> img.shape
        (4000, 4000)
        >>> # Read only a tile of a single raster band
        >>> # First tile, 10th raster band
        >>> img = ds.readTile(ds.getTile(0), 10)
        >>> img.shape
        (400, 400)
        >>> # Read all raster bands for the 24th tile
        >>> img = ds.readTileAllRasters(ds.getTile(23))
        >>> img.shape
        (22, 400, 400)
    """

    def __init__(self, filename):
        """
        Initialise the class structure.

        :param file:
            A string containing the full filepath of a GDAL compliant dataset created by stacker.py.
        """

        self.fname = filename

        # Open the dataset
        ds = gdal.Open(filename)

        self.bands   = ds.RasterCount
        self.samples = ds.RasterXSize
        self.lines   = ds.RasterYSize

        # Initialise the tile variables
        self.tiles  = [None]
        self.nTiles = 0

        # Close the dataset
        ds = None

    def getRasterBandMetadata(self, raster_band=1):
        """
        Retrives the metadata for a given band_index. (Default is the first band).

        :param raster_band:
            The band index of interest. Default is the first band.

        :return:
            A dictionary containing band level metadata.
        """

        # Open the dataset
        ds = gdal.Open(self.fname)

        # Retrieve the band of interest
        band = ds.GetRasterBand(raster_band)

        # Retrieve the metadata
        metadata = band.GetMetadata()

        # Close the dataset
        ds = None

        return metadata

    def getRasterBandDatetime(self, raster_band=1):
        """
        Retrieves the datetime for a given raster band index.

        :param raster_band:
            The raster band interest. Default is the first raster band.

        :return:
            A Python datetime object.
        """

        metadata = self.getRasterBandMetadata(raster_band)
        dt_item  = metadata['start_datetime']
        start_dt = datetime.datetime.strptime(dt_item, "%Y-%m-%d %H:%M:%S.%f")

        return start_dt

    def initYearlyIterator(self):
        """
        Creates an interative dictionary containing all the band indices available for each year.
        """

        self.yearlyIterator = {}

        band_list = [1] # Initialise to the first band
        yearOne   = self.getRasterBandDatetime().year

        self.yearlyIterator[yearOne] = band_list

        for i in range(2, self.bands + 1):
            year = self.getRasterBandDatetime(raster_band=i).year
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

    def initTiling(self, xsize=100, ysize=100):
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

    def readTile(self, tile, raster_band=1):
        """
        Read an x & y block specified by tile for a given raster band using GDAL.

        :param tile:
            A tuple containing the start and end array indices, of the form
            (ystart,yend,xstart,xend).

        :param raster_band:
            If reading from a single band, provide which raster band to read from.
            Default is raster band 1.
        """

        ystart = int(tile[0])
        yend   = int(tile[1])
        xstart = int(tile[2])
        xend   = int(tile[3])
        xsize  = int(xend - xstart)
        ysize  = int(yend - ystart)

        # Open the dataset.
        ds = gdal.Open(self.fname)

        band = ds.GetRasterBand(raster_band)

        # Read the block and flush the cache (potentianl GDAL memory leak)
        subset = band.ReadAsArray(xstart, ystart, xsize, ysize)
        band.FlushCache()

        # Close the dataset
        ds = None

        return subset

    def readTileAllRasters(self, tile):
        """
        Read an x & y block specified by tile from all raster bands
        using GDAL.

        :param tile:
            A tuple containing the start and end array indices, of the form
            (ystart,yend,xstart,xend).
        """

        ystart = int(tile[0])
        yend   = int(tile[1])
        xstart = int(tile[2])
        xend   = int(tile[3])
        xsize  = int(xend - xstart)
        ysize  = int(yend - ystart)

        # Open the dataset.
        ds = gdal.Open(self.fname)

        # Read the array and flush the cache (potentianl GDAL memory leak)
        subset = ds.ReadAsArray(xstart, ystart, xsize, ysize)
        ds.FlushCache()

        # Close the dataset
        ds = None

        return subset

    def readRasterBand(self, raster_band=1):
        """
        Read the entire 2D block for a given raster band.
        By default the first raster band is read into memory.

        :param raster_band:
            The band index of interest. Default is the first band.

        :return:
            A NumPy 2D array of the same dimensions and datatype of the band of interest.
        """

        # Open the dataset.
        ds = gdal.Open(self.fname)

        band  = ds.GetRasterBand(raster_band)
        array = band.ReadAsArray()

        # Flush the cache to prevent leakage
        band.FlushCache()

        # Close the dataset
        ds = None

        return array

