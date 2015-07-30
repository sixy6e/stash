import timeit
import rasterio
import h5py
import netCDF4
from datetime import datetime as dt

fname = 'LS5_TM_NBAR_150_-034_2006-02-10T23-40-32.372000.tif'

hgz_outfname = 'tm_test_gzip.h5'
hlz_outfname = 'tm_test_lzf.h5'
ngz_outfname = 'tm_test_gzip.nc'

with rasterio.open(fname, 'r') as ds:
    img = ds.read(masked=False)
dims = img.shape

def write_gziph5():
    st = dt.now()
    f = h5py.File(hgz_outfname, 'w')
    dset = f.create_dataset('nbar', data=img, compression='gzip', chunks=(6, 128, 128))
    et = dt.now()
    print "h5-gzip time taken: {}".format(et - st)

def write_lzfh5():
    st = dt.now()
    f = h5py.File(hlz_outfname, 'w')
    dset = f.create_dataset('nbar', data=img, compression='lzf', chunks=(6, 128, 128))
    et = dt.now()
    print "h5-lzf time taken: {}".format(et - st)

def write_gzipnc():
    st = dt.now()
    f = netCDF4.Dataset(ngz_outfname, 'w', format='NETCDF4')
    f.createDimension('z', (dims[0]))
    f.createDimension('y', (dims[1]))
    f.createDimension('x', (dims[2]))
    dset = f.createVariable('nbar', 'i2', ('z', 'y', 'x'), zlib=True)
    dset[:] = img
    et = dt.now()
    print "nc-gzip time taken: {}".format(et - st)

#print "h5-gzip time taken: {}".format(timeit.timeit(write_gziph5), number=1, repeat=1)
#print "h5-lzf time taken: {}".format(timeit.timeit(write_lzfh5), number=1, repeat=1)
#print "nc-gzip time taken: {}".format(timeit.timeit(write_gzipnc), number=1, repeat=1)
write_lzfh5()
write_gziph5()
write_gzipnc()
