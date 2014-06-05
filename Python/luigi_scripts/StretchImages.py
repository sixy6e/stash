#!/usr/bin/env python

import numpy
from osgeo import gdal
import luigi
from IDL_Functions import hist_equal
import image_tools

"""
An example script that generates a series of images containing random values,
after which each image is then stretched via a histogram equalisation method.
"""

class createImages(luigi.Task):
    """
    A base class used to create a series of images containing random values.
    Image dimensions are strictly 1000x1000
    """

    # Maybe specify this to be an input parameter?
    self.n_images = 100

    def requires(self):
        """
        Define any requirements.
        None.
        """
        return None

    def outputs(self):
        """
        Define any outputs.
        The images will be the output.
        """

    def run(self):
        """
        Define the running mechanism. Basically the workflow for creating the images.
        """

        for i in range(self.n_images):
            fname = 'image%04i' %(i+1)
            img   = numpy.random.randn(1000,1000).astype('float32') # Purely for saving disk space
            #image_tools.write_img(array=img, name=fname)
            # For a simple example don't write the original image to disk
            h_eql = hist_equal(img)
            image_tools.write_img(array=h_eql, name=fname)

#class
