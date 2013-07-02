PRO threeD_Cube, event 

ENVI_SELECT, title='choose a file', fid=in_fid  
   IF (in_fid eq -1L) THEN return
   envi_file_query, in_fid, dims=dims, nb=nb  
  pos  = lindgen(nb)  
  rgb_pos = [3,2,1]  
  out_name = 'testimg'
    
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
    fid=in_fid, pos=pos, dims=dims, $  
    out_name=out_name, scale=10.0, $  
    border=30, rgb_pos=rgb_pos, ct=ct, $  
    in_fid=in_fid  
  ;  
  ; Exit ENVI  
  ;  
  ;envi_batch_exit  
end