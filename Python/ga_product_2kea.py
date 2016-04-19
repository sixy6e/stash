#!/usr/bin/env python

from os.path import join as pjoin
import argparse
from os.path import basename, dirname
import rasterio
from rasterio.crs import from_string
from gaip import acquisitions
from gaip import stack_data
from gaip import gridded_geo_box
from eotools.tiling import generate_tiles


def convert(package_name, blocksize=256, compression=1):
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

    fname_fmt = '{}_compress{}_blocksize{}.kea'
    base_name = basename(dirname(acqs[0].dir_name))
    fname = pjoin(acqs[0].dir_name, fname_fmt.format(base_name, compression,
                                                      blocksize))

    kwargs = {'driver': 'KEA',
              'count': bands,
              'width': cols,
              'height': rows,
              'crs': crs,
              'transform': geobox.affine,
              'dtype': dtype,
              'nodata': no_data,
              'deflate': compression,
              'imageblocksize': blocksize}

    with rasterio.open(fname, 'w', **kwargs) as src:
        for tile in tiles:
            img, _ = stack_data(acqs, window=tile)
            src.write(img, range(1, len(acqs) + 1), window=tile)


if __name__ == '__main__':
    desc = "Converts a packaged scene of GTiffs to KEA format."
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument('--scene', required=True,
                        help='Filepath name of scene.')
    parser.add_argument('--blocksize', required=True, type=int,
                        help='The image blocksize.')
    parser.add_argument('--compression', required=True, type=int,
                        help='The compression value to use (0-9).')

    parsed_args = parser.parse_args()

    convert(parsed_args.scene, parsed_args.blocksize, parsed_args.compression)
