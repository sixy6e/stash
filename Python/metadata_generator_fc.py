#! /usr/bin/env

import os
import sys
import re
import datetime

def get_size(start_path = '.'):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(start_path):
            for f in filenames:
                    fp = os.path.join(dirpath, f)
                    total_size += os.path.getsize(fp)
            return total_size

def img2map(geoTransform, pixel):
    '''Converts a pixel (image) co-ordinate into a map co-ordinate.

    '''

    mapx = pixel[1] * geoTransform[1] + geoTransform[0]
    mapy = geoTransform[3] - (pixel[0] * (numpy.abs(geoTransform[5])))
    return (mapx,mapy)


template = '''
<?xml version="1.0" encoding="UTF-8"?>
<EODS_DATASET xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
   <MDRESOURCE>
      <MDFILEID>{DirectoryName}</MDFILEID>
         <FILESIZE>{DirectorySize}</FILESIZE>
         <RESOLUTIONINMETRES>{Resolution}</RESOLUTIONINMETRES>
      <CONSTRAINTID>1</CONSTRAINTID>
      <RESOURCESTATUS>completed</RESOURCESTATUS>
      <KEYWORDS/>
      <TOPICCATEGORIES>environment</TOPICCATEGORIES>
      <CITATION>
         <TITLE/>
         <ALTERNATETITLE/>
         <DATE>{DateTime}</DATE>
         <DATETYPE>creation</DATETYPE>
         <EDITION/>
         <EDITIONDATE/>
         <ENTEREDBYRESPONSIBLEPARTY>
            <INDIVIDUALNAME>NEO Group</INDIVIDUALNAME>
            <ORGANISATIONNAME>Geoscience Australia</ORGANISATIONNAME>
            <POSITIONNAME>NEO Operations</POSITIONNAME>
            <ROLE>pointOfContact</ROLE>
         </ENTEREDBYRESPONSIBLEPARTY>
         <UPDATEDBYRESPONSIBLEPARTY>
            <INDIVIDUALNAME/>
            <ORGANISATIONNAME/>
            <POSITIONNAME/>
            <ROLE/>
         </UPDATEDBYRESPONSIBLEPARTY>
         <OTHERCITATIONDETAILS/>
      </CITATION>
      <MDSTANDARDNAME>GA Metadata Profile: A Geoscience Australia Profile of AS/NZS ISO 19115:2005, Geographic information - Metadata</MDSTANDARDNAME>
      <MDSTANDARDVERSION>1.0</MDSTANDARDVERSION>
      <PARENTID/>
      <DATALANGUAGE>eng</DATALANGUAGE>
      <MDCONTACT>
            <INDIVIDUALNAME>NEO Group</INDIVIDUALNAME>
            <ORGANISATIONNAME>Geoscience Australia</ORGANISATIONNAME>
            <POSITIONNAME>NEO Operations</POSITIONNAME>
         <ROLE>pointOfContact</ROLE>
      </MDCONTACT>
      <RESOURCETYPE>Processed Image</RESOURCETYPE>
      <CHARACTERSETCODE>usAscii</CHARACTERSETCODE>
      <ABSTRACT></ABSTRACT>
      <PURPOSE/>
      <CREDIT></CREDIT>
      <HIERARCHYLEVEL>dataset</HIERARCHYLEVEL>
      <HIERARCHYLEVELNAME>Satellite Imagery</HIERARCHYLEVELNAME>
      <ENVIRONMENTDESCRIPTION/>
      <SPATIALREPRESENTATIONTYPE/>
      <SUPPLEMENTARYINFORMATION>
              Fractional cover - Landsat, Joint Remote Sensing Research Program algorithm, Australian coverage. Processed by Geoscience Australia.

              The Fractional Cover algorithm utilises spectral bands 2,3,4,5,7 for either of the TM or ETM+ sensors. The spectral band inputs are sourced from the Australian Reflectance Grid 25m (ARG25); processed by Geoscience Australia. The bare soil, green vegetation and non-green vegetation endmenbers are calculated using models linked to an intensive field sampling program whereby more than 600 sites covering a wide variety of vegetation, soil and climate types were sampled to measure overstorey and ground cover following the procedure outlined in Muir et al (2011).

              Individual band information:
              PV: Green Cover Fraction. Fraction of green cover including green groundcover and green leaf material over all strata, within the Landsat pixel. Expressed as a percent * 10000.
              NPV: Non-green cover fraction. Fraction of non green cover including litter, dead leaf and branches over all strata, within the Landsat pixel. Expressed as a percent * 10000.
              BS: Bare ground fraction. Fraction of bare ground including rock, bare and disturbed soil, within the Landsat pixel. Expressed as a percent * 10000.
              UE: Unmixing Error. The residual error, defined as the Eclidean Norm of the Residual Vector. High values express less confidence in the fractional components.
      </SUPPLEMENTARYINFORMATION>
      <FORMAT>
         <FORMATNAME>GeoTIFF</FORMATNAME>
         <FORMATVERSION>1</FORMATVERSION>
      </FORMAT>
   </MDRESOURCE>
   <EXEXTENT>
      <COORDINATEREFERENCESYSTEM>{CoordRefSys_1}</COORDINATEREFERENCESYSTEM>
      <EXTENTTYPE/>
      <EXTENTDESCRIPTION/>
      <UL_LAT>{UL_LAT}</UL_LAT>
      <UL_LONG>{UL_LONG}</UL_LONG>
      <UR_LAT>{UR_LAT}</UR_LAT>
      <UR_LONG>{UR_LONG}</UR_LONG>
      <LR_LAT>{LR_LAT}</LR_LAT>
      <LR_LONG>{LR_LONG}</LR_LONG>
      <LL_LAT>{LL_LAT}</LL_LAT>
      <LL_LONG>{LL_LONG}</LL_LONG>
      <WEST_BLONG/>
      <EAST_BLONG/>
      <NORTH_BLAT/>
      <SOUTH_BLAT/>
      <TEMPORALEXTENTFROM>{TEMPORALEXTENTFROM}</TEMPORALEXTENTFROM>
      <TEMPORALEXTENTTO>{TEMPORALEXTENTTO}</TEMPORALEXTENTTO>
      <VERTICALEXTENTMAX/>
      <VERTICALEXTENTMIN/>
      <VERTICALEXTENTUOM/>
      <VERTICALEXTENTCRS/>
      <VERTICALEXTENTDATUM/>
      <SCENECENTRELAT>{SCENECENTRELAT}</SCENECENTRELAT>
      <SCENECENTRELONG>{SCENECENTRELONG}</SCENECENTRELONG>
      <TIMESERIESCOMPOSITINGINTERVAL/>
   </EXEXTENT>
   <MAINTAININFO>
      <MAINTAINFREQUENCY>notPlanned</MAINTAINFREQUENCY>
      <MAINTAINDATENEXT/>
      <USERDEFINEDFREQUENCYQSTARTTIME/>
      <USERDEFINEDFREQUENCYQENDTIME/>
      <MAINTAINSCOPE/>
      <UPDATESCOPEDESCRIPTION/>
      <MAINTAINNOTE/>
      <MAINTAINCONTACT>
         <INDIVIDUALNAME/>
         <ORGANISATIONNAME/>
         <POSITIONNAME/>
         <ROLE/>
      </MAINTAINCONTACT>
   </MAINTAININFO>
   <DATAQUALITY>
      <SCOPELEVEL>dataset</SCOPELEVEL>
      <SCOPELEVELDESCRIPTION/>
      <LINEAGE>
         <STATEMENT>Landcover fractions representing the proportions of green, non-green and bare cover retrieved by inverting multiple linear regression estimates and using synthetic endmembers in a constrained non-negative least squares unmixing model.</STATEMENT>
         <PROCESSINGSTEP>
            <ALGORITHMCITATION>
               <TITLE>Scarth, P., Roeder, A., and Schmidt, M., 2010, 'Tracking grazing pressure and climate interaction - the role of Landsat fractional cover in time series analysis' ,in Proceedings of the 15th Australasian Remote Sensing and Photogrammetry Conference, Alice Springs, Australia, 13-17 September 2010. Danaher, T., Scarth, P., Armston, J., Collet, L., Kitchen, J. & Gillingham, S. (2010). Remote sensing of tree-grass systems: The Eastern Australian Woodlands. In: Ecosystem Function in Savannas: Measurement and Modelling at Landscape to Global Scales, Eds. M.J. Hill and N.P. Hanan. CRC Press, Boca Raton. Muir, J., Schmidt, M., Tindall, D., Trevithick, R., Scarth, P. & Stewart, J.B. (2011). Field measurement of fractional ground cover: a technical handbook supporting ground cover monitoring for Australia, prepared by the Queensland Department of Environment and Resource Management for the Australian Bureau of Agricultural and Resource Economics and Sciences, Canberra, November.
               </TITLE>
               <EDITION/>
            </ALGORITHMCITATION>
         </PROCESSINGSTEP>
         <LINEAGESOURCE>
            <MDFILEID/>
            <SOURCERESOURCEID/>
            <SOURCECITATION>
               <TITLE/>
               <DATE/>
               <DATETYPE/>
               <ENTEREDBYRESPONSIBLEPARTY>
                  <INDIVIDUALNAME/>
                  <ORGANISATIONNAME/>
                  <POSITIONNAME/>
                  <ROLE/>
               </ENTEREDBYRESPONSIBLEPARTY>
            </SOURCECITATION>
            <DESCRIPTION>The Fractional cover algorithm uses ARG25 (Australian Reflectance Grid 25m) products.
              </DESCRIPTION>
            <SOURCEREFERENCESYSTEM/>
            <SOURCESCALE/>
            <SOURCESTEP/>
            <PROCESSINGLEVEL/>
         </LINEAGESOURCE>
      </LINEAGE>
      <DQELEMENT>
         <MEASURENAME/>
         <QUANTATIVEVALUE/>
         <QUANTATIVEVALUEUNIT/>
      </DQELEMENT>
   </DATAQUALITY>
   <IMAGEDESCRIPTION>
         <ILLUMINATIONELEVATIONANGLE>{ELEV_ANGLE}</ILLUMINATIONELEVATIONANGLE>
         <ILLUMINATIONELEVATIONAZIMUTH>{AZI_ANGLE}</ILLUMINATIONELEVATIONAZIMUTH>
         <VIEWINGINCIDENCEANGLEXTRACK>0</VIEWINGINCIDENCEANGLEXTRACK>
         <VIEWINGINCIDENCEANGLELONGTRACK>0</VIEWINGINCIDENCEANGLELONGTRACK>
         <CLOUDCOVERPERCENTAGE>{ACCA_CLOUD}</CLOUDCOVERPERCENTAGE>
      <CLOUDCOVERDETAILS/>
      <SENSOROPERATIONMODE/>
      <BANDGAIN/>
      <BANDSAVAILABLE>PV,NPV,BS,UE</BANDSAVAILABLE>
         <SATELLITEREFERENCESYSTEM_X></SATELLITEREFERENCESYSTEM_X>
         <SATELLITEREFERENCESYSTEM_Y></SATELLITEREFERENCESYSTEM_Y>
      <IMAGECONDITION/>
      <PROCESSINGTYPECD>Fractional Cover</PROCESSINGTYPECD>
      <BEARING/>
   </IMAGEDESCRIPTION>
   <BROWSEGRAPHIC>
      <FILENAME>{Browse_Filename}</FILENAME>
      <FILEDESCRIPTION>Color JPEG Image</FILEDESCRIPTION>
      <FILETYPE>JPG</FILETYPE>
      <SAMPLEPIXELRESOLUTION/>
      <BLUEBAND>NPV</BLUEBAND>
      <GREENORGREYBAND>PV</GREENORGREYBAND>
      <REDBAND>BS</REDBAND>
   </BROWSEGRAPHIC>
   <ACQUISITIONINFORMATION>
      <PLATFORMNAME>{PLATFORMNAME}</PLATFORMNAME>
      <INSTRUMENTNAME>{INSTRUMENTNAME}</INSTRUMENTNAME>
      <INSTRUMENTYPE>Multi-spectral</INSTRUMENTYPE>
      <MISSIONNAME/>
      <EVENT>
         <TIME/>
         <AOS/>
         <LOS/>
         <ORBITNUMBER></ORBITNUMBER>
         <CYCLENUMBER/>
         <PASSSTATUS/>
         <NUMBERSCENESINPASS/>
         <COLLECTIONSITE></COLLECTIONSITE>
         <ANTENNA/>
         <HEADING></HEADING>
         <SEQUENCE/>
         <TRIGGER/>
         <CONTEXT/>
      </EVENT>
   </ACQUISITIONINFORMATION>
   <GRIDSPATIALREPRESENTATION>
           <NUMBEROFDIMENSIONS>2</NUMBEROFDIMENSIONS>
           <TRANSFORMATIONPARAMETERAVAILABILITY>1</TRANSFORMATIONPARAMETERAVAILABILITY>
           <CELLGEOMETRY>area</CELLGEOMETRY>
      <DIMENSION_X>
         <NAME>sample</NAME>
         <SIZE>{SAMPLES}</SIZE>
         <RESOLUTION>{RESOLUTION}</RESOLUTION>
      </DIMENSION_X>
      <DIMENSION_Y>
         <NAME>line</NAME>
         <SIZE>{LINES}</SIZE>
         <RESOLUTION>{RESOLUTION}</RESOLUTION>
      </DIMENSION_Y>
      <GEORECTIFIED>
         <CHECKPOINTAVAILABILITY/>
         <CHECKPOINTDESCRIPTION/>
         <POINTINPIXEL>upperLeft</POINTINPIXEL>
         <GEOREFULPOINT_X>{UL_X}</GEOREFULPOINT_X>
         <GEOREFULPOINT_Y>{UL_Y}</GEOREFULPOINT_Y>
         <GEOREFULPOINT_Z/>
         <GEOREFURPOINT_X>{UR_X}</GEOREFURPOINT_X>
         <GEOREFURPOINT_Y>{UR_Y}</GEOREFURPOINT_Y>
         <GEOREFURPOINT_Z/>
         <GEOREFLLPOINT_X>{LL_X}</GEOREFLLPOINT_X>
         <GEOREFLLPOINT_Y>{LL_Y}</GEOREFLLPOINT_Y>
         <GEOREFLLPOINT_Z/>
         <GEOREFLRPOINT_X>{LR_X}</GEOREFLRPOINT_X>
         <GEOREFLRPOINT_Y>{LR_Y}</GEOREFLRPOINT_Y>
         <GEOREFLRPOINT_Z/>
         <CENTREPOINT_X/>
         <CENTREPOINT_Y/>
      <ELLIPSOID>{ELLIPSOID}</ELLIPSOID>
      <DATUM>{DATUM}</DATUM>
      <PROJECTION>{PROJECTION}</PROJECTION>
      <ZONE>{ZONE}</ZONE>
         <COORDINATEREFERENCESYSTEM>{CoordRefSys_2}</COORDINATEREFERENCESYSTEM>
      </GEORECTIFIED>
   </GRIDSPATIALREPRESENTATION>
</EODS_DATASET>
'''

