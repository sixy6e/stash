#!/usr/bin/env python

import numpy
import matplotlib.pyplot as plt
import matplotlib.colors as col
import matplotlib.cm as cm
from osgeo import gdal

def get_class_colours(band, alpha=False, normal=False):
    """
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

    if alpha:
        # Do nothing
    else:
        class_colours = class_colours[*,0:3] # Alpha channel is last column

    if normal:
        class_colours = class_colours / 255.0

    return class_colours

def create_colour_table(colours, name='', n=None):
    """
    """

    cmap = col.ListedColormap(colours, name=name, N=n)
    cm.register_cmap(cmap=cmap)

