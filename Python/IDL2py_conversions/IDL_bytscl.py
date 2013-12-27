#! /usr/bin/env python

import numpy

def bytscl(array, Max=None, Min=None, Top=255, NaN=False):
    """
    Replicates the bytscl function available within IDL (Interactive Data Language, EXELISvis).
    Scales all values of array in the range (Min <= value <= Max) to (0 <= scl_value <= Top).

    :param array:
        A numpy array of any type.

    :param Max:
        The maximum data value to be considered. Otherwise the maximum data value of array is used.

    :param Min:
        The minimum data value to be considered. Otherwise the minimum data value of array is used.

    :param Top:
        The maximum value of the scaled result. Default is 255. The mimimum value of the scaled result is always 0.

    :param NaN:
        type Bool. If set to True, then NaN values will be ignored.

    :return:
        A numpy array of type byte (uint8) with the same dimensions as the input array.

    Example:

        >>> a = numpy.random.randn(100,100)
        >>> scl_a = bytscl(a)

    :author:
        Josh Sixsmith; joshua.sixsmith@ga.gov.au; josh.sixsmith@gmail.com

    :history:
       *  2013/10/24: Created

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

    if (Max == None):
        if (NaN):
            Max = numpy.nanmax(array)
        else:
            Max = numpy.amax(array)

    if (Min == None):
        if (NaN):
            Min = numpy.nanmin(array)
        else:
            Min = numpy.amin(array)

    if (Top > 255):
        Top = 255

    scl = array.copy()
    scl[scl >= Max] = Top
    scl[scl <= Min] = 0

    int_types = ['int', 'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64']
    flt_types = ['float', 'float16', 'float32', 'float64']

    if (array.dtype in int_types):
        rscl = numpy.floor(((Top + 1.) * (scl - Min) - 1.) / (Max - Min))
    elif (array.dtype in flt_types):
        rscl = numpy.floor((Top + 0.9999) * (scl - Min) / (Max - Min))
    else:
        raise Exception('Error! Unknown datatype. Supported datatypes are int8, uint8, int16, uint16, int32, uint32, int64, uint64, float32, float64.')

    # Check and account for any overflow that might occur during datatype conversion
    rscl[rscl >= Top] = Top
    rscl[rscl < 0] = 0
    scl = rscl.astype('uint8')
    return scl

