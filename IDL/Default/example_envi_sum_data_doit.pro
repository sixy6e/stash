pro example_envi_sum_data_doit

envi_open_file, 'median4median4', r_fid=fid  
  if (fid eq -1) then begin  
    envi_batch_exit  
    return  
  endif
  
  
envi_file_query, fid, dims=dims, nb=nb  
  pos  = lindgen(nb)  
  out_name = 'median4median4stats'  
  compute_flag = [1,1,1,1,1,1,1,1]  
  out_dt = 4

envi_doit, 'envi_sum_data_doit', $  
    fid=fid, pos=pos, dims=dims, $  
    out_name=out_name, out_dt=out_dt, $  
    compute_flag=compute_flag
    
 end