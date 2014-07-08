#!/usr/bin/env python

import argparse
import numpy
from osgeo import gdal
from IDL_functions import histogram

def calculate_triangle_threshold(histogram, xone, ytwo):
    """
    """
    mx_loc = numpy.argmax(histogram)
    mx     = histogram[mx]

    # Find the first and last non-zero elements
    wh = numpy.where(histogram != 0)
    first_non_zero = wh[0][0]
    last_non_zero  = wh[0][-1]

    # Horizontal distance
    if (abs(left_span) > abs(right_span)):
        x_dist = left_span
    else:
        x_dist = right_span

    # Get the distances for the left span and the right span
    left_span  = first_non_zero - mx_loc
    right_span = last_non_zero - mx_loc

    # Get the farthest non-zero point from the histogram peak
    if (abs(left_span) > abs(right_span)):
        non_zero_point = first_non_zero
    else:
        non_zero_point = last_non_zero

    # Vertial distance
    y_dist = h[non_zero_point] - mx

    # Gradient
    m = float(y_dist) / x_dist

    # Intercept
    b = m * (-mx_loc) + mx

    # Get points along the line
    if (abs(left_span) > abs(right_span)):
        x1 = numpy.arange(abs(x_dist) + 1)
    else:
        x1 = numpy.arange(abs(x_dist) + 1) + mx_loc

    y1 = h[x1]
    y2 = m * x1 + b

    # Distances for each point along the line to the histogram
    dists = numpy.sqrt((y2 - y1)^2)

    # Get the location of the maximum distance
    thresh_loc = numpy.argmax(dists)

    # Determine the threshold at the location
    thresh = (ABS(left_span) GT ABS(right_span)) ? thresh_loc : thresh_loc + mx_loc
    if (abs(left_span) > abs(right_span)):
        thresh = thresh_loc
    else:
        thresh = thresh_loc + mx_loc

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
