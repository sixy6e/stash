#!/usr/bin/env python

import gdal


GDAL2KEADTYPE = {gdal.GDT_Unknown: 0,
                 gdal.GDT_Int16: 2,
                 gdal.GDT_Int32: 3,
                 gdal.GDT_Byte: 5,
                 gdal.GDT_UInt16: 6,
                 gdal.GDT_UInt32: 7,
                 gdal.GDT_Float32: 9,
                 gdal.GDT_Float64: 10}

# kea undefined is 0; not sure what the mapping to numpy is
NUMPY2KEADTYPE = {'int8': 1,
                  'int16': 2,
                  'int32': 3,
                  'int64': 4,
                  'uint8': 5,
                  'uin16': 6,
                  'uint32': 7,
                  'uint64': 8,
                  'float32': 9,
                  'float64': 10}

LAYERTYPE = {'contiuous': 0,
             'thematic': 1}

# TODO
LAYERUSAGE = {}


def kea_init(fid, nbands, shape, affine, crs_wkt, dtype, no_data=None,
             chunks=(256, 256), compression=1, blocksize=256):
    bnames = ['BAND{}'.format(i+1) for i in range(nbands)]

    res = (affine[0], affine[4])
    ul = (affine[2], affine[5])
    rot = (affine[1], affine[3])

    # gdal or numpy number dtype value
    kea_dtype = NUMPY2KEADTYPE[dtype]

    # create band level groups
    band_groups = {}
    for bname in bnames:
        band_groups[bname] = fid.create_group(bname)
        band_groups[bname].create_group('METADATA')
        band_groups[bname].create_group('OVERVIEWS')
        band_groups[bname].create_dataset('DATA', shape=shape, dtype=dtype,
                                          compression=compression,
                                          chunks=chunks)
        band_groups[bname]['DATA'].attrs['CLASS'] = 'IMAGE'
        band_groups[bname]['DATA'].attrs['IMAGE_VERSION'] = '1.2'
        band_groups[bname]['DATA'].attrs['BLOCK_SIZE'] = blocksize
        band_groups[bname].create_dataset('DATATYPE', shape=(1,),
                                          data=kea_dtype, dtype='uint16')
        band_groups[bname].create_dataset('DESCRIPTION', shape=(1,), data='')
        band_groups[bname].create_dataset('LAYER_TYPE', shape=(1,), data=0)
        band_groups[bname].create_dataset('LAYER_USAGE', shape=(1,), data=0)
        band_groups[bname].create_group('ATT/DATA')
        band_groups[bname].create_group('ATT/NEIGHBOURS')
        band_groups[bname].create_dataset('ATT/HEADER/CHUNKSIZE', data=0,
                                          dtype='uint64')
        band_groups[bname].create_dataset('ATT/HEADER/SIZE', data=[0,0,0,0,0],
                                          dtype='uint64')
        if no_data is not None:
            band_groups[bname].create_dataset('NO_DATA_VAL', shape=(1,),
                                              data=no_data)


    fid.create_group('GCPS')
    fid.create_group('METADATA')
    hdr = fid.create_group('HEADER')

    # header dsets
    hdr.create_dataset('WKT', shape=(1,), data=crs_wkt)
    hdr.create_dataset('SIZE', data=shape, dtype='uint64')
    hdr.create_dataset('VERSION', shape=(1,), data='1.1')
    hdr.create_dataset('RES', data=res, dtype='float64')
    hdr.create_dataset('TL', data=ul, dtype='float64')
    hdr.create_dataset('ROT', data=rot, dtype='float64')
    hdr.create_dataset('NUMBANDS', shape=(1,), data=nbands, dtype='uint16')
    hdr.create_dataset('FILETYPE', shape=(1,), data='KEA')
    hdr.create_dataset('GENERATOR', shape=(1,), data='h5py')
