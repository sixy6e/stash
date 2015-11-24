#!/usr/bin/env python

import h5py
import rasterio
from keah5 import kea_init

in_fname = 'LS5_TM_NBAR_151_-033_2008-02-25T23-33-30.404081.dat'
out_fname = 'test2.kea'

ds = rasterio.open(in_fname)
fid = h5py.File(out_fname, 'w')

kea_init(fid, ds.count, ds.shape, ds.affine, ds.crs_wkt, ds.dtypes[0],
         ds.nodata, chunks=None, compression=None)

data_fmt = 'BAND{}/DATA'
for i in range(1, ds.count + 1):
    pth = data_fmt.format(i)
    fid[pth][:] = ds.read(i)

fid.close()
