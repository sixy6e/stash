#! /usr/bin/env python
import numpy

def array_indices(array, index, dimensions=False):
    """
    Replicates the array_indices function available within IDL (Interactive Data Language, EXELISvis).
    Converts one-dimensional subscripts of an array into corresponding multi-dimensional subscripts.

    :param array:
        A numpy array of any type, whose dimensions should be used in converting the subscripts. If dimensions is set to True then array should be a list or tuple containing the dimensions.

    :param index:
        A scalar or 1D numpy array containing the one-dimensional subscripts to be converted.

    :param dimensions:
        If set to True, then array should be a list or tuple containing the dimensions. Default is False. Dimensions are retrieved by array.shape.

    :return:
        A tuple of numpy 1D arrays containing the multi-dimensional subscripts.

    Example:

        >>> a = numpy.random.randint(0,256,(10000))
        >>> wh = numpy.where(a == 66)
        >>> b = a.reshape(100,100)
        >>> ind2D = array_indices(array=b, index=wh[0])
        >>> # Using the dimensions keyword
        >>> ind2D_b = array_indices(array=b.shape, index=wh[0], dimensions=True)

    :author:
        Josh Sixsmith, joshua.sixsmith@ga.gov.au, josh.sixsmith@gmail.com

    :history:
        * 23/10/2013: Created

    :notes:
        IDL will return an (m x n) array, with each row (n, IDL is [col,row]) containing the multi-dimensional subscripts corresponding to that index. However this function will return a tuple containing n numpy arrays, where n is the number of dimensions. This allows numpy to use the returned tuple for normal array indexing.

    :copyright:
        Copyright (c) 2013, Josh Sixsmith
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        1. Redistributions of source code must retain the above copyright notice, this
           list of conditions and the following disclaimer.
        2. Redistributions in binary form must reproduce the above copyright notice,
           this list of conditions and the following disclaimer in the documentation
           and/or other materials provided with the distribution.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
        ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

        The views and conclusions contained in the software and documentation are those
        of the authors and should not be interpreted as representing official policies,
        either expressed or implied, of the FreeBSD Project.

    """
 
    if (type(index) != numpy.ndarray):
        if (numpy.isscalar(index) != True):
            raise Exception('Error! Index must either be a 1D numpy array or a scalar!!!')
            return

    if dimensions:
        dims        = array
        ndimensions = len(dims)
        nelements   = numpy.prod(numpy.array(dims))
    else:
        dims        = array.shape
        ndimensions = len(dims)
        nelements   = numpy.prod(numpy.array(dims))

    if (len(dims) == 3):
        rows  = dims[1]
        cols  = dims[2]
        bands = dims[0]
    elif (len(dims) == 2):
        rows  = dims[0]
        cols  = dims[1]
        bands = 0

    # Calculate min and max for bounds checking
    min_ = numpy.min(index)
    max_ = numpy.max(index)

    # Check that the index is not out of bounds.
    # Negatives are legal in python, but make it harder to determine the
    # multi-dimensional index
    if ((min_ < 0) | (max_ >= nelements)):
        raise Exception('Error. Index out of bounds!')
        return

    # 1D case; basically do nothing!
    if (ndimensions <= 1):
        return index
    # 2D case;
    elif (ndimensions == 2):
        r   = index / cols
        c   = index % cols
        ind = (r,c)
        return ind
    # 3D case;
    elif (ndimensions == 3):
        b   = index / (cols * rows)
        r   = (index % (cols * rows)) / cols
        c   = index % cols
        ind = (b,r,c)
        return ind
    # Higher D order;
    else:
        dims_rv = dims[::-1]
        i = 1
        cumu_dims_rv = []
        for D in dims_rv:
            i *= D
            cumu_dims_rv.append(i)

        cumu_dims = cumu_dims_rv[::-1]
        idx = []

        # Leftmost dimension to rightmost -1 dimension
        for i in range(1,len(dims)):
            idx.append((index / cumu_dims[i]) % dims[i-1])

        # For rightmost dimension, ie the columns.
        idx.append(index % dims[-1])
        ind = tuple(idx)
        return ind

