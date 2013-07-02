pro savgol_widget_test, event
;the image gets rotated 90 degrees to the right, need to change that
;the nested for loops make this work very slowly
   COMPILE_OPT STRICTARR 
   
   ENVI_SELECT, title='choose a file', fid=fid, pos=pos, dims=dims
   IF (fid eq -1) THEN return
    
   envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave
   map_info = envi_get_map_info(fid=fid)
    
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
   if (result.accept eq 0) then return  
   if (result.accept eq 1) then $        
     svg=Savgol(result.p1,result.p2,result.p3,result.p4)
     rfm_svg=REFORM(svg,1,result.p1 + result.p2 +1)
     openw, unit, result.outf, /get_lun
     for i=0, nl-1 do for j=0, ns-1 do begin
     pixel= envi_get_slice(fid=fid, line=j, pos=pos, $
      xs=i,xe=i)
     filter=CONVOL(pixel,rfm_svg, /EDGE_TRUNCATE)
     writeu, unit, filter
     ;ENVI_WRITE_ENVI_FILE,filter , $
      ;DATA_TYPE=4, OUT_NAME=result.outf, fid=in_fid, nb=nb, ns=ns, nl=nl
     endfor
     ;ENVI_WRITE_ENVI_FILE,filter , $
      ;DATA_TYPE=4, OUT_NAME=result.outf, fid=in_fid, nb=nb, ns=ns, nl=nl
      FREE_LUN, unit
      envi_setup_head, fname=fname2, ns=ns, nl=nl, nb=nb, $ 
    data_type=4, offset=0, interleave=2, map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
      envi_tile_done, tile_id 
    
end 
