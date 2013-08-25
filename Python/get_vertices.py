"""
Created on 28/11/2011

@author: u08087
"""
# Only returns lat and long, not elevation coords

import numpy

def get_vertices(ring):
    longitude = []
    lattitude = []
    elevation = []
    points = ring.GetPointCount()
    for p in xrange(points):
        lon, lat, z = ring.GetPoint(p)
        longitude.append(lon)
        lattitude.append(lat)
        elevation.append(z)
    longitude = numpy.asarray(longitude)
    lattitude = numpy.asarray(lattitude)
    elevation = numpy.asarray(elevation)
    #print longitude
    #return long, latt, elev
    #if 3D == 0:
    #    return longitude, lattitude
    #else:
    #    return longitude, lattitude, elevation
    #return longitude, lattitude, elevation
    return longitude, lattitude
    
