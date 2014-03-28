#!/usr/bin/env python

import os
import argparse
import numpy
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from osgeo import gdal
from ULA3.dataset import SceneDataset
from IDL_functions import histogram

def read_text_file(text_file=''):
    """
    Read text file into a list.
    Removes leading and trailing blanks and new line feeds.
    """
    if os.path.exists(text_file):
        f_open = open(text_file)
        f_read = f_open.readlines()
        f_open.close()
        f_strip = [i.strip() for i in f_read]
        return f_strip
    else:
        raise Exception('Error. No file with that name exists! filename: %s' %text_file)

def plotHistogram(fname, out_dir):
    """
    """

    ds = SceneDataset(fname)

    # Retrieve and create the output base directory
    base_dir = os.path.basename(fname)
    out_dir = os.path.join(out_dir, base_dir)

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    bands = []
    for i in ds._bands['REFLECTIVE']:
        bands.append(i)
    for j in ds._bands['THERMAL']:
        bands.append(j)
    for k in ds._bands['ATMOSPHERE']:
        bands.append(k)

    pdf_name  = os.path.join(out_dir,'histogram_plots.pdf')
    plot_file = PdfPages(pdf_name)

    mx_DN_list = []
    hist_list  = []
    lab_list   = []
    for band in bands:
        b   = ds.GetRasterBand(band)
        img = b.ReadAsArray()
        h = histogram(img.ravel(), max=65535)
        hist = h['histogram']
        hist[0] = 0 # Ignore the no-data value
        if band != 9:
            hist_list.append(hist.copy())
        wh = numpy.where(hist != 0)
        mx = numpy.max(wh)
        mx_DN_list.append('Band: %i, Max DN: %i, Count: %i\n' %(band, mx, hist[mx]))
        # for plotting
        lab = 'Band %i'%band
        lab_list.append(lab)
        plt.plot(hist, label=lab)
        plt.legend()
        plt.suptitle(base_dir)
        plot_file.savefig()
        plt.close()

    # Now to output a single plot containing all (except band 9) histograms
    for i in range(len(hist_list)):
        plt.plot(hist_list[i], label=lab_list[i])

    plt.legend()
    plt.suptitle(base_dir)
    plot_file.savefig()
    plot_file.close()

    plt.close()

    out_file = open(os.path.join(out_dir, 'histogram_results.txt'), 'w')
    for line in mx_DN_list:
        out_file.write(line)

    out_file.close()

def findSaturation(fname, out_dir):
    """
    """

    ds = SceneDataset(fname)
    cols = ds.RasterXSize
    rows = ds.RasterYSize

    drv = gdal.GetDriverByName("ENVI")

    bands = []
    for i in ds._bands['REFLECTIVE']:
        bands.append(i)
    for j in ds._bands['THERMAL']:
        bands.append(j)
    for k in ds._bands['ATMOSPHERE']:
        bands.append(k)

    count_list = []
    for band in bands:
        b   = ds.GetRasterBand(band)
        img = b.ReadAsArray()
        sat = (img == 1) | (img == 65535)

        count = sat.sum()

        count_list.append('Band %i: %i\n' %(band, count))

        out_fname = os.path.join(fname, 'saturation_%i'%band)
        outds = drv.Create(out_fname, cols, rows, 1, 1)
        outds.SetProjection(ds.GetProjection())
        outds.SetGeoTransform(ds.GetGeoTransform())

        outband = outds.GetRasterBand(1)
        outband.WriteArray(sat)
        outds = None

        b  = None

    base_dir = os.path.basename(fname)
    out_dir = os.path.join(out_dir, base_dir)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    saturation_file = open(os.path.join(out_dir, 'saturation_counts.txt'), 'w')
    for line in count_list:
        saturation_file.write(line)

    saturation_file.close()

def main(file_list, out_dir, Hist=None):
    """
    """

    scene_list = read_text_file(text_file=file_list)

    for scene in scene_list:
        print 'Processing scene: %s' %scene
        if Hist:
            plotHistogram(fname=scene, out_dir=out_dir)
        else:
            findSaturation(fname=scene, out_dir=out_dir)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Takes an input file list containing scenes to process through a saturation analysis.')

    parser.add_argument('--scene_list', required=True, help='Text file containing the list of scenes to process.')
    parser.add_argument('--out_dir', required=True, help='The output directory.')
    parser.add_argument('--histogram', action='store_true', help='Will undertake histogram analysis to find the max DN value and the count.')

    parsed_args = parser.parse_args()

    scene_list = parsed_args.scene_list
    out_dir    = parsed_args.out_dir
    hist       = parsed_args.histogram

    main(file_list=scene_list, out_dir=out_dir, Hist=hist)
