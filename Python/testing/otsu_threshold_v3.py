'''
Created on 06/02/2013

Author: Josh Sixsmith, joshua.sixsmith@ga.gov.au
'''

import numpy
from IDL_functions import IDL_Histogram

def otsu_threshold(image, Fast=True, Apply=False):
    dims = image.shape
    if (len(dims) > 3):
        print 'Incorrect shape!; More than 3 dimensions is not a standard image.'
        return None
#>>> def otsu(a):
#...     h = IDL_Histogram(a, locations='loc', omin='omin')
#...     hist = h['histogram']
#...     loc = h['loc']
#...     omin = h['omin']
#...     cdf = numpy.cumsum(hist, dtype=float)
#...     rcdf = numpy.cumsum(hist[::-1], dtype=float)
#...     total = cdf[-1]
#...     wb = cdf/total
#...     wf = (rcdf/total)[::-1]
#...     mub = numpy.cumsum(hist * loc)/cdf
#...     muf = (numpy.cumsum(hist[::-1] * loc[::-1])/rcdf)[::-1]
#...     bwtsig = wb * wf *(mub - muf)**2
#...     thresh = numpy.argmax(bwtsig)
#...     binsz = loc[1] - loc[0]
#...     thresh = thresh*binsz + omin
#...     print thresh

def otsu2(a):
    h = IDL_Histogram(a, locations='loc', omin='omin')
    hist = h['histogram']
    loc = h['loc']
    omin = h['omin']
    cdf = numpy.cumsum(hist, dtype=float)
    rcdf = numpy.cumsum(hist[::-1], dtype=float)
    total = cdf[-1]
    wb = cdf/total
    wf = (1 - wb) # reverse probability
    mub = numpy.cumsum(hist * loc)/cdf
    muf = (numpy.cumsum(hist[::-1] * loc[::-1])/rcdf)[::-1]
    bwtsig = wb * wf *(mub - muf)**2
    thresh = numpy.argmax(bwtsig)
    binsz = loc[1] - loc[0]
    thresh = thresh*binsz + omin
    print thresh
    return (mub,muf)

def otsu5(a):
    h = IDL_Histogram(a, locations='loc', omin='omin')
    hist = h['histogram']
    loc = h['loc']
    omin = h['omin']
    cdf = numpy.cumsum(hist, dtype=float)
    rcdf = numpy.cumsum(hist[::-1], dtype=float)
    total = cdf[-1]
    wb = cdf/total
    wf = (1 - wb) # reverse probability
    mub = numpy.zeros(hist.shape[0])
    muf = numpy.zeros(hist.shape[0])
    mub[0:-1] = (numpy.cumsum(hist * loc)/cdf)[0:-1]
    muf[0:-1] = ((numpy.cumsum(hist[::-1] * loc[::-1])/rcdf)[::-1])[1:]
    bwtsig = wb * wf *(mub - muf)**2
    thresh = numpy.argmax(bwtsig)
    binsz = loc[1] - loc[0]
    thresh = thresh*binsz + omin
    print thresh
    return (mub,muf)


