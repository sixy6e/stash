PRO file_info, event  
   ENVI_SELECT, title='choose a file', fid=in_fid  
   IF (in_fid eq -1L) THEN return
   ENVI_FILE_QUERY, in_fid, ns=ns, nl=nl, nb=nb, fname=fname  
   OpenR, unit, fname, /Get_LUN  
   info = FSTAT(unit)  
   Free_LUN, unit  
   print, 'you selected ',fname  
   print, 'number of samples = ',ns  
   print, 'number of lines = ',nl  
   print, 'number of bands = ',nb  
   print, 'file size in bytes = ',info.size  
END