iobj = gdal.Open(f)
samples = iobj.RasterXSize
lines = iobj.RasterYSize
geot = iobj.GetGeoTransform()

img_prj = osr.SpatialReference()
img_prj.ImportFromWkt(iobj.GetProjection())
pretty_prj = img_prj.ExportToPrettyWkt()
split_prj = pretty_prj.split('\n')

find = split_prj[0].find('"')
find2 = split_prj[0].find('"',find+1)
CoordRefSys_2 = split_prj[0][find+1:find2]

find = split_prj[1].find('"')
find2 = split_prj[1].find('"',find+1)
DATUM = split_prj[1][find+1:find2]

find = split_prj[3].find('"')
find2 = split_prj[3].find('"',find+1)
ELLIPSOID = split_prj[3][find+1:find2]

ZONE = numpy.abs(set_prj.GetUTMZone())

find = re.search('MGA', CoordRefSys_2)
if find != None:
    PROJECTION = find.group()
else:
    PROJECTION = 'UNKNOWN'

# The satellite name and sensor can be retrieved from the directory name
DirectoryName = os.path.dirname(os.path.abspath(f)).split('/')[-2]
DirectorySize = numpy.round(get_size(os.path.dirname(os.path.abspath(f)))/1024./1024.)
Resolution = geot[1]
RESOLUTION = geot[1]
Browse_Filename = DirectoryName + '.jpg'

