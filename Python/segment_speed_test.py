#!/usr/bin/env python
import numpy
import argparse
import datetime
from IDL_functions import histogram

def numpy_test():
    """
    A small test that investigates the speed of finding specific objects/segments
    within an image.  The identifed objects are then set/flagged in an array of the
    same dimensions as the original image.  This just illustrates the finding mechanism,
    but in reality statistics can be generated per segment/object.
    This is the method for solving such a problem in Python and NumPy.
    """
    print 'The NumPy method!'
    st = datetime.datetime.now()
    img = numpy.random.randint(0,30001, (8000,8000))
    b = numpy.random.randint(0,30001, (3000))
    c = numpy.unique(b)
    img2 = numpy.zeros((8000,8000), dtype='uint8').flatten()
    find = numpy.in1d(img.flatten(), c)
    img2[find] = 1
    img2 = img2.reshape(8000,8000)
    et = datetime.datetime.now()
    print et - st

def idl_test():
    """
    A small test that investigates the speed of finding specific objects/segments
    within an image.  The identifed objects are then set/flagged in an array of the
    same dimensions as the original image.  This just illustrates the finding mechanism,
    but in reality statistics can be generated per segment/object.
    This is the method for solving such a problem using the histogram module.

    To Note:
        This is just one simple example of using the histogram to solve such an
        abstract problem.  It can be used for so much more, such as chunk indexing
        and incrementing vectors. 
        See http://www.idlcoyote.com/tips/histogram_tutorial.html for more info.
    """
    print 'The IDL method!'
    st = datetime.datetime.now()
    img = numpy.random.randint(0,30001, (8000,8000))
    b = numpy.random.randint(0,30001, (3000))
    c = numpy.unique(b)
    img2 = numpy.zeros((8000,8000), dtype='uint8').flatten()
    h = histogram(img.flatten(), min=0, max=numpy.max(c), reverse_indices='ri')
    hist = h['histogram']
    ri = h['ri']
    for i in numpy.arange(c.shape[0]):
        if hist[c[i]] == 0:
            continue
        img2[ri[ri[c[i]]:ri[c[i]+1]]] = 1
    et = datetime.datetime.now()
    print et - st

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description="A small test that investigates the speed of finding specific objects/segments within an image. The identifed objects are then set/flagged in an array of the same dimensions as the original image. This just illustrates the finding mechanism, but in reality statistics can be generated per segment/object. Two methods are tested, one using NumPy, the other using the histogram.")
    parser.add_argument('--idl', action='store_true', help='Solves the problem using the IDL method.')
    parser.add_argument('--numpy', action='store_true', help='Solves the problem using the NumPy method.')
    parser.add_argument('--both', action='store_true', help='Solves the problem testing both the IDL and NumPy methods.')

    parsed_args = parser.parse_args()
    test_IDL    = parsed_args.idl
    test_NumPy  = parsed_args.numpy
    test_both   = parsed_args.both

    if test_IDL:
        idl_test()

    if test_NumPy:
        numpy_test()
    
    if test_both:
        idl_test()
        numpy_test()

