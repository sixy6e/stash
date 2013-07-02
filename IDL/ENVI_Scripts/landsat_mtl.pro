pro landsat_mtl

cd, 'D:\Data\Imagery\Landsat\Landsat_5'

;files=FILE_SEARCH('Processing','*MTL.txt',COUNT=numfiles)
files=FILE_SEARCH('Processing','*9384*rfl.hdr',COUNT=numfiles)

counter = 0

While(counter LT numfiles) DO BEGIN

ENVI_OPEN_FILE, files[counter], r_fid=fid

Counter= counter +1

ENDWHILE

END
  
