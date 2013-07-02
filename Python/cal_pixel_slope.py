#! /usr/bin/env python

import numpy

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

'''
This routine needs the solar azimuth, view azimuth, solar zenith, view zenith angles.  Will need to take the code from NBAR to duplicate these rasters.
As these rasters are calculated for the extents of the landsat raster; The DEM
will need to be projected to the landsat grid. However as a buffer is needed
for the cast shadow calculation, will need to create a dummy image that 
contains the buffer. The projection info will be extracted from the landsat
file, but the geotransform info will be created. This dummy image will be used
as a base from which the DEM will be projected to. This should ensure that the
DEM will match up pixel by pixel with the landsat file.

Potentially, the DEM will have No-Data values, eg -32767.00. When projecting in
python, you can't (at the time of writing this, 02/08/2012) specify a data 
ignore value in the interpolation method. A way around this is to find any 
values less than -500m, and set them to zero. The algorithms created by Fuqin
don't really account for negative values. So for large negative values, the
algorithm could be searching outside the buffer extent. Anything less than -500
should be sufficient engouh to not include real features that are below sea
level, eg Lake Eyre.
'''


def cal_pole(zenith, azimuth, slope, aspect):

    '''
      The zenith argument is not necessarily the zenith. The first call to this
      function will be solar_zenith, solar_azimuth, slope & aspect. The second
      call to this function is the sensor_view_angle, sensor_azimuth, slope &
      aspect.
    '''

    ierr=0.0
    offset=0.0
    eps= 0.000001
    pi = numpy.pi

    offset = numpy.arctan(numpy.tan(pi - numpy.radians(aspect)) * numpy.cos(numpy.radians(slope)))
    pdiff = numpy.radians(azimuth - aspect)
    
    costhp = numpy.cos(numpy.radians(zenith)) * numpy.cos(numpy.radians(slope)) + numpy.sin(numpy.radians(zenith)) * numpy.sin(numpy.radians(slope)) * numpy.cos(pdiff)
    
    thp = numpy.degrees(numpy.arccos(costhp))
    sinphp = numpy.sin(numpy.radians(zenith)) * numpy.sins(pdiff) / numpy.sin(numpy.radians(thp))
    cosphp = (numpy.cos(numpy.radians(zenith)) * numpy.sin(numpy.radians(slope)) - numpy.sin(numpy.radians(zenith)) * numpy.cos(numpy.radians(slope)) * numpy.cos(pdiff)) / numpy.sin(numpy.radians(thp))
    
    tnum = numpy.sin(numpy.radians(zenith)) * numpy.sin(pdiff)
    tden = (numpy.cos(numpy.radians(zenith)) * numpy.sin(numpy.radians(slope)) - numpy.sin(numpy.radians(zenith)) * numpy.cos(numpy.radians(slope)) * numpy.cos(pdiff))
    php = numpy.degrees(numpy.arctan2(tnum, tden) - offset)
    
    # the fortran stuff had checks that returned default values for php and thp.
    # These are applied at the end as we are dealing with arrays. Pixels will be
    # calculated on the way through, but revert back to a defaulted value if
    # certain conditions are met.
    query = numpy.abs(slope) <= eps
    thp[query] = zenith[query] # check small eg in python to see if this works
    php[query] = azimuth[query]
    
    query = costhp >= (1.0 - eps)
    thp[query] = 0.0
    php[query] = 0.0 - numpy.degrees(offset)
    
    query = numpy.abs(sinphp) <= eps
    php[query] = numpy.degrees(180.0 - offset)
    query = ((numpy.abs(sinphp) <= eps) & (cosphp > eps))
    php[query] = numpy.degrees(0.0 - offset)

    query = numpy.abs(cosphp) <= eps
    php[query] = numpy.degrees(-90.0 - offset)
    query = ((numpy.abs(cosphp) <= eps) & (sinphp > eps))
    php[query] = numpy.degrees(90.0 - offset)
        
    query = php > 180.0
    php[query] += - 360.0
    query = php < 180.0
    php[query] +=  360.0

    return thp, php, ierr, offset

# Fortran input order (not including header and DEM)
# inputs required: solar_zenith, sensor_view_angle, view_azimuth, solar_azimuth
# fortran names: solar, view, solar_azimuth, view_azimuth

# Python input (different order to above)
#          solar_zenith, solar_azimuth, sensor_view_angle, view_azimuth
# named inputs: sol_zen, sol_azi, sensor_view_angle, sensor_view_azi


# assuming we have a projected DEM called dem_arr
slope, aspect = slope_aspect(dem_arr, pix_size)

landsat_dims
# subset the slope and aspect rasters based on the landsat extents
slope = subset(slope)
aspect = subset(aspect)

incident_t, azi_incident_t, sol_ierr, sol_offest = cal_pole(sol_zen, sol_azi, slope, aspect)

exiting_t, azi_exiting_t, view_ierr, view_offest = cal_pole(sensor_view_angle, sensor_view_azi, slope, aspect)

rela = azi_incident_t - azi_exiting_t
rela[rela <= -180.0] += 360.0
rela[rela > 180.0] -= 360.0

query = numpy.cos(numpy.radians(incident_t)) <= 0.0
sub_mask[query] = 0
incident_t[query] = 90

query = numpy.cos(numpy.radians(exiting_t)) <= 0.0
sub_mask[query] = 0
exiting_t[query] = 90
