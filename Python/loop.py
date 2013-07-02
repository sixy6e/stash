weight_sum = ((image[0] + image[1] + image[2] + image[3]) +
                        2*(image[4] + image[6]))

if ACCA == None:
    statsfile = open('ACCA_Shadow_stats.txt', 'w')
    statsfile.write('Cutoff, Skewness, Kurtosis\n')
else:
    statsfile = open('Fmask_Shadow_stats.txt', 'w')
    statsfile.write('Cutoff, Skewness, Kurtosis\n')

for x in [0.8, 0.9, 1.0, 1.1, 1.2]:
    wsumc = weight_sum.copy().flatten()
    wsumc[(wsumc < 0) | (wsumc > x-0.1)] = -99
    bins = numpy.arange(x*10)/10.
    digb = numpy.digitize(wsumc, bins=bins)
    digbu = numpy.unique(digb)
    del wsumc
    flatwsum = weight_sum.flatten()
    binmean = numpy.zeros(bins.shape)
    binstdv = numpy.zeros(bins.shape)
    for i in digbu[digbu > 0]:
        binmean[i-1] = numpy.mean(flatwsum[digb == i])
        binstdv[i-1] = numpy.std(flatwsum[digb == i])
    limit = binstdv * 2.5
    upper = binmean + limit
    lower = binmean - limit
    del binmean, binstdv
    grown_regions = numpy.zeros(dims, dtype='bool').flatten()
    flatmask = (flatwsum >= lower.min()) & (flatwsum <= upper.max())
    mask = flatmask.reshape(dims)
    label_array, num_labels = ndimage.label(mask, structure=s)
    flat_label = label_array.flatten()
    labels = label_array[sindex]
    ulabels = numpy.unique(labels[labels > 0])
    find_lab = numpy.in1d(flat_label, ulabels)
    grown_regions |= find_lab
    del find_lab, ulabels, labels, flat_label, label_array, num_labels
    del mask, flatmask, 
    cshadow = grown_regions.reshape(dims)
    cshadow[cindex] = 0
    if sea_mask != None:
        sea = sea_mask == 0
        cshadow[sea] = 0
        del sea
    if null_mask != None:
        null = null_mask == 0
        cshadow[null] = 0
        del null
    skew = stats.skew(weight_sum[cshadow == 1])
    kurt = stats.kurtosis(weight_sum[cshadow == 1])
    n = numpy.sum(cshadow, dtype='float')
    ses = numpy.sqrt((6*n*(n-1))/((n-2)*(n+1)*(n+3)))
    stest = stats.skewtest(weight_sum[cshadow ==1])

    statsfile.write('%g\t%f\t%f\t%f\t%f\n' %(x, skew, kurt, ses, stest))

statsfile.close()
