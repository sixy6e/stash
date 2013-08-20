#! /usr/bin/env python

import os
import numpy
from osgeo import gdal
import ogr
import osr
import pdb

def TopographicShadow(image, img_geoT, img_prj, DEM, metafile, bitpos=14):
    '''Creates a 2D array of topographic shadow.

       Executes "gdaldem hillshade" from the command line.

       Args:
           image: either a multiband or single band ndarray.
           img_geoT: The geo-transformation co-ordinates of the image.
           img_prj: The projection information of the image.
           DEM: A string file path to the location of the Digital Elevation
                Model that is to be used for surface topography.
           metafile: Either a full file path string name of the metadata file,
                     or a dictionary containing the relevant parameters
                     (Sun azimuth and elevation).
           bitpos: The bit position for specifying the resulting mask (Default
                   value is 14).

       Returns:
           An ndarray with 1 for no shadow and 0 for shadow specified by the
           bit position.

    '''

    def img2map(geoTransform, pixel):
        '''Converts a pixel (image) co-ordinate into a map co-ordinate.

        '''

        mapx = pixel[1] * geoTransform[1] + geoTransform[0]
        mapy = geoTransform[3] - (pixel[0] * (numpy.abs(geoTransform[5])))
        return (mapx,mapy)

    def map2img(geoTransform, location):
        '''Converts a map co-ordinate into a pixel (image) co-ordinate.

        '''

        imgx = int(numpy.round((location[0] - geoTransform[0])/geoTransform[1]))
        imgy = int(numpy.round((geoTransform[3] - location[1])/numpy.abs(geoTransform[5])))
        return (imgy,imgx)


    # Returns the required line from a list of strings
    def linefinder(array, string = ""):
        '''Searches a list for the specified string.

           Args:
               array: A list containing searchable strings.
               string: User input containing the string to search.

           Returns:
               The line containing the found sting.
        '''

        for line in array:
            if string in str(line):
                return line


    # Reads the metadata file in order to extract the needed parameters
    def read_metafile(metafile):
        '''Opens the metadata file and extracs relevant parameters.

           Args:
               metafile: A full string path name to the metadata file.

           Returns:
               Dictionary containing the parameters.
        '''

        f         = open(metafile, 'r')
        met_array = f.readlines()
        f.close()

        sfind   = linefinder(met_array, 'SUN_AZIMUTH')
        s_azi   = float(sfind.split()[2])
        sfind   = linefinder(met_array, 'SUN_ELEVATION')
        s_elev  = float(sfind.split()[2])



        params = {
                     'Sun_Azimuth'      : s_azi,
                     'Sun_Elevation'    : s_elev,
                 }

        return params



