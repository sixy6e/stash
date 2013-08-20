import numpy as np

def rebin(a, (m, n)):
    """Downsizes a 2d array by averaging, new dimensions must be integral factors of original dimensions
    
    Credit: Tim http://osdir.com/ml/python.numeric.general/2004-08/msg00076.html"""                                                              
    M, N = a.shape
    ar = a.reshape((M/m,m,N/n,n))
    return np.sum(np.sum(ar, 3), 1) / float(m*n)

if __name__ =='__main__':
    import matplotlib.pyplot as plt
    array_100x100= np.arange(100) * np.arange(100)[:,None]
    array_10x10 = rebin(array_100x100, (10, 10))
    plt.figure()
    plt.contourf(array_100x100)
    plt.contourf(array_10x10)
    plt.colorbar()