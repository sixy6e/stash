import numpy

def indices_2d(array, indices):
    """ Converts 1D indices into their 2D counterparts.

        Args:
            array: 
                 A 2D array on which the indices were derived. Can accept a 3D 
                 array but indices are assumed to be in 2D.
            indices:
                 The 1D array containing the indices. Can accept the tuple
                 returned from a 'where' statement.

        Returns:
            A tuple containing the 2D indices.

        Author:
            Josh Sixsmith, joshua.sixsmith@ga.gov.au

    """

    dims = array.shape
    if (len(dims) == 3):
        rows = dims[1]
        cols = dims[2]
    elif (len(dims) == 2):
        rows = dims[0]
        cols = dims[1]
    elif (len(dims) == 1):
        return indices
    else:
        print 'Error. Array not of correct shape!'
        return

    if (type(indices) == tuple):
        if (len(indices) == 1):
            indices = indices[0]
        else:
            print 'Error. Indices is not a 1 dimensional array!'
            return

    sz = cols * rows
    min = numpy.min(indices)
    max = numpy.max(indices)

    if ((min < 0) | (max >= sz)):
        print 'Error. Index out of bounds!'
        return

    r = indices / cols
    c = indices % cols
    ind = (r,c)

    return ind


