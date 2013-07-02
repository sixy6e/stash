;This is to be run after the fid_masking pro has been run.
;It will add all the masks together into a single file


pro fid_band_math_test

;The starting directory to run from
cd, 'C:\WINNT\Profiles\u08087\My Documents\Testing'

;Make sure only the required masks are located in the folder
files=FILE_SEARCH('Masks','*.hdr',COUNT=numfiles, /FULLY_QUALIFY_PATH)

counter = 0

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

  counter = counter + 1
ENDWHILE

;Retrieve fid's of all the files that have just been opened in ENVI
;For this to work properly ENVI has to be empty of an images
fids = ENVI_GET_FILE_IDS()

;All the images should have the same dimensions and projection
;so just retrieve the file info for the first FID

ENVI_FILE_QUERY, fids[0], dims=dims, fname=fname, ns=ns, nl=nl, nb=nb
map_info = envi_get_map_info(fid=fids[0])

;Need to set up an array containing all the positions of the bands
;within each image.  For this example all should be pos=[0] as they're
;single band images
;The pos will be an array of n, where n = number of images

;num = N_ELEMENTS(fids) ; the numfiles variable can be used here
;pos = bytarr(num)
pos = bytarr(numfiles)

;The band math expression needs to be set up for the number of images
;i.e. b1 + b2 + b3 ... + bn-1

b=strarr(numfiles)
b[*] = 'b'

num = strtrim(string(indgen(numfiles) + 1), 1)

expr = b + num + ' + '

;need to remove the last '+' sign
last_plus = strpos(expr[numfiles-1], '+', 0)
expr[numfiles - 1] = strmid(expr[numfiles - 1], 0, last_plus - 1)

;need to convert the array 'expr' of size n to a single element array
FOR i = 0, numfiles - 1 DO BEGIN
	IF (i eq 0) THEN BEGIN
		f_expr = expr[i]
	ENDIF ELSE BEGIN
		f_expr = f_expr + expr[i]
	ENDELSE
ENDFOR

file_name = 'Combined_FID_mask'

ENVI_DOIT, 'math_doit', $
fid=fids, pos=pos, dims=dims, $
exp=f_expr, out_name=file_name, $
r_fid=r_fid


END