satellite = {'LS5':'Landsat-5', 'LS7':'Landsat-7'}
sensor = {'TM':'TM', 'ETM':'ETM+'}
PLATFORMNAME = satellite[DirectoryName.split('_')[0]]
INSTRUMENTNAME = sensor[DirectoryName.split('_')[1]]

# bounding co-ordinates
bounding_box = []
bounding_box.append(img2map(geot, pixel=(0,0))) # UL
bounding_box.append(img2map(geot, pixel=(0,samples))) # UR
bounding_box.append(img2map(geot, pixel=(lines,samples))) # LR
bounding_box.append(img2map(geot, pixel=(lines,0))) # LL
bounding_box.append(img2map(geot, pixel=(lines/2.,samples/2.))) # Centre

UL_X = bounding_box[0][0]
UL_Y = bounding_box[0][1]
UR_X = bounding_box[1][0]
UR_Y = bounding_box[1][1]
LR_X = bounding_box[2][0]
LR_Y = bounding_box[2][1]
LL_X = bounding_box[3][0]
LL_Y = bounding_box[3][1]

centre_x = bounding_box[4][0]
centre_y = bounding_box[4][1]

box_coords = []
for corner in bounding_box:
    box_coords.append(corner[0])
    box_coords.append(corner[1])

# Retrieve the image bounding co-ords and create a vector geometry set
if type(box_coords[0]) == int:
    box_wkt = 'MULTIPOINT(%d %d, %d %d, %d %d, %d %d, %d %d)' %(box_coords[0],box_coords[1],box_coords[2],box_coords[3],box_coords[4],box_coords[5],box_coords[6],box_coords[7], box_coords[8], box_coords[9])
