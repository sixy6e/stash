#!/usr/bin/env python

import numpy
from scipy import ndimage
import numexpr
from IDL_functions import histogram, array_indices

#TODO
# Add a parameter for the histogram object and dictionary keyword for the reverse indices
# That way we can simply pass around the locations rather than have to recompute them

def obj_area(array):
    """
    Calculates area per object. Area is referred to as number of pixels.
    """

    h = histogram(array.flatten(i), Min=1)
    hist = h['histogram']

    return hist

def obj_centroid(array):
    """
    Calculates centroids per object.
    """

    dims = array.shape
    h    = histogram(array.flatten(), Min=1, reverse_indices='ri')
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
    h        = histogram(array.flatten(), Min=1, reverse_indices='ri')
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
        h    = histogram(array.flatten(), Min=1, reverse_indices='ri')
        hist = h['histogram']
        ri   = h['ri']
        arr  = array > 0
    else:
        # Label the array to assign id's to segments/regions
        lab, num = ndimage.label(array, k)

        # Calculate the histogram of the labelled array and retrive the indices
        h    = histogram(lab.flatten(), Min=1, reverse_indices='ri')
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
        h_i    = histogram(convolved[ri[ri[i]:ri[i+1]]], Min=1, Max=50)
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
    h    = histogram(array.flatten(), Min=1, reverse_indices='ri')
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

def track_obj_perimeter(array, start_index=None, label_id=None):
    """
    Function to track the perimeter of a given object specified by label_id.
    """

    dims = array.shape
    rows = dims[0]
    cols = dims[1]

    # We'll opt for the perimeter co-ordinates to be ordered in a clockwise fashion. GIS convention???
    pix_directions = [[ 0, 1],
                      [ 1, 1],
                      [ 1, 0],
                      [ 1,-1],
                      [ 0,-1],
                      [-1,-1],
                      [-1, 0],
                      [-1, 1]]

    # Set up the distances as we traverse across a pixel
    diag           = numpy.sqrt(2.0) # NumPy will return a float64, but just in case future versions change....
    pix_distances  = {0 : 1.0,
                      1 : diag,
                      2 : 1.0,
                      3 : diag,
                      4 : 1.0,
                      5 : diag,
                      6 : 1.0,
                      7, diag
                     }

    co_ords = []
    co_ords.append(start_index)

    # Initialise the to/from directions
    to_   = 0
    from_ = 4

    perimeter_point  = (-1,-1)
    perimeter_length = 0.0

    while (perimeter_point != start_index):
        for i in range(len(pix_directions)):
            to_         = (from_ + 4) % 8 # Track the direction we have been and the direction we are going
            current_idx = co_ords[-1]
            new_idx     = (current_idx[0] + pix_directions[to_][0], current_idx[1] + pix_directions[to_][1])
            if not (((new_idx[0] >= 0) & (new_idx[0] < rows)) & ((new_idx[1] >= 0) & (new_idx[1] < cols))):
                continue
            if array[new_idx] == label_id:
                break
        else:
            perimeter_point = new_idx
            co_ords.append(new_idx)
            # Next direction search will be one more than the from_ direction
            # Just in case we need to double back and return from whence we came. ie a line object
            from_ = (to_ + 4) % 8
            perimeter_length += pix_distances[to_]
            continue # Kick off the direction search again

    return {'Vertices' : co_ords, 'Perimeter_Length' : perimeter_length}

