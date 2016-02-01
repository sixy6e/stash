from datacube.api.query import list_tiles_wkt
from datacube.api.model import DatasetType, Satellite
from datetime import date
import fiona
from shapely.geometry import Polygon
import pandas
from eotools.geobox import GriddedGeoBox
import pandas
import rasterio
from rasterio.transform import guard_transform
import numpy
from eotools.bulk_stats import bulk_stats
from eotools.tiling import generate_tiles
from glue import qglue
import h5py
import sys
sys.path.append('/home/547/jps547/git_repositories/agdc-science/fc-mpi-example')
from keah5 import kea_init_variable


vfname = 'p90r84-85.shp'
src = fiona.open(vfname)
feat = src[0]
geom = feat['geometry']
poly = Polygon(geom['coordinates'][0])

dataset_types = [DatasetType.ARG25]
years = [2008]
satellites = [Satellite(i) for i in ['LS5']]
tiles = list_tiles_wkt(poly.wkt, satellites=satellites, years=years, datasets=dataset_types)

ulx = []
uly = []
dim_x = []
dim_y = []
time_stamps = []
fnames = []
lrx = []
lry = []

for tile in tiles:
    nbar_ds = tile.datasets[DatasetType.ARG25]
    with rasterio.open(nbar_ds.path) as ds:
        geobox = GriddedGeoBox.from_rio_dataset(ds)
    x, y = geobox.ul
    lr_x, lr_y = geobox.lr
    cols, rows = geobox.get_shape_xy()
    dim_x.append(cols)
    dim_y.append(rows)
    ulx.append(x)
    uly.append(y)
    time_stamps.append(tile.start_datetime)
    fnames.append(nbar_ds.path)
    lrx.append(lr_x)
    lry.append(lr_y)

df = pandas.DataFrame({'timestamp': time_stamps,
                       'cols': dim_x,
                       'rows': dim_y,
                       'ulx': ulx,
                       'uly': uly,
                       'filename': fnames,
                       'lrx': lrx,
                       'lry': lry}, index=range(len(ulx)))

min_x = df.ulx.min()
max_x = df.lrx.max()
min_y = df.lry.min()
max_y = df.uly.max()

# pixel resolution
res_x = geobox.affine[0]
res_y = geobox.affine[4]

# form the affine for the new image
new_aff = guard_transform([min_x, res_x, 0, max_y, 0, res_y])

# get the LR in pixel co-ordinates
lr_x, lr_y = (max_x, min_y) * ~new_aff
cols = int(lr_x)
rows = int(lr_y)

# create a time/band index for the new time series mosaic image
t_df = df['timestamp'].unique()
t_index_df = pandas.DataFrame({'timestamp': t_df,
                               'band_index': numpy.arange(t_df.shape[0])})
n_bands = t_index_df.shape[0]

# join with the original dataframe
new_df = pandas.merge(df, t_index_df, on='timestamp')

# lets create a mosaic of ndvi through time
band_num = 4
with rasterio.open(nbar_ds.path) as ds:
    dtype = ds.dtypes[0]
dims = (int(n_bands), int(rows), int(cols))
ndvi = numpy.zeros(dims, dtype=dtype)
#ndvi.fill(-999) Memory hungry
windows = generate_tiles(dims[2], dims[1], 2000, 2000, False)
for window in windows:
    ys, ye = window[0]
    xs, xe = window[1]
    ndvi[:, ys:ye, xs:xe] -= 999


for row in new_df.iterrows():
    rdata = row[1]
    fname = rdata['filename']
    bidx = rdata['band_index']
    with rasterio.open(fname, 'r') as ds:
        # find the location of the image we're reading within the larger image
        ulx, uly = (0, 0) * ds.affine
        # compute the offset
        xoff, yoff = (ulx, uly) * ~new_aff
        xend = xoff + ds.shape[1]
        yend = yoff + ds.shape[0]
        # read into the pre-allocated image
        data = (ds.read([3,4])).astype('float32')
        data[data == -999] = numpy.nan
        res = ((data[1] - data[0]) / (data[1] + data[0])) *10000
        res[~numpy.isfinite(res)] = -999
        ndvi[bidx, yoff:yend, xoff:xend] = res


ds = rasterio.open(fname)

# output the ndvi timeseries
n_bands = ndvi.shape[0]
out_dims = (ndvi.shape[1], ndvi.shape[2])
fid = h5py.File('ndvi_mosaic.kea', 'w')
kea_init_variable(fid, n_bands, out_dims, new_aff, ds.crs_wkt, ndvi.dtype.name, compression=4, no_data=-999)
windows = generate_tiles(dims[2], dims[1], 256, 256, False)
dset_fmt = 'BAND{}/DATA'
for i in range(ndvi.shape[0]):
    dname = dset_fmt.format(i+1)
    for window in windows:
        ys, ye = window[0]
        xs, xe = window[1]
        fid[dname][ys:ye, xs:xe] = ndvi[i, ys:ye, xs:xe]

