#!/usr/bin/env python

import numpy
from osgeo import gdal
import luigi
from IDL_functions import hist_equal
import image_tools

"""
An example script that generates a series of images containing random values,
after which each image is then stretched via a histogram equalisation method.

The first case will be simple.  Create a random image and only output the
stretched version. The next phase will be to output the original as well.
That way we can create some sort of dependency and make use of the 'requires'
function.
"""

class createImages(luigi.Task):
    """
    A base class used to create a series of images containing random values.
    Image dimensions are strictly 1000x1000
    """

    # Maybe specify this to be an input parameter?
    #self.n_images = 100
    n_images = luigi.IntParameter(default=100)

    # Initialise the starting index of the output images
    self.index = 1

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

        # I don't think this will work for writing a GDAL compliant file
        # It more looks like something for writing raw text to disk.
        #fname = luigi.LocalTarget('image%04i' % (self.index))
        #self.index += 1
        #return fname

    def run(self):
        """
        Define the running mechanism. Basically the workflow for creating the images.
        """

        for i in range(self.n_images):
            fname = 'stretched_image%04i' %(i+1)
            img   = numpy.random.randn(1000,1000).astype('float32') # Purely for saving disk space

            #image_tools.write_img(array=img, name=fname)
            # For a simple example don't write the original image to disk

            h_eql = hist_equal(img)
            image_tools.write_img(array=h_eql, name=fname)

class CreateImage(luigi.Task):
    """
    
    """

    def requires(self):
        """
        
        """
        return None

    def run(self):
        """
        
        """
        return [numpy.random.randn(1000,1000).astype('float32')]

class ApplyStretch(luigi.Task):
    """
    
    """

    def requires(self):
        """
        
        """
        return [Createimage()]

    def run(self):
        """
        
        """
        return [hist_equal(self.input)]

class WriteImages(luigi.Task):
    """
    
    """

    n_images = luigi.IntParameter(default=10)

    def requires(self):
        """
        
        """
        return [ApplyStretch()]

    def run(self):
        """
        
        """

        for i in range(self.n_images):
            fname = 'stretched_image%04i' %(i+1)
            image_tools.write_img(array=self.input, name=fname)

if __name__ == '__main__':
    #luigi.run()
    luigi.build([WriteImages(n_images=5)], workers=1)
