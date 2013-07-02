#! /usr/bin/env python
import numpy
import multiprocessing
from multiprocessing import Array, Pool, Process

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


def func(a, tile, out):
    ys=tile[0]
    ye=tile[1]
    xs=tile[2]
    xe=tile[3]
    #print out[ys:ye,xs:xe]
    out[ys:ye,xs:xe] = a[ys:ye,xs:xe]
    #print out[ys:ye,xs:xe]
    return

def func2(a, tiles, out):
    for tile in tiles:
        ys=tile[0]
        ye=tile[1]
        xs=tile[2]
        xe=tile[3]
        #print out[ys:ye,xs:xe]
        out[ys:ye,xs:xe] = a[ys:ye,xs:xe]
        #print out[ys:ye,xs:xe]
    return
if __name__ == '__main__':
    jobs = []
    #aa = numpy.random.randint(0,256,(1000,1000))
    a = numpy.random.randint(0,256,(1000,1000))
    #a = numpy.ctypeslib.as_array(Array('i', 1000*1000).get_obj()).reshape(1000,1000)
    #a[:] = aa
    #b = numpy.array(Array('i', 1000*1000).get_obj()).reshape(1000,1000)
    b = numpy.ctypeslib.as_array(Array('i', 1000*1000).get_obj()).reshape(1000,1000)
    print 'a', a
    print 'b', b
    tiles = get_tile2(a, 12,12)
    pool = Pool(processes=2)
    #for i in range(8000):
    #    for j in range(8000):
    #        p = multiprocessing.Process(target=func, args=(a,b,i,j))
    #        jobs.append(p)
    #        p.start()
    #result=[pool.apply_async(func, (a, tile, b)) for tile in tiles]
    #[pool.apply_async(func, (a, tile, b)) for tile in tiles]
    #p = Process(target=func2, args=(a, tiles, b))
    #p.start()
    #p.join()
    r = [pool.apply_async(func, (a, tile, b)) for tile in tiles]
    print 'a', a
    print 'b'
    print b
    #print 'result[0]', result[0].get()