fid.close()


# compute something intersting???
# should use roughly 500mb with this block size
windows = generate_tiles(dims[2], dims[1], 1000, 1000, False)
result = numpy.zeros((14, dims[1], dims[2]), dtype='float32')
for window in windows:
    ys, ye = window[0]
    xs, xe = window[1]
    data = ndvi[:, ys:ye, xs:xe]
    result[:, ys:ye, xs:xe] = bulk_stats(data, no_data=-999)


# define the output stats file
out_nbands = result.shape[0]
out_dims = (result.shape[1], result.shape[2])
out_dtype = result.dtype.name
bnames = ['Sum',
          'Mean',
          'Valid Observations',
          'Variance',
          'Standard Deviation',
          'Skewness',
          'Kurtosis',
          'Max',
          'Min',
          'Median (non-interpolated value)',
          'Median Index (zero based index)',
          '1st Quantile (non-interpolated value)',
          '3rd Quantile (non-interpolated value)',
          'Geometric Mean']

fid = h5py.File('stats_mosaic.kea', 'w')
kea_init_variable(fid, out_nbands, out_dims, origin_aff, ds.crs_wkt,
                  out_dtype, compression=4, band_names=bnames,
                  no_data=numpy.nan)

# default KEA chunksize is (256, 256)
windows = generate_tiles(dims[2], dims[1], 256, 256, False)
dset_fmt = 'BAND{}/DATA'
for i in range(out_nbands):
    dname = dset_fmt.format(i+1)
    for window in windows:
        ys, ye = window[0]
        xs, xe = window[1]
        fid[dname][ys:ye, xs:xe] = result[i, ys:ye, xs:xe]

fid.close()


# prep data for glue
result = result[:, ::-1, :]
data = {}
for i, bname in enumerate(bnames):
    data[bname] = result[i]

qglue(data=data)


# For when we have already created the file
fid = h5py.File('ndvi_mosaic.kea', 'r')
dsets = {}
hdr = fid['HEADER']
rows, cols = [int(res) for res in hdr['SIZE'][:]]
nbands = hdr['NUMBANDS'][:][0]
windows = generate_tiles(cols, rows, 2000, 2000, False)
result = numpy.zeros((14, rows, cols), dtype='float32')
dset_fmt = 'BAND{}/DATA'
for i in range(nbands):
    bnum = i+1
    dname = dset_fmt.format(bnum)
    dsets[bnum] = fid[dname]

for window in windows:
    ys, ye = window[0]
    xs, xe = window[1]
    ysize = ye - ys
    xsize = xe - xs
    data = numpy.zeros((nbands, ysize, xsize), dtype='float32')
    for i in range(nbands):
        bnum = i + 1
        data[i] = dsets[bnum][ys:ye, xs:xe]
    result[:, ys:ye, xs:xe] = bulk_stats(data, no_data=-999)


# define the output stats file
out_nbands = result.shape[0]
out_dims = (result.shape[1], result.shape[2])
out_dtype = result.dtype.name
bnames = ['Sum',
          'Mean',
          'Valid Observations',
          'Variance',
          'Standard Deviation',
          'Skewness',
          'Kurtosis',
          'Max',
          'Min',
          'Median (non-interpolated value)',
          'Median Index (zero based index)',
          '1st Quantile (non-interpolated value)',
          '3rd Quantile (non-interpolated value)',
          'Geometric Mean']

wkt = hdr['WKT'][:]
out_dims = (result.shape[1], result.shape[2])
out_dtype = result.dtype.name
xres, yres = hdr['RES'][:]
ulx, uly = hdr['TL'][:]
origin_aff = guard_transform([ulx, xres, 0, uly, 0, yres])
fid2 = h5py.File('stats_mosaic.kea', 'w')
kea_init_variable(fid2, out_nbands, out_dims, origin_aff, wkt, out_dtype, compression=4, band_names=bnames, no_data=numpy.nan)

# default KEA chunksize is (256, 256)
windows = generate_tiles(out_dims[0], out_dims[1], 256, 256, False)
dset_fmt = 'BAND{}/DATA'
for i in range(out_nbands):
    dname = dset_fmt.format(i+1)
    for window in windows:
        ys, ye = window[0]
        xs, xe = window[1]
        fid2[dname][ys:ye, xs:xe] = result[i, ys:ye, xs:xe]

fid2.close()

