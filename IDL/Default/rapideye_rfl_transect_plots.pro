pro RapidEye_RFL_transect_plots

;will create plots of the transects created in envi for all bands, not just the ones loaded into the image
;i use the arbitrary profile (transect) tool then save the data (not the plot) to an ascii file selecting all
;bands

;set the in and out directories
in_dir='D:\Data\Classifications\2011_01_CIA\redo\Transects'
out_dir='D:\Data\Classifications\2011_01_CIA\redo\Plots'

;change the in and out directories as needed
;make sure files have an underscore at the end of it, just convention but not necessary
;this was just to help separate plots that were of the same landcover
;ie corn_1, corn_2

cd, out_dir

;restore the ascii template so you don't have to do it by hand, change the directory to wherever you saved
;the .sav file
;it will work if you have saved the transects to ascii
RESTORE, 'D:\Data\ENVI_Workspace\sav\myRFL_RapidEyeTransectTemplate.sav'

files=FILE_SEARCH(in_dir,'*',COUNT=numfiles)

counter=0

While(counter LT numfiles) DO BEGIN
name=files(counter)
;extension variable un-needed
;extension= name + '.jpg'
FullName=FILE_BASENAME(name)
out_name= out_dir + '\' + FullName + '.jpg'
underScore=STRPOS(FullName,'_', /REVERSE_SEARCH)
extract=STRMID(FullName,0,underScore)
PlotTitle=STRUPCASE(extract)
transect=READ_ASCII(name,TEMPLATE=RapidEyeTransectTemplate)
iPLOT, transect.Point, transect.Blue, COLOR=[0,0,255], VIEW_TITLE=PlotTitle, Name='Blue', /INSERT_LEGEND

;moving the legend
idTool = IGETCURRENT(TOOL=oTOOL)
legendID= oTool->FindIdentifiers('*legend*', /ANNOTATION)
legendOBJ = oTool->GetByIdentifier(legendID[0])
legendOBJ->Select
iTRANSLATE, 'legend', X=70, Y=-100

iPLOT, transect.Point, transect.Green, COLOR=[0,255,0], Name='Green', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Red, COLOR=[255,0,0], Name='Red', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Red_Edge, COLOR=[255,0,255], Name='Red Edge', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.NIR, COLOR=[0,0,0], Name='NIR', /INSERT_LEGEND, /OVERPLOT

;Moving the plot window
PlotID= oTool->FindIdentifiers('*Plot*', /ANNOTATION)
PlotOBJ = oTool->GetByIdentifier(PlotID[0])
PlotOBJ->Select
iTRANSLATE, 'data space', X=-40

;;;;;;;;;;;;Using the extension variable would put the output jpg in the transect folder
;iSAVE, extension
iSAVE, out_name

;append ';' to the front of idelete if you want the plot to stay open
;iDELETE, iPLOT

Counter=counter +1

ENDWHILE

END
