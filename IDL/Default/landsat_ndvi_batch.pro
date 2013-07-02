pro landsat_ndvi_batch

cd, 'D:\Data\Imagery\Landsat\Landsat_5'

envi_batch_init, log_file='batch.txt'

files=FILE_SEARCH('Processing2','*[0-9]_rfl*_subs.hdr',COUNT=numfiles)

counter = 0

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

ENVI_FILE_QUERY, fid, dims=dims, fname=fname
t_fid=[fid,fid]
pos=[3,2]
exp = '(float(b1)-float(b2))/(float(b1)+float(b2))'
out_name= fname + '_ndvi'

ENVI_DOIT, 'math_doit', $
fid=t_fid, pos=pos, dims=dims, $
exp=exp, out_name=out_name, $
r_fid=r_fid, out_bname='NDVI'

Counter=counter +1
ENDWHILE

envi_batch_exit 

end