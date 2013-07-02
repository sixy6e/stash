pro example_ndvi_doit  
  ;  
  ; First restore all the base save files.  
  cd, 'D:\tmp'   
  envi, /restore_base_save_files  
  ;  
  ; Initialize ENVI and send all errors  
  ; and warnings to the file batch.txt  
  ;  
  envi_batch_init, log_file='batch.txt'  
  ;  
  ; Open the input file  
  ;  
  envi_open_file, 'bhtmref.img', r_fid=fid  
  if (fid eq -1) then begin  
    envi_batch_exit  
    return  
  endif  
  ;  
  ; Set the keywords. We will perform the  
  ; NDVI on all samples and all bands  
  ; in the file.  
  ;  
  envi_file_query, fid, dims=dims  
  pos  = [4,3] - 1  
  out_name = 'testimg'  
  ;  
  ; Perform the NDVI transform  
  ;  
  envi_doit, 'ndvi_doit', $  
    fid=fid, pos=pos, dims=dims, $  
    /check, o_min=0, o_max=255, $  
    out_name=out_name, r_fid=r_fid  
  ;  
  ; Exit ENVI  
  ;  
  envi_batch_exit  
end