#! /usr/bin/env python
import sys
import argparse

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Calculates Fractional Cover.')
    parser.add_argument('--indir', required=True, help='The full file system path to the directory containing the tif images.')
    parser.add_argument('--outdir', required=True, help='The full file system path to the directory that will contain the fractional cover tif image.')
    parser.add_argument('--band_names', help='A comma separated list of band names. eg Min,Max,Mean')
    parser.add_argument('--xsize', help='The tile size for dimension x.', type=int)
    parser.add_argument('--ysize', help='The tile size for dimension y.', type=int)
    parser.add_argument('--no_data', help='The data value to be ignored.', type=int, default=-999)
    parser.add_argument('--as_bip', action='store_true', help='If set, the array will be transposed to be [Lines,Samples,Bands], and processed in this fashion. The default is to process the array as [Bands,Lines,Samples].')
    parser.add_argument('--as_bip_old', default=False, type=bool, help='If set to True, the array will be transposed to be [Lines,Samples,Bands], and processed in this fashion. The default is to process the array as [Bands,Lines,Samples]. Tests another way of setting a True/False switch.')

    parsed_args = parser.parse_args()


    path   = parsed_args.indir
    outdir = parsed_args.outdir
    if parsed_args.band_names:
        bnames = parsed_args.band_names.split(',')
    xtile  = parsed_args.xsize
    ytile  = parsed_args.ysize
    no_data = parsed_args.no_data
    as_bip = parsed_args.as_bip
    as_bip_old = parsed_args.as_bip_old


    print 'path: ', path
    print 'outdir: ', outdir
    print 'type(path): ', type(path)
    if parsed_args.band_names:
        print 'bnames: ', bnames
        print 'type(bnames): ', type(bnames)
    print 'xtile == None: ', xtile == None
    print 'ytile == None: ', ytile == None
    print 'type(no_data): ', type(no_data)
    print 'no_data: ', no_data
    print 'as_bip: ', as_bip
    print 'as_bip_old: ', as_bip_old
