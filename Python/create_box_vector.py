"""
Created on 14/03/2013

@author: Josh Sixsmith; joshua.sixsmith@ga.gov.au
"""

import ogr
import osr


def create_box(UL,LR, driver='ESRI Shapefile', layer_name='Layer', file_name='', projection='WGS84', UTM=None, South=False):
    if (len(file_name) == 0):
        file_name = 'output.shp'
    if (len(UL) != 2):
        raise Exception('Upper left must contain both longitude and lattitude!')
    if (len(LR) != 2):
        raise Exception('Lower right must contain both longitude and lattitude!')
        
    prj = osr.SpatialReference()
    prj.SetWellKnownGeogCS(projection)
    if UTM:
        prj.SetUTM(UTM, South)
    
    wkt = 'POLYGON((%f %f, %f %f, %f %f, %f %f, %f %f))' %(UL[0],UL[1],LR[0],UL[1],LR[0],LR[1],UL[0],LR[1],UL[0],UL[1])
    
    drv = ogr.GetDriverByName(driver)
    assert drv, '%s Is not a valid ogr Driver!' % driver
    outds = drv.CreateDataSource(file_name)
    layer   = outds.CreateLayer(layer_name, geom_type=ogr.wkbPolygon, srs=prj)
    feature = ogr.Feature(layer.GetLayerDefn())
    polygon = ogr.CreateGeometryFromWkt(wkt)
    feature.SetGeometry(polygon)
    layer.CreateFeature(feature)
    outds = None
    layer = None
    feature = None
    polygon = None