def otsu4(a):
    h = IDL_Histogram(a, locations='loc', omin='omin')
    hist = h['histogram']
    loc = h['loc']
    omin = h['omin']
    #wb = numpy.cumsum(hist, dtype=float)
    wb = 0.
    total = a.shape[0]
    #wf = total - wb
    wf = 0.
    #sumB = numpy.cumsum(hist * loc, dtype=float)
    sumB = 0.
    total2 = numpy.sum(hist * loc, dtype=float)
    varmax = 0
    mB = numpy.zeros(hist.shape[0])
    mF = numpy.zeros(hist.shape[0])
    for i in numpy.arange(hist.shape[0]):
        wb += hist[i]
        if (wb == 0):
            continue
        wf = total - wb
        if (wf == 0):
            break
        sumB += loc[i] * hist[i]
        mB[i] = sumB/wb
        mF[i] = (total2 - sumB)/wf
        bwtsig = wb * wf * (mB[i] - mF[i])**2
        if (bwtsig > varmax):
            varmax = bwtsig
            thresh = i
    binsz = loc[1] - loc[0]
    thresh = thresh*binsz + omin
    print thresh
    return (mB,mF)


    if Fast:
        if (len(dims) == 3):
            # For multi-band images, return a list of thresholds
            thresholds = []
            bands = dims[0]
            for b in range(bands):
                img = image[b].flatten()

                h = IDL_Histogram(img, locations='loc', omin='omin')
                hist = h['histogram']
                omin = h['omin']
                loc  = h['loc']
                binsz = loc[1] - loc[0]

                cumu_hist  = numpy.cumsum(hist, dtype=float)
                rcumu_hist = numpy.cumsum(hist[::-1], dtype=float) # reverse

                total = cumu_hist[-1]

                # probabilities per threshold class
                bground_weights = cumu_hist / total
                fground_weights = 1 - bground_weights # reverse probability
                mean_bground = numpy.zeros(hist.shape[0])
                mean_fground = numpy.zeros(hist.shape[0])
                mean_bground[0:-1] = (numpy.cumsum(hist * loc[::-1]) / cumu_hist)[0:-1]
                mean_fground[0:-1] = ((numpy.cumsum(hist[::-1] * loc[::-1]) / rcumu_hist)[::-1])[1:]
                sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)**2
                thresh = numpy.argmax(sigma_between)
                binsz = loc[1] - loc[0]
                thresh = (thresh * binsz) + omin

                thresholds.append(thresh)

            if Apply:
                masks = numpy.zeros(dims, dtype='bool')
                for b in range(bands):
                    masks[b] = image[b] > thresholds[b]
                return masks
            else:
                return thresholds

        elif (len(dims) == 2):
            img = image.flatten()
            h = IDL_Histogram(img, locations='loc', omin='omin')
            hist = h['histogram']
            omin = h['omin']
            loc  = h['loc']
            binsz = loc[1] - loc[0]
 
            cumu_hist  = numpy.cumsum(hist, dtype=float)
            rcumu_hist = numpy.cumsum(hist[::-1], dtype=float) # reverse
 
            total = cumu_hist[-1]
 
            # probabilities per threshold class
            bground_weights = cumu_hist / total
            fground_weights = 1 - bground_weights # reverse probability
            mean_bground = numpy.zeros(hist.shape[0])
            mean_fground = numpy.zeros(hist.shape[0])
            mean_bground[0:-1] = (numpy.cumsum(hist * loc[::-1]) / cumu_hist)[0:-1]
            mean_fground[0:-1] = ((numpy.cumsum(hist[::-1] * loc[::-1]) / rcumu_hist)[::-1])[1:]
            sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)**2
            thresh = numpy.argmax(sigma_between)
            binsz = loc[1] - loc[0]
            thresh = (thresh * binsz) + omin
 
            threshold = thresh

            if Apply:
                mask = image > threshold
                return mask
            else:
                return threshold


        elif (len(dims) == 1):
            h = IDL_Histogram(image, locations='loc', omin='omin')
            hist = h['histogram']
            omin = h['omin']
            loc  = h['loc']
            binsz = loc[1] - loc[0]

            cumu_hist  = numpy.cumsum(hist, dtype=float)
            rcumu_hist = numpy.cumsum(hist[::-1], dtype=float) # reverse

            total = cumu_hist[-1]

            # probabilities per threshold class
            bground_weights = cumu_hist / total
            fground_weights = 1 - bground_weights # reverse probability
            mean_bground = numpy.zeros(hist.shape[0])
            mean_fground = numpy.zeros(hist.shape[0])
            mean_bground[0:-1] = (numpy.cumsum(hist * loc[::-1]) / cumu_hist)[0:-1]
            mean_fground[0:-1] = ((numpy.cumsum(hist[::-1] * loc[::-1]) / rcumu_hist)[::-1])[1:]
            sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)**2
            thresh = numpy.argmax(sigma_between)
            binsz = loc[1] - loc[0]
            thresh = (thresh * binsz) + omin

            threshold = thresh

            if Apply:
                mask = image > threshold
                return mask
            else:
                return threshold

    else:
        if (len(dims) == 3):
            # For multi-band images, return a list of thresholds
            thresholds = []
            bands = dims[0]
            for b in range(bands):
                img = image[b].flatten()
                h = IDL_Histogram(img, reverse_indices='ri', omin='omin', omax='omax', locations='loc')

                hist = h['histogram']
                ri   = h['ri']
                omin = h['omin']
                loc  = h['loc']

                nbins = hist.shape[0]
                binsz = loc[1] - loc[0]

                nB = numpy.cumsum(hist, dtype='int64')
                total = nB[-1]
                nF = total - nB
        
                # should't be a problem to start at zero. best_sigma should (by design) always be positive
                best_sigma = 0
                # set to loc[0], thresholds can be negative
                optimal_t = loc[0]
        
                for i in range(nbins):
                    # get bin zero to the threshold 'i', then 'i' to nbins
                    if ((ri[i+1] > ri[0]) and (ri[nbins] > ri[i+1])):
                        mean_b = numpy.mean(img[ri[ri[0]:ri[i+1]]], dtype='float64')
                        mean_f = numpy.mean(img[ri[ri[i+1]:ri[nbins]]], dtype='float64')
                        sigma_btwn = nB[i]*nF[i]*((mean_b - mean_f)**2)
                        if (sigma_btwn > best_sigma):
                            best_sigma = sigma_btwn
                            optimal_t = loc[i]
                        
                thresholds.append(optimal_t)

            if Apply:
                masks = numpy.zeros(dims, dtype='bool')
                for b in range(bands):
                    masks[b] = image[b] > thresholds[b]
                return masks
            else:
                return thresholds

            
        elif (len(dims) == 2):
            img = image.flatten()
            h = IDL_Histogram(img, reverse_indices='ri', omin='omin', omax='omax', locations='loc')

            hist = h['histogram']
            ri   = h['ri']
            omin = h['omin']
            loc  = h['loc']

            nbins = hist.shape[0]
            binsz = loc[1] - loc[0]

            nB = numpy.cumsum(hist, dtype='int64')
            total = nB[-1]
            nF = total - nB
        
            # should't be a problem to start at zero. best_sigma should (by design) always be positive
            best_sigma = 0
            # set to loc[0], thresholds can be negative
            optimal_t = loc[0]
        
            for i in range(nbins):
                # get bin zero to the threshold 'i', then 'i' to nbins
                if ((ri[i+1] > ri[0]) and (ri[nbins] > ri[i+1])):
                    mean_b = numpy.mean(img[ri[ri[0]:ri[i+1]]], dtype='float64')
                    mean_f = numpy.mean(img[ri[ri[i+1]:ri[nbins]]], dtype='float64')
                    sigma_btwn = nB[i]*nF[i]*((mean_b - mean_f)**2)
                    if (sigma_btwn > best_sigma):
                        best_sigma = sigma_btwn
                        optimal_t = loc[i]
                        
            threshold = optimal_t
            if Apply:
                mask = image > threshold
                return mask
            else:
                return threshold

        elif (len(dims) == 1):
            h = IDL_Histogram(image, reverse_indices='ri', omin='omin', locations='loc')

            hist = h['histogram']
            ri   = h['ri']
            omin = h['omin']
            loc  = h['loc']

            nbins = hist.shape[0]
            binsz = loc[1] - loc[0]

            nB = numpy.cumsum(hist, dtype='int64')
            total = nB[-1]
            nF = total - nB

            # should't be a problem to start at zero. best_sigma should (by design) always be positive
            best_sigma = 0
            # set to loc[0], thresholds can be negative
            optimal_t = loc[0]

            for i in range(nbins):
                # get bin zero to the threshold 'i', then 'i' to nbins
                if ((ri[i+1] > ri[0]) and (ri[nbins] > ri[i+1])):
                    mean_b = numpy.mean(image[ri[ri[0]:ri[i+1]]], dtype='float64')
                    mean_f = numpy.mean(image[ri[ri[i+1]:ri[nbins]]], dtype='float64')
                    sigma_btwn = nB[i]*nF[i]*((mean_b - mean_f)**2)
                    if (sigma_btwn > best_sigma):
                        best_sigma = sigma_btwn
                        optimal_t = loc[i]

            threshold = optimal_t
            if Apply:
                mask = image > threshold
                return mask
            else:
                return threshold
            
