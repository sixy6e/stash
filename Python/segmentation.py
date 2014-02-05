#!/usr/bin/env python

import numpy
from scipy import ndimage
from IDL_functions import histogram, array_indices

#TODO
# Add a parameter for the histogram object and dictionary keyword for the reverse indices
# That way we can simply pass around the locations rather than have to recompute them

def obj_area(array):
    """
    Calculates area per object. Area is referred to as number of pixels.
    """

    h = histogram(array.flatten(i), min=1)
    hist = h['histogram']

    return hist

def obj_centroid(array):
    """
    Calculates centroids per object.
    """

    dims = array.shape
    h    = histogram(array.flatten(), min=1, reverse_indices='ri')
    hist = h['histogram']
    ri   = h['ri']
    cent = []
    for i in numpy.arange(hist.shape[0]):
        if (hist[i] == 0):
            continue
        idx = numpy.array(array_indices(dims, ri[ri[i]:ri[i+1]], dimensions=True))
        cent_i = numpy.mean(idx, axis=1)
        cent.append(cent_i)

    return cent

def obj_mean(array, base_array):
    """
    Calculates mean value per object.
    """
    arr_flat = base_array.flatten()
    h        = histogram(array.flatten(), min=1, reverse_indices='ri')
    hist     = h['histogram']
    ri       = h['ri']
    mean_obj = []
    for i in numpy.arange(hist.shape[0]):
        if (hist[i] == 0): 
            continue
        xbar = numpy.mean(arr_flat[ri[ri[i]:ri[i+1]]])
        mean_obj.append(xbar)

    return mean_obj

def perimeter(array, labelled=False, all_neighbors=False):
    """
    Calculates the perimeter per object.
    """

    # Construct the kernel to be used for the erosion process
    if all_neighbors:
        k = [[1,1,1],[1,1,1],[1,1,1]]
    else:
        k = [[0,1,0],[1,1,1],[0,1,0]]

    if labelled:
        # Calculate the histogram of the labelled array and retrive the indices
        h    = histogram(array.flatten(), min=1, reverse_indices='ri')
        hist = h['histogram']
        ri   = h['ri']
        arr  = array > 0
    else:
        # Label the array to assign id's to segments/regions
        lab, num = ndimage.label(array, k)

        # Calculate the histogram of the labelled array and retrive the indices
        h    = histogram(lab.flatten(), min=1, reverse_indices='ri')
        hist = h['histogram']
        ri   = h['ri']
        arr = array

    # Erode the image
    erode = ndimage.binary_erosion(arr, k)

    # Get the borders of each object/region/segment
    obj_borders = arr - erode

    # There is potential here for the kernel to miss object borders containing diagonal features
    # Force the kernel to include all neighbouring pixels
    #k = [[1,1,1],[1,1,1],[1,1,1]]
    #label_arr, n_labels = ndimage.label(obj_borders, k)
    #TODO
    # An alternative would be to use the reverse_indices of the original objects.
    # It shouldn't matter if they point to zero in the convolve array as the second histogram will exclude them.

    #h    = histogram(label_arr.flatten(), min=1, reverse_indices='ri')
    #hist = h['histogram']
    #ri   = h['ri']

    # Construct the perimeter kernel
    k2 = [[10,2,10],[2,1,2],[10,2,10]]
    convolved = ndimage.convolve(obj_borders, k2, mode='constant', cval=0.0) # pixels on array border only use values within the array extents

    # Initialise the perimeter list
    perim   = []

    # Calculate the weights to be used for each edge pixel's contribution
    sqrt2   = numpy.sqrt(2.)
    weights = numpy.zeros(50)
    weights[[5,7,15,17,25,27]] = 1 # case (a)
    weights[[21,33]] = sqrt2 # case (b)
    weights[[13,23]] = (1. + sqrt2) / 2. # case (c)

    for i in numpy.arange(hist.shape[0]):
        #if hist[i] # Probable don't need this check, as ndimage.label() should provide consecutive labels
        h_i    = histogram(convolved[ri[ri[i]:ri[i+1]]], min=1, max=50)
        hist_i = h_i['histogram']
        perim.append(numpy.dot(hist_i, weights))

    perim = numpy.array(perim)

    return perim

def obj_compactness(array):
    """
    Calculates centroids per object.
    """

    pi          = numpy.pi
    area        = obj_area(array)
    perim       = perimeter(array, labelled=True)
    compactness = (perim**2)/(4*pi*area)

    return compactness

