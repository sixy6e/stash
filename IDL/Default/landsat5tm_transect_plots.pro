pro landsat5TM_transect_plots

;will create plots of the transects created in envi for all bands, not just the ones loaded into the image
;i use the arbitrary profile (transect) tool then save the data (not the plot) to an ascii file selecting all
;bands

;set the in and out directories
in_dir='D:\Data\Imagery\Temporary\PC_IC\Plots'
out_dir='D:\Data\Imagery\Temporary\PC_IC'

;change the in and out directories as needed
;make sure files have an underscore at the end of it, just convention but not necessary
;this was just to help separate plots that were of the same landcover
;ie corn_1, corn_2

cd, out_dir

;restore the ascii template so you don't have to do it by hand, change the directory to wherever you saved
;the .sav file
;it will work if you have saved the transects to ascii
RESTORE, 'D:\Data\ENVI_Workspace\sav\myLandsat5TransectTemplate.sav'

files=FILE_SEARCH(in_dir,'*',COUNT=numfiles)

counter=0

While(counter LT numfiles) DO BEGIN
name=files(counter)
extension= name + '.jpg'
FullName=FILE_BASENAME(name)
underScore=STRPOS(FullName,'_', /REVERSE_SEARCH)
extract=STRMID(FullName,0,underScore)
PlotTitle=STRUPCASE(extract)
transect=READ_ASCII(name,TEMPLATE=Landsat5TransectTemplate)
iPLOT, transect.Point, transect.Band_1, COLOR=[0,0,255], VIEW_TITLE=PlotTitle, Name='Band 1', /INSERT_LEGEND

;moving the legend
idTool = IGETCURRENT(TOOL=oTOOL)
legendID= oTool->FindIdentifiers('*legend*', /ANNOTATION)
legendOBJ = oTool->GetByIdentifier(legendID[0])
legendOBJ->Select
iTRANSLATE, 'legend', X=70, Y=-100

iPLOT, transect.Point, transect.Band_2, COLOR=[0,255,0], Name='Band 2', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Band_3, COLOR=[255,0,0], Name='Band 3', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Band_4, COLOR=[0,255,255], Name='Band 4', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Band_5, COLOR=[255,0,255], Name='Band 5', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Band_6, COLOR=[200,100,50], Name='Band 6', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Band_7, COLOR=[0,0,0], Name='Band 7', /INSERT_LEGEND, /OVERPLOT

iSAVE, extension

;append ';' to the front of idelete if you want the plot to stay open
;iDELETE, iPLOT

Counter=counter +1

ENDWHILE

END