def obj_get_boundary_method1(labelled_array, fill_holes=True):
    """
    Get the pixels that mark the object boundary/perimeter.
    Method 1.
    
    8 neighbourhood chain code

         5 6 7
         4 . 0
         3 2 1

    4 neighbourhood chain code

         . 3 .
         2 . 0
         . 1 .

    """

    dims = labelled_array.shape
    rows = dims[0]
    cols = dims[1]

    if fill_holes:
        orig_binary = (labelled_array > 0).astype('uint8')
        fill = obj_fill_holes(labelled_array)
        s = [[1,1,1],[1,1,1],[1,1,1]]
        labelled_array, nlabels = ndimage.label(fill, structure=s)

    # We'll opt for the perimeter co-ordinates to be ordered in a clockwise fashion. GIS convention???
    pix_directions = numpy.array([[ 0, 1],
                                  [ 1, 1],
                                  [ 1, 0],
                                  [ 1,-1],
                                  [ 0,-1],
                                  [-1,-1],
                                  [-1, 0],
                                  [-1, 1]])

    # Set up the distances as we traverse across a pixel
    diag           = numpy.sqrt(2.0) # NumPy will return a float64, but just in case future versions change....
    pix_distances  = {0 : 1.0,
                      1 : diag,
                      2 : 1.0,
                      3 : diag,
                      4 : 1.0,
                      5 : diag,
                      6 : 1.0,
                      7, diag
                     }

    # Determine the co-ordinates (indices) of each segement
    # The first index of each segment will be used to define the start and end of a boundary/perimeter
    h = histogram(labelled_array.flatten(), Min=1, reverse_indices='ri')
    hist = h['histogram']
    ri = h['ri']
    nlabels = hist.shape[0]
    seg_start_idxs = numpy.zeros(nlabels, dtype='int')

    # Boundary or perimeter ?? Will go with perimeter, akin to a method implement earlier which uses a
    # convolution operator to determine perimeter length.

    # Obtain the start indices of each segment/object
    for i in numpy.arange(nlabels):
        #if (hist[i] == 0): # The labeled array should be consecutive
        #    continue
        seg_start_idxs[i] = ri[ri[i]:ri[i+1]][0] # Return the first index

    # Convert the 1D indices to 2D indices used by NumPy
    seg_start_idxs = array_indices(dims, seg_start_idxs, dimensions=True)

    # Lots to figure out here. Dealing with 'from' and 'too' directions can make things confusing
    # Keep track of the direction we last travelled, that way we can start at the next clockwise direction
    # For single pixel objects or 'islands' use the histogram value to skip the follow boundary/search routine

    """
    The memory of the order of the array should be 'C-Style': column, column, column, then next row.

    eg a 2x5 array

        0, 1, 2, 3, 4
        5, 6, 7, 8, 9

    Therefore the first index will only have labels to the right and below (below left, below right).

    eg an object with a label ID of 6

       0, 0, 6, 6, 6
       6, 6, 6, 6, 6

    As such, the first direction travelled will be to the right '0' in the freeman chain, and the first index will be the
    first boundary co-ordinate and will be the final co-ordinate to close the boundary thereby creating a polygon.
    As for linear features...
    """

    # Probably deal with these inside the boundary tracking routine
    # Let the tracking routine handle to/from and just return the final result
    to_   = 0
    from_ = 4

    perimeter_info = {}

    for i in range(hist.shape[0]):
        if hist[i] == 0:
            continue
        if hist[i] == 1:
            # What is the perimeter of a single pixel, 0.0, 4.0???
            #perimeter_co_ords[i] = seg_start_idxs[i[0],i[1]] # Still need to design the function and how to return the result
            continue
        idx   = (seg_start_idxs[0][i], seg_start_idxs[1][i])
        label = i + 1
        perimeter_info[i] = track_object_boundary(labelled_array, start_index=idx, label_id=label)

    # Might need to format the perimeter_info dictionary before returning, ie turn the co-ords into numpy arrays.
    # Or even into a polygon object using the shapely library???
    # Using shapely might be easier to report geometrical attributes

    # Still need to deal with holes within an object as ENVI does. They will increase an objects perimeter length.
    # SciPy have a binary_fill_holes function. label the filled array, then get the indices, and then retrive only those indices
    # for each object that are 0 in the original array.
    # That might be one way to do it, which means re-writing the above function....ughhh :)

    #!!!!This isn't the correct place for the handling of object holes, but just get the rough structure out!!!
    if fill_holes:
        for i in range(hist.shape[0]):
            if hist[i] == 0:
                continue
            if hist[i] == 1:
                # What is the perimeter of a single pixel, 0.0, 4.0???
                continue
            idx   = (seg_start_idxs[0][i], seg_start_idxs[1][i])
            label = i + 1
            perimeter_info[i] = track_object_boundary(labelled_array, start_index=idx, label_id=label)
            # Can we trust that the labelling of the filled and unfilled arrays will give the same object index??
            # If we can we could use the area differences to determine if there are holes and only go through the 
            # hole perimeter tracking if needed.
            single_object = numpy.zeros((rows*cols), dtype='uint8')
            single_object[ri[ri[i]:ri[i+1]]] = 1
            holes = numexpr.evaluate("(single_object - orig_binary) == 1")
            labs, nlabs = ndimage.label(holes, s)
            h_holes = histogram(labs, Min=1, reverse_indices='ri')
            hist_holes = h_holes['histogram']
            ri_h = h_holes['ri']
            seg_holes_start_idxs = numpy.zeros(nlabs, dtype='int')
            for j in numpy.arange(nlabels):
                #if (hist[i] == 0): # The labeled array should be consecutive
                #    continue
                seg_holes_start_idxs[j] = ri_h[ri_h[j]:ri_h[j+1]][0] # Return the first index

            # Convert the 1D indices to 2D indices used by NumPy
            seg_holes_start_idxs = array_indices(dims, seg_holes_start_idxs, dimensions=True)
            for k in range(hist_holes.shape):
                if hist_holes[k] == 0:
                    continue
                if hist[i] == 1:
                    # What is the perimeter of a single pixel, 0.0, 4.0???
                    continue
                idx = (seg_holes_start_idxs[0][k], seg_holes_start_idxs[1][k])
                holes_label = k + 1
                holes_result = track_object_boundary(labs, start_index=idx, label_id=holes_label)
                perimeter_info[i]['Holes'] = holes_result['Vertices']
                perimeter_info[i]['Perimeter_Length'] += perimeter_info['Perimeter_Length']

    return perimeter_info

