PRO ThermalCamera_batch

;turns the csv files the thermal camera spits out into a tif image


in_dir='d:/Data/ENVI_Workspace/IDL/Original'

cd, in_dir

;i should set up an auto template but haven't as of yet
itemplate=ASCII_TEMPLATE()

files=FILE_SEARCH('*.csv',COUNT=numfiles)

counter=0

While(counter LT numfiles) DO BEGIN
name=files(counter)
extension= name + '.tif'
A=READ_ASCII(name,TEMPLATE=itemplate)
WRITE_TIFF,extension,A.image,/FLOAT

Counter=counter +1
ENDWHILE

END