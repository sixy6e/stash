pro envi_layer_stacking_doit_multi_file_test 
  compile_opt idl2   
 
 ;as this is creating a temporal dataset, in order for further processing such as 
 ;savitsky-golay filter or pixel stats to wrok, convert the file to bip
 ;this had been taken and modified slightly from the ittvis techtip website
 ;ttid=4572
 ;the order the files are found in, will be the same order when put into bands
 ;first restore all the base save files and initialize batch. 
  envi, /restore_base_save_files  
  envi_batch_init, log_file='batch.txt'  

 ;go to directory with several files
  cd, 'D:\Data\Imagery\Landsat\Landsat_5'
  files = file_search('Processing','*overlap_subs_ndvi.hdr', count=numfiles)

 ;open and gather file information in arrays, create the arrays so the following
 ;for loops will work
  in_fid=lonarr(numfiles)
  in_nb=lonarr(numfiles)
  in_dims=lonarr(5, numfiles)
  in_dt=lonarr(numfiles)
  ;in_bnames=string(lonarr(numfiles))
  ;trim1=string(lonarr(numfiles))
  ;trim2=string(lonarr(numfiles))
  band=string(lonarr(numfiles))
  number=string(lonarr(numfiles))
  band_number=string(lonarr(numfiles))
  get_band_name=string(lonarr(numfiles))
  out_bname=string(lonarr(numfiles))
  
  
 ;create the array with value 'Band' placed in each element 
  for i=0L, numfiles-1 do begin
    band[i]= 'Band '
  endfor
 ;create the array with values of 1 to the number of files 
  for i=0L, numfiles-1 do begin
    number[i]= strtrim(i+1,1)
  endfor
 ;concatenate (join) the band and number arrays into one
  for i=0L, numfiles-1 do begin
    band_number[i]= band[i] + number[i]
  endfor
  
  ;out_bname=REPLICATE('Band '+ STRMID(STRMID(files[0],(STRPOS(files[0], '\', $
  ; /REVERSE_SEARCH)+1)), 0, 15), 1)
  ;collect the file name info that will be used as band names
  for i=0L, numfiles-1 do begin
    ;out_bname[i]= [REPLICATE('Band '+ STRMID(STRMID(files[i],(STRPOS(files[i], $
      ;'\', /REVERSE_SEARCH)+1)), 0, 15), numfiles)]
      get_band_name[i]= STRMID(STRMID(files[i],(STRPOS(files[i], $
       '\', /REVERSE_SEARCH)+1)), 0, 15)
      
      ;out_bname[i]=[i]+1
      ;
      ;out_bname[i]= lonarr('Band '+ STRMID(STRMID(files[i],(STRPOS(files[i], $
      ;'\', /REVERSE_SEARCH)+1)), 0, 15),numfiles)
     
     ;find=STRPOS(files[i], '\', /REVERSE_SEARCH)
     ;trim1=STRMID(find, 0, find + 1)
     ;directory=STRMID(trim1, 0, 15)
  endfor
  
  ;final output for band names 
  for i=0L, numfiles-1 do begin
    out_bname[i]= band_number[i] + ' ' + get_band_name[i]
  endfor
  
  for i=0L, numfiles-1 do begin 
    envi_open_file, files[i], r_fid=r_fid  
       if (r_fid eq -1) then begin  
        envi_batch_exit  
        return 
       endif  
 
    envi_file_query, r_fid, ns=ns, nl=nl, nb=nb, dims=dims, data_type=dt, fname=fname  
    in_fid[i]=r_fid 
    in_nb[i]=nb
    in_dims[*,i]=dims
    in_dt[i]=dt
    ;in_bnames[i]=fname
  endfor
  
 ;set up output fid, pos, and dims arrays  
  out_fid = replicate(in_fid[0], in_nb[0])
  for i=1, numfiles-1 do out_fid = [out_fid, replicate(in_fid[i], in_nb[i])]
  
  out_pos = lindgen(in_nb[0])
  for i = 1, numfiles-1 do out_pos = [out_pos, lindgen(in_nb[i])]

  rep_dims = (intarr(in_nb[0])+1) # in_dims[*,0]
  for i = 1, numfiles-1 do $
    rep_dims = [rep_dims, (intarr(in_nb[i]) + 1) # in_dims[*,i]]
  out_dims = transpose(rep_dims)
  
 ; out_bnames = replicate(in_bnames[0], numfiles)
 ; for i=1, numfiles-1 do out_bnames = [out_bnames, replicate(in_bnames[i], in_bnames[i])]

 ;set the output projection and pixel size from the first file. 
 ;save the result to disk and use max data type 
  out_proj = envi_get_projection(fid=in_fid[0], pixel_size=out_ps)  
  out_dt = max(in_dt)
  out_name = '2008_09_16__2009_05_14_MIAsubs_ndvi' 

 ;call the layer stacking routine. Do not set the exclusive keyword allow for an  
 ;inclusive result. Use nearest neighbor for the interpolation method.  

  envi_doit, 'envi_layer_stacking_doit', fid=out_fid, pos=out_pos, dims=out_dims, $  
    out_dt=out_dt, out_name=out_name, interp=0, out_ps=out_ps, $  
    out_proj=out_proj, r_fid=r_fid, out_bname=out_bname 

 ;exit ENVI  
  envi_batch_exit  

end