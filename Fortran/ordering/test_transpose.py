#!/usr/bin/env python

import numpy
from test_ordering import ordering

a = numpy.arange(90).reshape(10,9).astype('int16')
adims = a.shape
print 'normal\ncols: {cols}\nrows: {rows}'.format(cols=adims[1], rows=adims[0])
b = a.transpose()
bdims = b.shape
print 'transpose\ncols: {cols}\nrows: {rows}'.format(cols=bdims[1], rows=bdims[0])

c = ordering(b)
cdims = c.shape
print 'result\ncols: {cols}\nrows: {rows}'.format(cols=cdims[1], rows=cdims[0])

d = c.transpose()
ddims = d.shape
print 'transpose\ncols: {cols}\nrows: {rows}'.format(cols=ddims[1], rows=ddims[0])
