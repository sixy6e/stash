#!/usr/bin/env python

import argparse
import numpy
from osgeo import gdal
from IDL_functions import histogram

def calculate_triangle_threshold(histogram, xone, ytwo):
    """
    """

    return thresh

def triangle_threshold_mask():
    """
    """

    return tr_mask

def input_output_main():
    """
    A function to handle the input and ouput of image files.  GDAL is used for reading and writing files to and from the disk.
    This function also acts as main when called from the command line.
    """

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Creates a binary mask from an image using the Triangle threshold method. The threshold is calculated as the point of maximum perpendicular distance of a line between the histogram peak and the farthest non-zero histogram edge to the histogram.')

    input_output_main()
