pro RapidEye_transect_plots

in_dir='D:\Data\Classifications\2010_01_19_CIA\Transects'
out_dir='D:\Data\Classifications\2010_01_19_CIA\Transects\Plots'

cd, out_dir

itemplate=ASCII_TEMPLATE()

files=FILE_SEARCH(in_dir,'*',COUNT=numfiles)

counter=0

While(counter LT numfiles) DO BEGIN
name=files(counter)
extension= name + '.bmp'
transect=READ_ASCII(name,TEMPLATE=itemplate)
iPLOT, transect.Point, transect.Blue, COLOR=[0,0,255], Name='Blue', /INSERT_LEGEND
iPLOT, transect.Point, transect.Green, COLOR=[0,255,0], Name='Green', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Red, COLOR=[255,0,0], Name='Red', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.Red_Edge, COLOR=[255,0,255], Name='Red Edge', /INSERT_LEGEND, /OVERPLOT
iPLOT, transect.Point, transect.NIR, COLOR=[0,0,0], Name='NIR', /INSERT_LEGEND, /OVERPLOT


