pro example_envi_batch_status_window 
  ; 
  ; First restore all the base save files. 
  ; 
  envi, /restore_base_save_files 
  ; 
  ; Initialize ENVI and send all errors 
  ; and warnings to the file batch.txt 
  ; 
  envi_batch_init, log_file='batch.txt' 
  ; 
  ; Open the input file 
  ; 
  envi_open_file, 'testfl', r_fid=fid 
  if (fid eq -1) then begin 
    envi_batch_exit 
    return 
  endif 
  ; 
  ; Get the dimensions and # bands 
  ; for the input file. 
  ; 
  envi_file_query, fid, dims=dims, nb=nb 
  ; 
  ; Set the pos to calculate 
  ; statistics for all data (spectrally) 
  ; in the file. 
  ; 
  pos  = lindgen(nb) 
  ; 
  ; Calculate the basic statistics and 
  ; print the mean. 
  ; 
  envi_doit, 'envi_stats_doit', fid=fid, pos=pos, $ 
    dims=dims, comp_flag=1, mean=mean 
  print, 'Mean', mean 
  ; 
  ; Turn off the status window and do the same 
  ; 
  envi_batch_status_window, /off 
  ; 
  ; Calculate the basic statistics and 
  ; print the mean. 
  ; 
  envi_doit, 'envi_stats_doit', fid=fid, pos=pos, $ 
    dims=dims, comp_flag=1, mean=mean 
  print, 'Mean', mean 
  ; 
  ; Exit ENVI 
  ; 
  envi_batch_exit 
end