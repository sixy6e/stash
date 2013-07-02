pro example_math_doit 
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
  envi_open_file, 'TTC01143.BMP', r_fid=fid 
  if (fid eq -1) then begin 
    envi_batch_exit 
    return 
  endif 
  ; 
  ; Set the keywords. We will perform the 
  ; band math on all samples in the file. 
  ; 
  envi_file_query, fid, dims=dims 
  t_fid = [fid,fid] 
  pos  = [0,1] 
  exp = '(float(b1)-float(b2))/(float(b1)+float(b2))' 
  out_name = 'testimg3' 
  ; 
  ; Perform the band math processing 
  ; 
  envi_doit, 'math_doit', $ 
    fid=t_fid, pos=pos, dims=dims, $ 
    exp=exp, out_name=out_name, $ 
    r_fid=r_fid 
  ; 
  ; Exit ENVI 
  ; 
  envi_batch_exit 
end 
