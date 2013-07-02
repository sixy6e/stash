pro image_tile_subsetting_masking

;the evf files need to be the same projection as the image files in order for the
;roi's to be created
;change the mask layer and subset layer as needed
;You will need to change the tile layer as needed
;You will need to change the search method as well
;depending on the tile and whether or not it is the thermal band being processed
cd, 'D:\Data\Imagery\Landsat\Landsat_5'

envi_batch_init, log_file='batch.txt'

;the search method for finding files
files=FILE_SEARCH('Processing2','*9284_rfl.hdr',COUNT=numfiles)

counter = 0

;generic, chop and change the file name as needed
tile_evf_fname = 'D:\Data\Imagery\Landsat\WRS2_DescendingTiles\9284_WGS84_UTMz55S_.evf'
tile_evf_id = envi_evf_open(tile_evf_fname)

;get info for the evf, this will be used for the creation of the mask, as well as for subsetting
envi_evf_info, tile_evf_id, num_recs = Tile_num_recs, $
  data_type = Tile_data_type, projection = Tile_prijection, $
  layer_name=Tile_layer_name

for i=0,Tile_num_recs-1 do begin 
  Tile_record = envi_evf_read_record(Tile_evf_id, i, type=5)
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

;remove the .shp and change it to .roi
Tile_rmvSHP = FILE_BASENAME(Tile_layer_name, '.shp') + '.roi'

;remove the 'Layer: ' from the front of the file name
Tile_roi_out_name = STRMID(Tile_rmvSHP, 7)

;add 'therm' when processing the thermal band, ie. Therm_Tile_Mask, Therm_mSubs
mask_out_name = 'Tile_mask'
file_out_name = fname + '_mSubs'

;convert the map coordinates to image coordinates
envi_convert_file_coordinates,fid,Tile_xf,Tile_yf, $
  Tile_record[0,*], Tile_record[1,*]
  
  Tile_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
     color=4, name='Tile_evfs')
  
  Tile_xpts=reform(Tile_xf)
  Tile_ypts=reform(Tile_yf)


ENVI_DEFINE_ROI, Tile_roi_id, /polygon, xpts=Tile_xpts, ypts=Tile_ypts
 

Tile_roi_ids = envi_get_roi_ids(fid=fid)
   envi_save_rois, Tile_roi_out_name, Tile_roi_ids


Tile_subs_roi_dims = ROUND([-1L, min(Tile_xf), max(Tile_xf), min(Tile_yf), max(Tile_yf)])

  
mask = BYTARR([ns,nl])
addr = ENVI_GET_ROI(Tile_roi_ids[0])
mask[addr]=1

ENVI_WRITE_ENVI_FILE, mask, BNAMES='mask', DATA_TYPE=1, MAP_INFO=map_info, $
  r_fid=m_fid, OUT_NAME=mask_out_name

;the pos will need to change depending on the number of bands
;in the chosen file
;landsat 5 stack, not including the termal band
pos=[0,1,2,3,4,5]
;thermal band, when processed as a single image, not a stack
;pos=[0]

ENVI_DOIT, 'ENVI_MASK_APPLY_DOIT', DIMS=Tile_subs_roi_dims, fid=fid, m_fid=m_fid, m_pos=0, $
  VALUE=0, OUT_NAME=file_out_name, r_fid=r_fid, pos=pos

;change back to the original directory so the next file can open
cd, 'D:\Data\Imagery\Landsat\Landsat_5'
  
Counter=counter +1
ENDWHILE

envi_batch_exit 

end