else:
    box_wkt = 'MULTIPOINT(%f %f, %f %f, %f %f, %f %f, %f %f)' %(box_coords[0],box_coords[1],box_coords[2],box_coords[3],box_coords[4],box_coords[5],box_coords[6],box_coords[7], box_coords[8], box_coords[9])

# Create the vector geometry set and transform the co-ords
wgs_ref = osr.SpatialReference()
wgs_ref.SetWellKnownGeogCS('WGS84')
box_geom = ogr.CreateGeometryFromWkt(box_wkt)
tform    = osr.CoordinateTransformation(img_prj, wgs_ref)
box_geom.Transform(tform)

new_box = []
for p in range(box_geom.GetGeometryCount()):
    point = box_geom.GetGeometryRef(p)
    new_box.append(point.GetPoint_2D())

UL_LAT  = new_box[0][1]
UL_LONG = new_box[0][0]
UR_LAT  = new_box[1][1]
UR_LONG = new_box[1][0]
LR_LAT  = new_box[2][1]
LR_LONG = new_box[2][0]
LL_LAT  = new_box[3][1]
LL_LONG = new_box[3][0]

centre_x_lat  = new_box[4][1]
centre_y_long = new_box[4][0]

# file datetime
DateTime = '%s' %datetime.datetime.fromtimestamp(os.path.getmtime(f))


template = template.format(DirectoryName=, DirectorySize=, Resolution=, DateTime=, CoordRefSys_1=, UL_LAT=, UL_LONG=, UR_LAT=, UR_LONG=, LR_LAT=, LR_LONG=, LL_LAT=, LL_LONG=, TEMPORALEXTENTFROM=, TEMPORALEXTENTTO=, SCENECENTRELAT=, SCENECENTRELONG=, Browse_Filename=, ELEV_ANGLE=, AZI_ANGLE=, SAMPLES=, LINES=, RESOLUTION=, ACCA_CLOUD=, PLATFORMNAME=, INSTRUMENTNAME=, ELLIPSOID=, DATUM=, PROJECTION=, ZONE=, CoordRefSys_2=, UL_X=, UL_Y=, UR_X=, UR_Y=, LL_X=, LL_Y=, LR_X=, LR_Y=)










