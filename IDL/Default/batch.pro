PRO batch

dir='d:/Data/Bryson'
cd, dir

imgs=ASCII_TEMPLATE('IR_0185.csv')

files=FILE_SEARCH('*.csv',COUNT=numfiles)

counter=0

While(counter LT numfiles) DO BEGIN
name=files(counter)
extension= name + '.tif'
A=READ_ASCII(name,TEMPLATE=imgs)
WRITE_TIFF,extension,A.image,/FLOAT

Counter=counter +1
ENDWHILE

END