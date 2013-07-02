pro landsat_ndvi_batch_test

cd, 'W:\Corporate Data\Storage02\Remote_Sensing\Processed_Images'

envi_batch_init, log_file='batch.txt'

files=FILE_SEARCH('Landsat5','*CIAsubs.hdr',COUNT=numfiles)

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
r_fid=r_fid

Counter=counter +1
ENDWHILE

envi_batch_exit 

end