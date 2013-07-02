pro savgol_widget, event

;smoothes time-series images using the savitsky-golay filter
;this requires the image to be in envi's bip interleave format
   COMPILE_OPT STRICTARR 
  
   ENVI_SELECT, title='choose a file', fid=fid, pos=pos, dims=dims
   IF (fid eq -1) THEN return
    
   envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave, $
      fname=fname, bnames=bnames
   map_info = envi_get_map_info(fid=fid)
 ;set up the interactive widget display   
   TLB = WIDGET_AUTO_BASE(title='Savitsky-Golay Filter')
   row_base1 = WIDGET_BASE(TLB, /row)  
   p1 = WIDGET_PARAM(row_base1, /auto_manage, dt=1, $  
      prompt='N Left', uvalue='p1')
   row_base2 = WIDGET_BASE(TLB, /row)
   p2 = WIDGET_PARAM(row_base2, /auto_manage, dt=1, $  
      prompt='N Right', uvalue='p2')
   row_base3 = WIDGET_BASE(TLB, /row)
   p3 = WIDGET_PARAM(row_base3, /auto_manage, dt=1, $  
      prompt='Order', uvalue='p3')
   row_base4 = WIDGET_BASE(TLB, /row)
   p4 = WIDGET_PARAM(row_base4, /auto_manage, dt=1, $  
      prompt='Degree', uvalue='p4')
   wo = widget_outf(tlb, uvalue='outf', /auto)  
   result = auto_wid_mng(tlb)
   fname2=result.outf
;perform the tiling procedure and filter the values using
;the savistky-golay filter     
   if (result.accept eq 0) then return  
   if (result.accept eq 1) then $
;displays the processing increment window  
   ostr = 'Output File: ' + fname2 
   rstr = ["Input File :" + fname, ostr] 
   envi_report_init, rstr, title="Savitsky-Golay Smoothing", base=base
        
     svg=Savgol(result.p1,result.p2,result.p3,result.p4)
     openw, unit, result.outf, /get_lun
     tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
     interleave=interleave, xs=dims[1], xe=dims[2], $
     ys=dims[3], ye=dims[4])
     
     for i=0L, num_tiles-1 do begin
         envi_report_stat, base, i, num_tiles
         data = envi_get_tile(tile_id, i)
         filter=CONVOL(data,svg, /EDGE_TRUNCATE)
         writeu, unit, filter
     endfor
  FREE_LUN, unit
  envi_setup_head, fname=fname2, ns=ns, nl=nl, nb=nb, bnames=bnames, $ 
    data_type=4, offset=0, interleave=2, map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
  envi_tile_done, tile_id 
  envi_report_init, base=base, /finish  
end 
