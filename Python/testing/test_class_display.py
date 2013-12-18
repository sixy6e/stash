#!/usr/bin/env python

import numpy
import matplotlib.pyplot as plt
import matplotlib.colors as col
import matplotlib.cm as cm
from osgeo import gdal

def get_class_colours(band, alpha=False, normal=False):
    """
    Creates a numpy array containing the class colours used for a classified image. If normalised will return RGB as 0 -> 1, otherwise it is 0 -> 255.

    :param band:
        A GDAL band object.

    :param alpha:
        A boolean option as to whether to return the class colours including the alpha channel. Default is False.

    :param normal:
        A boolean option as to whether to return the normalised class colours (colours / 255.0). Default is False.

    :return:
        A numpy array of shape [n,4] if alpha=True, or [n,3] if alpha=False (Default). If normal=True then array is of type float, else array is of type uint8 (Default).
    :author:
        Josh Sixsmith; josh.sixsmith@gmail.com

    :history:
        * 18/12/2013: Created
    """

    ct            = band.GetColorTable()
    n_classes     = ct.GetCount()
    class_colours = []

    for i in range(n_classes):
        class_colours.append(ct.GetColorEntry(i))

    # Convert to a numpy array with dimensions [n,4]
    class_colours = numpy.array(class_colours, dtype='uint8') # RGB values are only 0 -> 255

    if ~alpha:
        class_colours = class_colours[*,0:3] # Retreive only RGB parts.

    if normal:
        class_colours = class_colours / 255.0

    return class_colours

def create_colour_map(colours, name='Custom_Class_Colours', n=None, register=False):
    """
    Creates a colour map for use with matplotlib.

    :param colours:
        An [n,4] or [n,3] numpy array containing the colours desired for display.

    :param name:
        A string containing the name to be used for referencing the colour table. Default it 'Custom_Class_Colours'.

    :param n:
        The number of colour. If unset then n colours from colours array will be used.

    :param register:
        If set to True then the colour table is registered with cm (colormap) and can be retrieved via the get_cmap() method. Default is False.

    :return:
        A colour map object that can be used with matplotlib.

    :author:
        Josh Sixsmith; josh.sixsmith@gmail.com

    :history:
        * 18/12/2013: Created
    """

    cmap = col.ListedColormap(colours, name=name, N=n)

    if register:
        cm.register_cmap(cmap=cmap)

    return cmap

