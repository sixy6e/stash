#! /usr/bin/env python

import numpy
import osr

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

def select_earth_radius(ellipsoid):
    '''Selects earth radius corresponding to the reference ellipsoid

       Args:
           ellipsoid: The reference ellipsoid as a string.

       Returns:
           Earth radius in metres as a floating point.

       Note:
           These values taken from:
           http://en.wikipedia.org/wiki/Reference_ellipsoid
           Will have to be adapted to whatever codes are used to describe these
           ellipsoids.
           New ellipsoids can be added as the need arises.

    '''

    elip = ellipsoid
    return {
           'Airy 1830'   : 6377563.4,
           'Clarke 1866' : 6378206.4,
           'Bessel 1841' : 6377397.155,
           'International 1924' : 6378388,
           'Krasovsky 1940' : 6378245,
           'GRS80' : 6378137,
           'WGS84' : 6378137,
           }.get(elip, 6371000)

rlat = omapy
rlon = omapx

#R = select_earth_radius(ellipsoid)
sr = osr.SpatialReference()
sr.ImportFromWkt(img_prj)
R = sr.GetSemiMajor()
# to determine if projected
sr.IsProjected() # return 1 if True
# to determine if geographic
sr.IsGeographic() # return 1 if True

d = shadow_length

rlat2 = numpy.asin( numpy.sin(rlat)*numpy.cos(d/R) + numpy.cos(rlat)*numpy.sin(d/R)*numpy.cos(to_azi) )

rlon2 = rlon + numpy.atan2(numpy.sin(to_azi)*numpy.sin(d/R)*numpy.cos(rlat),numpy.cos(d/R)-numpy.sin(rlat)*numpy.sin(rlat))

rlat2 = numpy.deg2rad(rlat2)
rlon2 = numpy.deg2rad(rlon2)


