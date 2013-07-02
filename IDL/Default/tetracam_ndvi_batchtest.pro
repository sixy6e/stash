pro TetraCam_ndvi_batchtest

in_dir= 'D:/Data/ENVI_Workspace/IDL/Original'
out_dir= 'D:/Data/ENVI_Workspace/IDL/NDVI'

cd, out_dir

envi, /restore_base_save_files

envi_batch_init, log_file='batch.txt'

files=FILE_SEARCH(in_dir,'*.BMP',COUNT=numfiles)
IF(numfiles EQ 0) THEN BEGIN
Print, 'No Files Were found to process'
ENDIF
counter=0

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

name=files[counter]

ENVI_FILE_QUERY, fid, dims=dims
t_fid=[fid,fid]
pos=[0,1]
exp = '(float(b1)-float(b2))/(float(b1)+float(b2))'
out_name=FILE_BASENAME(name, '.BMP') +'_ndvi'

ENVI_DOIT, 'math_doit', $
fid=t_fid, pos=pos, dims=dims, $
exp=exp, out_name=out_name, $
r_fid=r_fid

Counter=counter +1
ENDWHILE


envi_batch_exit 



end
