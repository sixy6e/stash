pro landsat_rad_to_kelvin_batch

cd, 'N:\'

envi_batch_init, log_file='batch.txt'

files=FILE_SEARCH('Storage01','*[0-9]_Therm_rad.hdr',COUNT=numfiles)

counter = 0

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

ENVI_FILE_QUERY, fid, dims=dims, fname=fname, bnames=bname
t_fid=[fid]
pos=[0]
exp = '1260.56/alog((607.76/float(b1))+1)'

;remove the 'rad' from the file name and put 'kelvin' instead
;works by removing the last three characters of fname which should be rad
;if this is not the case, the naming won't work properly
f_length = strlen(fname)
trim_fname = strmid(fname, 0, f_length - 3)
out_name= trim_fname + 'kelvin'

ENVI_DOIT, 'math_doit', $
fid=t_fid, pos=pos, dims=dims, $
exp=exp, out_name=out_name, $
r_fid=r_fid, out_bname=bname

Counter=counter +1
ENDWHILE

envi_batch_exit 

end