#! /usr/bin/env python

import numpy
import numexpr

def test_main():

#-------------------------Filter Thresholds-----------------------------------
    
    global th1
    global th2
    th1 = 4
    th2 = 3

#-------------------------Sub Functions---------------------------
    def mult(array, multiplier=2):
        #a = array * multiplier
        a = numexpr.evaluate("array * multiplier")
        return a

    def thresh1(array):
        #b = array > th1
        #th1 = 4
        b = numexpr.evaluate("array > th1")
        return b

    def thresh2(array):
        #c = array < th2
        #th2 = 3
        c = numexpr.evaluate("array < th2")
        return c 

#--------------------------Processing------------------------------

    a = numpy.random.randint(0,6, (10,10))
    print a
    print

    m = mult(array=a)
    print m
    print

    t1 = thresh1(array=a)
    print t1.astype('int8')
    print

    t2 = thresh2(array=a)
    print t2.astype('int8')
    print

if __name__ == '__main__':

    test_main()