#--------------Processing Here-------------------------------

    box = []
    co_ords = []

    img_ref = osr.SpatialReference()
    dem_ref = osr.SpatialReference()
    img_ref.ImportFromWkt(img_prj)

    dims = image.shape
    if len(dims) >2:
        ncols = dims[2]
        nrows = dims[1]
        dims  = (nrows,ncols)

    box.append(img2map(geoTransform=img_geoT, pixel=(0,0))) # UL
    box.append(img2map(geoTransform=img_geoT, pixel=(0,dims[1]))) #UR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],dims[1]))) #LR
    box.append(img2map(geoTransform=img_geoT, pixel=(dims[0],0))) # LL

    for corner in box:
        co_ords.append(corner[0])
        co_ords.append(corner[1])

    if os.path.isfile(DEM):
        dem_obj = gdal.Open(DEM, gdal.gdalconst.GA_ReadOnly)
        assert dem_obj
        dem_prj  = dem_obj.GetProjection()
        dem_geoT = dem_obj.GetGeoTransform()
        dem_ref.ImportFromWkt(dem_prj)
        dem_cols = dem_obj.RasterXSize
        dem_rows = dem_obj.RasterYSize
    else:
        raise Exception('DEM needs to be a string pathname to a valid file')

    # Retrieve the image bounding co-ords and create a vector geometry set
    if type(co_ords[0]) == int:        
        wkt = 'MULTIPOINT(%d %d, %d %d, %d %d, %d %d)' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])
    else:
        wkt = 'MULTIPOINT(%f %f, %f %f, %f %f, %f %f)' %(co_ords[0],co_ords[1],co_ords[2],co_ords[3],co_ords[4],co_ords[5],co_ords[6],co_ords[7])

    # Create the vector geometry set and transform the co-ords to match
    # the DEM file
    box_geom = ogr.CreateGeometryFromWkt(wkt)
    tform    = osr.CoordinateTransformation(img_ref, dem_ref)
    box_geom.Transform(tform)

    new_box = []
    for p in range(box_geom.GetGeometryCount()):
        point = box_geom.GetGeometryRef(p)
        new_box.append(point.GetPoint_2D())
        
    
    x = []
    y = []
    for c in new_box:
        x.append(c[0])
        y.append(c[1])

    xmin = numpy.min(x)
    xmax = numpy.max(x)
    ymin = numpy.min(y)
    ymax = numpy.max(y)
    
    print x
    print y
    print xmin
    print xmax
    print ymin
    print ymax


    # Retrieve the image co_ords of the DEM
    UL = map2img(geoTransform=dem_geoT, location=new_box[0])
    UR = map2img(geoTransform=dem_geoT, location=new_box[1])
    LR = map2img(geoTransform=dem_geoT, location=new_box[2])
    LL = map2img(geoTransform=dem_geoT, location=new_box[3])

    # Compute the offsets in order to read only the portion of the DEM that
    # covers the extents of the image file.
    cx    = numpy.array([UL[1],UR[1],LR[1],LL[1]])
    cy    = numpy.array([UL[0],UR[0],LR[0],LL[0]])
    cxmin = int(numpy.min(cx))
    cxmax = int(numpy.max(cx))
    cymin = int(numpy.min(cy))
    cymax = int(numpy.max(cy))
    xoff  = cxmin
    yoff  = cymin
    xsize = cxmax - cxmin
    ysize = cymax - cymin 
    
    print xoff
    print yoff
    print xsize
    print ysize
    
    '''
    xoff  = UL[1]
    yoff  = UL[0]
    xsize = LR[1] - UL[1]
    ysize = LR[0] - UL[0]
    '''
    #pdb.set_trace()
    # Test if the number of columns and rows to read exceeds the DEM extents.
    if (xoff > dem_cols) | (yoff > dem_rows):
        return 'Topo Shadow not performed; Image has no assocciated DEM.'
    else:
        if xoff + xsize > dem_cols:
            xsize = dem_cols - xoff

        if yoff + ysize > dem_rows:
            ysize = dem_rows - yoff

        # Need to read in the subset image then create a gdal memory object
        dem_arr = dem_obj.ReadAsArray(xoff, yoff, xsize, ysize)
        print dem_arr[3000,4200]
        
        #dem_subs_geoT = (new_box[0][0],dem_geoT[1],0.0,new_box[0][1],0.0,dem_geoT[5])
        dem_subs_geoT = (xmin,dem_geoT[1],0.0,ymin,0.0,dem_geoT[5])
        
        #memdriver = gdal.GetDriverByName("MEM")
        driver = gdal.GetDriverByName("GTiff")
        #memdem = memdriver.Create("", dem_arr.shape[1], dem_arr.shape[0], 1, gdal.GDT_Float32)
        dumdem = driver.Create("subsDEMtest.tif", dem_arr.shape[1], dem_arr.shape[0], 1, gdal.GDT_Float32)
        #memdem.SetGeoTransform(dem_subs_geoT)
        dumdem.SetGeoTransform(dem_subs_geoT)
        #memdem.SetProjection(dem_prj)
        dumdem.SetProjection(dem_prj)
        #outband = memdem.GetRasterBand(1)
        outband = dumdem.GetRasterBand(1)
        outband.WriteArray(dem_arr)
        dumdem = None

        '''
        # As of gdal v. 1.8 there is no hillshade python method
        # Therefore writeout the projected dem file and compute the hillshade
        # from the command line.
        d_name = 'Projected_DEM_new_dims.tif'
        driver = gdal.GetDriverByName("GTiff")
        
        #outds  = driver.Create(d_name, dims[1], dims[0],1, gdal.GDT_Float32)
        outds  = driver.Create(d_name, xsize, ysize,1, gdal.GDT_Float32)
        #outds.SetGeoTransform(img_geoT)
        outds.SetGeoTransform(dem_subs_geoT)
        
        outds.SetProjection(img_prj)
        #outband = outds.GetRasterBand(1)
        #outband.WriteArray(dem_arr)

        proj = gdal.ReprojectImage(memdem, outds, None, None, gdal.GRA_Bilinear)
        memdem = None
        del memdem

        outds = None
        '''
        '''
        #dem_arr = outds.ReadAsArray()

        if (type(metafile) != dict): # Is an actual file in which case read it.
            parameters = read_metafile(metafile)
            elev       = parameters['Sun_Elevation']
            azi        = parameters['Sun_Azimuth']

        else: # The metafile is a dictionary
            elev = metafile['Sun_Elevation']
            azi  = metafile['Sun_Azimuth']

        hill_name = 'hillshade.tiff'
        command = "gdaldem hillshade %s %s -az %f -alt %f" %(d_name, hill_name, azi, elev)

        os.system(command)

        # Read in the hillshade image
        hobj = gdal.Open(hill_name, gdal.gdalconst.GA_ReadOnly)
        h_array = hobj.ReadAsArray()

        # Threshold the hillshade image
        topo_shad = h_array <= 170
        topo_shad = (~(topo_shad) << bitpos).astype('uint16')

        return topo_shad
        '''