def obj_fill_holes(array, labelled=True):
    """
    Fills holes within objects.
    """
    if labelled:
        fill = ndimage.binary_fill_holes(array > 0)
        #holes = fill - array
    else:
        fill = ndimage.binary_fill_holes(array)

    return fill

def obj_get_boundary_method2(labeled_array):
    """
    Get the pixels that mark the object boundary.
    Method 2

    The idea works and outputs the boundary. It doesn't quite work in all cases though.
    Mabye have to use the co-ordinate chain codes to aid in the decision as to which chain link
    a pixel should be appended to. Currently the method will search the end of each chain link
    and appends to the first match.
    Or implement a mehtod that will order the clockwise closest to the starting border pixel (basically the fisrt labeled pixel).
    Border pixels are found, just not always in the correct order. Bugger :( 
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

    chains = {}

    # Loop over the image investigating every pixel (probably not suitable for Python)
    # Just a play around to see if this method works
    # May try an F2Py approach if this succeeds

    cols = labeled_array.shape[1]
    rows = labeled_array.shape[0]

    for y in range(rows):
        for x in range(cols):
            label = labeled_array[y,x]
            if (label == 0):
                continue

            # Get co-ordinates of all neighbours
            all_neighb_points = [[y + val[0], x + val[1]] for val in pix_neighbours] # All 8 neighbours
            # Need to do checks for out of bounds
            in_bounds_all = [[val[0], val[1]] for val in all_neighb_points if ((val[0] >= 0) & (val[0] < rows) & (val[1] >= 0) & (val[1] < cols))]
            # Get labels of in-bounds all neighbours
            all_neighb = [lab[val[0], val[1]] for val in in_bounds_all] # All 8 neighbours
            # Get co-ordinates of adjacent neighbours
            adj_neighb_points = [[y + val[0], x + val[1]] for val in adjacent_neighbours] # Immediate 4 neighbours
            # Need to do checks for out of bounds
            in_bounds_adj = [[val[0], val[1]] for val in adj_neighb_points if ((val[0] >= 0) & (val[0] < rows) & (val[1] >= 0) & (val[1] < cols))]
            # Get labels of in-bounds adjacent neighbours
            adj_neighb = [lab[val[0], val[1]] for val in in_bounds_adj]

            # Border tests
            island = all(val != label for val in all_neighb)
            body   = all(val == label for val in all_neighb)

            if body: # Label surrounded by the same label
                continue
            if label not in coord_chain.keys():
                coord_chain[label] = [[]]
                chains[label] = 1
            if island: # Label surronded by zeros or other labels
                coord_chain[label][0] = [y,x]
            #if len(coord_chain[label][0][-1]) != 0:
            #    check_yx = coord_chain[label][0][-1]
            #    check_adj = check_yx in adj_neighb
            #    if check_adj:
            #        coord_chain[label][0].append([y,x])
            #    else:
            #        # Need to loop over each chain segment. Maybe include this above and only loop the whole chain rather than the extra chain
            #        if len(extra_chains[label]) != 0:
            #            for extra in extra_chains[lab]:
            #                check_yx = extra[-1]
            #                check_adj = check_yx in adj_neighb
            #                if check_adj:
            #                    extra[label].append([y,x])
            #                    continue
            #            else:
            #                chains[label] += 1
            #                coord_chain[lab][1] = [y,x]
            if len(coord_chain[label][0]) == 0: # Create the first chain
                coord_chain[label][0].append([y,x])
                continue
            check_chains = []
            # This has became too messy
            for i in range(chains[label]):
                #if len(coord_chain[label][i][-1]) != 0:
                #if len(coord_chain[label][i]) != 0:
                check_yx = coord_chain[label][i][-1]
                check_adj = check_yx in in_bounds_adj
                check_chains.append(check_adj)
                if (y == 2) & (x == 8):
                    print 'y,x ', y,x
                    print 'check_yx ', check_yx
                    print 'check_adj', check_adj
                    print 'in_bounds_adj', in_bounds_adj
                    #if check_adj:
                    #    coord_chain[lab][i].append([y,x])
                    #    break
                    #chain = any(val == True for val in check_chains)
                    #if check_adj:
                    #if chain:
                    #    idx = [i for i, val in enumerate(check_chains) if val][0] # Get the first True value
                    #    coord_chain[label][idx].append([y,x])
                    #    break
                    #else:
                    #    chains[label] += 1
                    #    idx = chains[label] - 1
                        #coord_chain[label][chains[label]].append([y,x]) # Number of chains as opposed to the index
                    #    coord_chain[label].append([[y,x]]) # Number of chains as opposed to the index
                    #    break
                #else: # Create a new chain
                #    coord_chain[label][i].append([y,x])
                #    break
            #else:
            #    continue
            chain = any(val == True for val in check_chains)
            if chain:
                idx = [i for i, val in enumerate(check_chains) if val][0] # Get the first True value
                coord_chain[label][idx].append([y,x]) # Append to an existing link in the chain
            else:
                chains[label] += 1
                #idx = chains[label] - 1
                coord_chain[label].append([[y,x]]) # Create a new link in chain

    return coord_chain