def obj_rectangularity(array):
    """
    Calculates rectangularity per object.
    """

    dims = array.shape
    h    = histogram(array.flatten(), min=1, reverse_indices='ri')
    hist = h['histogram']
    ri   = h['ri']
    rect = []
    for i in numpy.arange(hist.shape[0]):
        if (hist[i] == 0):
            continue
        idx = numpy.array(array_indices(dims, ri[ri[i]:ri[i+1]], dimensions=True))
        min_yx = numpy.min(idx, axis=1)
        max_yx = numpy.max(idx, axis=1)
        diff = max_yx - min_yx + 1 # Add one to account for zero based index
        bbox_area = numpy.prod(diff)
        rect.append(hist[i] / bbox_area)

    return rect

def obj_roundness(array):
    """
    Calculates roundness per object.
    """

    roundness = 1. / obj_compactness(array)

    return roundness

def pdf(hist_array, scale=False, double=False):
    """
    Calculates the probability density function from a histogram.
    """

    # Calculate in double precision?
    if double:
        dtype = 'float'
    else:
        dtype = 'float32'

    # Calculate the cumulative distribution
    cdf = numpy.cumsum(hist_array, dtype=dtype)

    # Calculate the probability density function
    pdf = cdf / cdf[-1]

    # Scale 0-100 percent?
    if scale:
        pdf = pdf * 100

    return pdf

def obj_get_boundary_method1():
    """
    Get the pixels that mark the object boundary.
    Method 1.
    """
    pix_directions = numpy.array([[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1],[-1,0],[-1,1]])
    
    # Lots to figure out here

    return

def obj_get_boundary_method2():
    """
    Get the pixels that mark the object boundary.
    Method 2.
    """

    lab = labeled_array
    labels_touched = [] # Maintain a list of recently investigated labels
    coord_chain = {} # Initialise the co-ordinate chain dictionary
    boundary_coords = []
    
    """
    8 neighbourhood chain code

         5 6 7
         4 . 0
         3 2 1

    4 neighbourhood chain code

         . 3 .
         2 . 0
         . 1 .
    """

    pix_neighbours      = [[0,1],[1,1],[1,0],[1,-1],[0,-1],[-1,-1],[-1,0],[-1,1]]
    adjacent_neighbours = [[0,1],[1,0],[0,-1],[-1,0]]

    extra_chains = {}

    # Loop over the image investigating every pixel (probably not suitable for Python)
    # Just a play around to see if this method works
    # May try an F2Py approach if this succeeds

    cols = labeled_array.shape[1]
    rows = labeled_array.shape[0]

    for y in range(rows):
        for x in range(cols):
            label = labeled_array[y,x]
            if (lab[y,x] == 0):
                continue

            # Get co-ordinates of all neighbours
            all_neighb_points = [[y + val[0], x + val[1]] for val in pix_neighbours] # All 8 neighbours
            # Need to do checks for out of bounds
            in_bounds_all = [[val[0], val[1]] for val in all_neighb_points if ((val[0] >= 0) & (val[0] < rows) & (val[1] >= 0) & (val[1] < cols))]
            # Get labels of in-bounds all neighbours
            all_neighb = [lab[val[0], val[1]] for val in in_bounds_all] # All 8 neighbours
            # Get co-ordinates of adjacent neighbours
            adj_neighb_points = [[y + val[0], x + val[1] for val in adjacent_neighbours] # Immediate 4 neighbours
            # Need to do checks for out of bounds
            in_bounds_adj = [[val[0], val[1]] for val in adj_neighb_points if ((val[0] >= 0) & (val[0] < rows) & (val[1] >= 0) & (val[1] < cols))]
            # Get labels of in-bounds adjacent neighbours
            adj_neighb = [lab[val[0], val[1]] for val in in_bounds_adj]

            # Border tests
            island = all(val != label for val in all_neighb)
            body   = all(val == label for val in all_neighb)

            if body: # Label surrounded by the same label
                continue
            if lab not in coord_chain.keys():
                coord_chain[lab] = [[]]
                extra_chains[lab] = 0
            if island: # Label surronded by zeros or other labels
                coord_chain[lab][0] = [y,x]
            if len(coord_chain[lab][0][-1]) != 0:
                check_y, check_x = coord_chain[lab][0][-1]
                check_adj = any((check_y == val[0]) & (check_x == val[1]) for val in adj_neighb)
                if check_adj:
                    coord_chain[lab][0].append([y,x])
                else:
                    # Need to loop over each chain segment. Maybe include this above and only loop the whole chain rather than the extra chain
                    if len(extra_chains[lab]) != 0:
                        for extra in extra_chains[lab]:
                            check_y, check_x = extra[-1]
                            check_adj = any((check_y == val[0]) & (check_x == val[1]) for val in adj_neighb)
                            if check_adj:
                                extra[lab].append([y,x])
                                continue
                        else:
                            extra_chains[lab] += 1
                            coord_chain[lab][1] = [y,x]
                
