pro example_fx_doit  
  compile_opt strictarr, hidden  
  ;  
  ; First restore all the base save files  
  ;  
  envi, /restore_base_save_files  
  ;  
  ; Initialize ENVI and send all errors  
  ; and warnings to the file batch.txt  
  ;  
  envi_batch_init, log_file = 'batch.txt'  
  ;  
  ; Specify the input image file, rule set,  
  ; and output directory for vector shapefiles  
  ;  
  imgFile = 'qb_boulder_msi'  
  rulesetfilename = 'qb_boulder_msi_ruleset.xml'  
  vectorFilename = 'vector_out'  
  ;  
  ; Open the image file  
  ;  
  envi_open_file, imgFile, r_fid=fid  
  if (fid eq -1) then begin  
    envi_batch_exit  
    return  
  endif  
  ;  
  ; Set the necessary variables  
  ;  
  envi_file_query, fid, dims=dims, nb=nb  
  pos = lindgen(nb)  
  ;  
  ; Call the doit  
  ;  
  envi_doit, 'envi_fx_doit', fid=fid, dims=dims, $  
    pos=pos, scale_level=60.0, merge_level=67.0, $  
    conf_threshold=0.20, ruleset_filename=rulesetfilename, $  
    vector_filename=vectorfilename, r_fid=r_fid  
  ;  
  if (r_fid eq -1) then begin  
    str = 'Processing failed for ' + imgFile  
    envi_error, str  
  endif  
  ;  
  ; Exit ENVI  
  ;  
  envi_batch_exit  
  ;  
end  