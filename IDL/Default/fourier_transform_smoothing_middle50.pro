pro fourier_transform_smoothing_middle50, event

;Smoothes time-series images using the fourier transform on the middle 50% of 
;the transformed and shifted data
;This requires the image to be in envi's bip interleave format
;At the moment this only applies a filter based on the mean of the power spectrum
;May try to include other filters as options for processing

COMPILE_OPT STRICTARR

ENVI_SELECT, title='choose a file', fid=fid, pos=pos, dims=dims
   IF (fid eq -1) THEN return

;Retrieve image information    
   envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave, $
      fname=fname, bnames=bnames

;Get the image projection information      
   map_info = envi_get_map_info(fid=fid)

;Set up the values for the mean to calculate across only the middle 50% of the array values
Centre = float(nb)/2
Left = Centre/2
Right = Centre + Centre/2
 
;Setting up the interactive window
TLB = WIDGET_AUTO_BASE(title='Fourier Transform')

wo = widget_outf(tlb, uvalue='outf', /auto)  
   result = auto_wid_mng(tlb)
   fname2=result.outf
   
   if (result.accept eq 0) then return  
   if (result.accept eq 1) then $

;Create the array for the mask   
   mask = bytarr(nb, ns)
   
;Display the Percent Complete Window   
   ostr = 'Output File: ' + fname2 
   rstr = ["Input File :" + fname, ostr] 
   envi_report_init, rstr, title="Fourier Transform Filtering", base=base

;Initialise the tiling procedure and output location   
   openw, unit, result.outf, /get_lun
     tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
     interleave=interleave, xs=dims[1], xe=dims[2], $
     ys=dims[3], ye=dims[4])

;Running the tiling procedure and applying the fourier transform     
     for i=0L, num_tiles-1 do begin
         envi_report_stat, base, i, num_tiles
         data = envi_get_tile(tile_id, i)
         fftr = fft(data, DIMENSION=1)
         fftrshift = shift(fftr, Centre,0)
         powerspectrum = abs(fftrshift)^2
         meanpwr = mean(powerspectrum[Left:Right,*], DIMENSION=1)
         for j=0, ns-1 do mask[*,j] = powerspectrum[*,j] gt meanpwr[j]
         masked = fftrshift * mask
         maskedshift = shift(masked, -Centre,0)
         inverse = real_part(fft(maskedshift, DIMENSION=1, /inverse))
         writeu, unit, inverse
     endfor
 
;Free the LUN 
  FREE_LUN, unit
  
;Create the header file  
  envi_setup_head, fname=fname2, ns=ns, nl=nl, nb=nb, bnames=bnames, $ 
    data_type=4, offset=0, interleave=2, map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
 
;Close the tiling procedure and the Percent Complete window 
  envi_tile_done, tile_id 
  envi_report_init, base=base, /finish  
end 