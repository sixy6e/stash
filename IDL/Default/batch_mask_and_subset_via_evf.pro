pro batch_mask_and_subset_via_evf

;the evf files need to be the same projection as the image files in order for the
;roi's to be created
;change the mask layer and subset layer as needed
cd, 'D:\Data\Imagery\Landsat\Landsat_5'

envi_batch_init, log_file='batch.txt'

;the search method for finding files
;files=FILE_SEARCH('Processing2','*[0-9]_rfl_mSubs.hdr',COUNT=numfiles)
files=FILE_SEARCH('Processing2','*Therm_rfl_mSubs.hdr',COUNT=numfiles)

counter = 0

Mask_evf_fname = 'D:\Data\Imagery\wrs2_descending\9284_9384_Overlap_WGS84_UTM55s_.evf' 
Mask_evf_id = envi_evf_open(Mask_evf_fname)
;subs_evf_fname = 'D:\Data\MIA\MIA_boundary_Dissolve\MIA_Boundary_WGS84_UTM55s_.evf'
subs_evf_fname = 'D:\Data\Coleambally\CollyBoundary\MikeRidley\CIA_farms_Mar09_UTMZ55S_9284_9384_Overlap_.evf'
subs_evf_id = envi_evf_open(subs_evf_fname)

;get info for the evf to be used as a mask
envi_evf_info, Mask_evf_id, num_recs=Mask_num_recs, $ 
  data_type=Mask_data_type, projection=Mask_projection, $ 
  layer_name=Mask_layer_name
;get info for the evf to be used as a subset  
envi_evf_info, subs_evf_id, num_recs=subs_num_recs, $ 
  data_type=subs_data_type, projection=subs_projection, $ 
  layer_name=subs_layer_name

for i=0,Mask_num_recs-1 do begin 
  Mask_record = envi_evf_read_record(Mask_evf_id, i, type=5)
endfor

for i=0,subs_num_recs-1 do begin 
  subs_record = envi_evf_read_record(subs_evf_id, i, type=5)
endfor
  
While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

ENVI_FILE_QUERY, fid, dims=dims, fname=fname, ns=ns, nl=nl, nb=nb
map_info = envi_get_map_info(fid=fid)

;changing to each image directory so the roi can be saved into the same directory
convert_dir=STRING(files[counter])
backslash=STRPOS(convert_dir, '\', /REVERSE_SEARCH)
directory=STRMID(convert_dir, 0, backslash+1)
cd, directory

;remove the .shp and change it to .roi, add 'Therm' when doing the thermal band
Mask_rmvSHP = FILE_BASENAME(Mask_layer_name, '.shp') + 'Therm_.roi'
subs_rmvSHP = FILE_BASENAME(subs_layer_name, '.shp') + 'Therm_.roi'
;remove the 'Layer: ' from the front of the file name
Mask_roi_out_name = STRMID(Mask_rmvSHP, 7)
subs_roi_out_name = STRMID(subs_rmvSHP, 7)
;add 'therm' when processing the thermal band
mask_out_name = '9293_84overlapTherm_mask'
file_out_name = fname + '_CIAoverlapTherm_subs'

;convert the map coordinates to image coordinates
envi_convert_file_coordinates,fid,Mask_xf,Mask_yf, $
  Mask_record[0,*], Mask_record[1,*]
  
  Mask_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
     color=4, name='Mask_evfs')
  
  Mask_xpts=reform(Mask_xf)
  Mask_ypts=reform(Mask_yf)
  
envi_convert_file_coordinates,fid,subs_xf,subs_yf, $
  subs_record[0,*], subs_record[1,*]
  
  subs_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
     color=4, name='subs_evfs')
  
  subs_xpts=reform(subs_xf)
  subs_ypts=reform(subs_yf)  
 
ENVI_DEFINE_ROI, Mask_roi_id, /polygon, xpts=Mask_xpts, ypts=Mask_ypts

ENVI_DEFINE_ROI, subs_roi_id, /polygon, xpts=subs_xpts, ypts=subs_ypts
  
Mask_roi_ids = envi_get_roi_ids(fid=fid)
   envi_save_rois, Mask_roi_out_name, Mask_roi_ids

subs_roi_ids = envi_get_roi_ids(fid=fid)
   envi_save_rois, subs_roi_out_name, subs_roi_ids

subs_roi_dims = ROUND([-1L, min(subs_xf), max(subs_xf), min(subs_yf), max(subs_yf)])
  
mask= BYTARR([ns,nl])
;roi_ids = envi_get_roi_ids(fid=fid)
addr = ENVI_GET_ROI(Mask_roi_ids[0])
mask[addr]=1

ENVI_WRITE_ENVI_FILE, mask, BNAMES='mask', DATA_TYPE=1, MAP_INFO=map_info, $
  r_fid=m_fid, OUT_NAME=mask_out_name

;the pos will need to change depending on the number of bands
;in the chosen file
;landsat 5 stack, not including the thermal band
;pos=[0,1,2,3,4,5]
;thermal band, when processed as a single image, not a stack
pos=[0]

ENVI_DOIT, 'ENVI_MASK_APPLY_DOIT', DIMS=subs_roi_dims, fid=fid, m_fid=m_fid, m_pos=0, $
  VALUE=0, OUT_NAME=file_out_name, r_fid=r_fid, pos=pos

;change back to the original directory so the next file can open
cd, 'D:\Data\Imagery\Landsat\Landsat_5'
  
Counter=counter +1
ENDWHILE

envi_batch_exit 

end