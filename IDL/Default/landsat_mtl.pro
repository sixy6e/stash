pro landsat_mtl

cd, 'D:\Data\Imagery\Landsat\Landsat_5'
;cd, 'D:\Data\Imagery\RapidEye\2011_01_CIA\887a0053_CharlesStrutUni_RiceAreaColeambally'

files=FILE_SEARCH('Pro3','*MTL.txt',COUNT=numfiles)
;files=FILE_SEARCH('Processing','*overlap*ndvi.hdr',COUNT=numfiles)
;files=FILE_SEARCH('TOA_rfl','*[0-9]_rfl.hdr',COUNT=numfiles)

counter = 0

While(counter LT numfiles) DO BEGIN

ENVI_OPEN_FILE, files[counter], r_fid=fid

Counter= counter +1

ENDWHILE

END
  
