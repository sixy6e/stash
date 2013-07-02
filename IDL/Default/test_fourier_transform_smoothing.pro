pro test_fourier_transform_smoothing, event

;smoothes time-series images using the fourier transform
;this requires the image to be in envi's bip interleave format

COMPILE_OPT STRICTARR

ENVI_SELECT, title='choose a file', fid=fid, pos=pos, dims=dims
   IF (fid eq -1) THEN return
    
   envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave, $
      fname=fname, bnames=bnames
   map_info = envi_get_map_info(fid=fid)
   

TLB = WIDGET_AUTO_BASE(title='Fourier Transform')

wo = widget_outf(tlb, uvalue='outf', /auto)  
   result = auto_wid_mng(tlb)
   fname2=result.outf
   
   if (result.accept eq 0) then return  
   if (result.accept eq 1) then $
   
   mask = bytarr(nb, ns)
   ostr = 'Output File: ' + fname2 
   rstr = ["Input File :" + fname, ostr] 
   envi_report_init, rstr, title="Fourier Transform Filtering", base=base
   
   openw, unit, result.outf, /get_lun
     tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
     interleave=interleave, xs=dims[1], xe=dims[2], $
     ys=dims[3], ye=dims[4])
     
     for i=0L, num_tiles-1 do begin
         envi_report_stat, base, i, num_tiles
         data = envi_get_tile(tile_id, i)
         fftr = fft(data, DIMENSION=1)
         ;fftrshift = shift(fftr, 15.5)
         ;powerspectrum = abs(fftrshift)^2
         powerspectrum = abs(fftr)^2
         meanpwr = mean(powerspectrum, DIMENSION=1)
         for j=0, ns-1 do mask[*,j] = powerspectrum[*,j] gt meanpwr[j]
         ;mask = powerspectrum gt meanpwr
         ;masked = fftrshift * mask
         ;mask = reform(mask, 1, ns), just testing what happens to the following arrays
         masked = fftr * mask
         ;maskedshift = shift(masked, -15.5)
         ;inverse = real_part(fft(maskedshift, /inverse))
         inverse = real_part(fft(masked, DIMENSION=1, /inverse))
         ;filter=CONVOL(data,svg, /EDGE_TRUNCATE)
         ;writeu, unit, filter
         writeu, unit, inverse
     endfor
  FREE_LUN, unit
  envi_setup_head, fname=fname2, ns=ns, nl=nl, nb=nb, bnames=bnames, $ 
    data_type=4, offset=0, interleave=2, map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
  envi_tile_done, tile_id 
  envi_report_init, base=base, /finish  
end 