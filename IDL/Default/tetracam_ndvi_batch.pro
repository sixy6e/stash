pro TetraCam_ndvi_batch

;calculates the ndvi for the tetracam images

;set the in and out directories
in_dir= 'D:/Data/ENVI_Workspace/IDL/Original'
out_dir= 'D:/Data/ENVI_Workspace/IDL/NDVI'

;change to the out directory
cd, out_dir

envi, /restore_base_save_files

;a log file in case something goes wrong
envi_batch_init, log_file='batch.txt'

;find all the images
files=FILE_SEARCH(in_dir,'*.BMP',COUNT=numfiles)
IF(numfiles EQ 0) THEN BEGIN
Print, 'No Files Were found to process'
ENDIF
counter=0

;setting the loop to run only for as many files it found, specified by counter
While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

name=files[counter]

;set fid for each of the bands in the expression, ie 2 bands [fid,fid]
;pos is the position of the bands, dims is dimensional subsets
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
