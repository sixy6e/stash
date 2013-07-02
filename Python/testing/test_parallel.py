#! /usr/bin/env python

import numpy
import multiprocessing
from multiprocessing import Pool, Array

def func(array, tiles, out):
    #print tiles
    a = tiles[0]
    b = tiles[1]
    c = tiles[2]
    d = tiles[3]
    out[a:b,c:d] = array[a:b, c:d]
    return

    

# This is a more efficient method than get_tile
# Using this method, only one for loop is needed for processing
def get_tile2(array, xtile=100,ytile=100):
    #st = datetime.datetime.now()
    dims = array.shape
    ncols = dims[1]
    nrows = dims[0]
    l = []
    if len(dims) >2:
        ncols = dims[2]
        nrows = dims[1]
        dims  = (nrows,ncols)
    xstart = numpy.arange(0,ncols,xtile)
    ystart = numpy.arange(0,nrows,ytile)
    for ystep in ystart:
        if ystep + ytile < nrows:
            yend = ystep + ytile
        else:
            yend = nrows
        for xstep in xstart:
            if xstep + xtile < ncols:
                xend = xstep + xtile
            else:
                xend = ncols
            l.append((ystep,yend,xstep, xend))
    #et = datetime.datetime.now()
    #print 'get_tile2 time taken: ', et - st
    return l 

if __name__ == '__main__':
    a = numpy.random.randint(0,101, (100,100))
    b = Array('i', 100*100) 
    #out = numpy.zeros_like(a)
    arr = numpy.frombuffer(b.get_obj())
    print arr.shape
    #out = numpy.frombuffer(b.get_obj()).reshape(100,100)
    print 'a'
    print a
    print 'out'
    print out
    tiles = get_tile2(a, 12,12)
    pool = Pool(processes=2)
    #pool.apply(func, args=(a,tiles, out))
    result=[pool.apply_async(func, (a, tile, out)) for tile in tiles]
    print 'a'
    print a
    print 'out'
    print out
    print 'result'
    print result

    #p = multiprocessing.Process(target=func, args=(a,tiles, out))
    #p.start()
    #p.join()
    #pool.map(func, args=(a,tiles, out))
    #pool.close()
    #pool.join()

