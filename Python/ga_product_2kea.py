#!/usr/bin/env python

from os.path import join as pjoin
from os.path import basename, dirname
import rasterio
from rasterio.crs import from_string
from gaip import acquisitions
from gaip import stack_data
from gaip import gridded_geo_box
from eotools.tiling import generate_tiles


def convert(package_name, blocksize=256, compress=1):
    """
    Convets a GA packaged product containing GTiff's and converts
    to a single KEA file format.
    """
    acqs = acquisitions(package_name)
    bands = len(acqs)
    geobox = gridded_geo_box(acqs[0])
    cols, rows = geobox.get_shape_xy()
    crs = from_string(geobox.crs.ExportToProj4())
    dtype = acqs[0].data(window=((0, 1), (0, 1))).dtype.name
    no_data = acqs[0].no_data

    tiles = generate_tiles(cols, rows, blocksize, blocksize)

    fname_fmt = 'compress{}_blocksize{}.kea'.format(compress, blocksize)
    fname = pjoin(basename(dirname(acqs[0].dir_name)), fname_fmt)

    kwargs = {'driver': 'KEA',
              'count': bands,
              'width': cols,
              'height': rows,
              'crs': crs,
              'transform': geobox.affine,
              'dtype': dtype,
              'nodata': no_data,
              'deflate': compress,
              'imageblocksize': blocksize}

    with rasterio.open(fname, 'w', **kwargs) as src:
        for tile in tiles:
            img, _ = stack_data(acqs, window=tile)
            src.write(img, range(1, len(acqs) + 1), window=tile)
