pro example_envi_cube_3d_doit  
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
  ; Set the keywords DIMS and POS to  
  ; use all pixles and all bands for the  
  ; spatial and spectral parts of the cube.  
  ; Use band 3,2,1 as the RGB bands for the  
  ; front face of the cube.  
  ;  
  envi_file_query, fid, dims=dims, nb=nb  
  pos  = lindgen(nb)  
  rgb_pos = [3,2,1]  
  out_name = 'testimg'  
  ;  
  ; Set the CT keyword to the fifth color  
  ; table from the IDL colors1.tbl file.  
  ;  
  openr, unit, filepath('colors1.tbl', $  
    sub=['resource','colors']), $  
    /block, /get  
  a = assoc(unit, bytarr(256,3), 1)  
  ct = a[4]  
  ct[0,*] = 0  
  free_lun, unit  
  ;  
  ; Call the doit  
  ;  
  envi_doit, 'ENVI_CUBE_3D_DOIT', $  
    fid=fid, pos=pos, dims=dims, $  
    out_name=out_name, scale=10.0, $  
    border=30, rgb_pos=rgb_pos, ct=ct, $  
    r_fid=r_fid  
  ;  
  ; Exit ENVI  
  ;  
  envi_batch_exit  
end