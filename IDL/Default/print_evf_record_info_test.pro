pro print_evf_record_info_test 
; 
; Open the EVF file can_v1.evf in the 
; ENVI_Install_Directory/data/vector 
; 

ENVI_SELECT, title='choose a file', fid=fid, pos=pos, dims=dims
   IF (fid eq -1) THEN return
    
   envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave
   map_info = envi_get_map_info(fid=fid)

evf_fname = 'D:\Data\MIA\MIA_boundary_Dissolve\MIA_Boundary_WGS84_UTM55s_.evf' 
evf_id = envi_evf_open(evf_fname) 
; 
; Get the vector information 
; 
envi_evf_info, evf_id, num_recs=num_recs, $ 
data_type=data_type, projection=projection, $ 
layer_name=layer_name 
; 
; Print information about each record 
; 
print, 'Number of Records: ',num_recs
print, projection.datum 
for i=0,num_recs-1 do begin 
  record = envi_evf_read_record(evf_id, i, type=5) 
  print, 'Number of nodes in Record ' + $ 
         strtrim(i+1,2) + ': ', n_elements(record[0,*])
         
  ;envi_convert_file_coordinates,fid,record[0,*],record[1,*], $
  ;xmap,ymap, /TO_MAP 
  
  ;envi_convert_file_coordinates,fid,xf,yf, $
  ;xmap,ymap
  
  envi_convert_file_coordinates,fid,xf,yf, $
  record[0,*],record[1,*]
  
  roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
     color=4, name='evfs')
  
  xpts=reform(xf)
  ypts=reform(yf)
 
 ENVI_DEFINE_ROI, roi_id, /polygon, xpts=xpts, ypts=ypts
     
 ; ENVI_DEFINE_ROI, roi_id, /polygon, $
;   xpts=reform(xf), ypts=reform(yf)
  
  roi_ids = envi_get_roi_ids(fid=fid)
  envi_save_rois, 'D:\Data\MIA\MIA_boundary_Dissolve\MIA_boundary_.evf.roi', roi_ids 
endfor 
; 
; Close the EVF file 
; 
envi_evf_close, evf_id 



end