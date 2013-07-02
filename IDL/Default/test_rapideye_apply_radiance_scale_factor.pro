pro test_rapideye_apply_radiance_scale_factor

;can't get it to work across all bands::Fixed!
cd, 'D:\Data\Imagery\RapidEye\2011_01_CIA\887a0053_CharlesStrutUni_RiceAreaColeambally'

files=FILE_SEARCH('RAWDATA','*[0-9].tif',COUNT=numfiles)

counter = 0

;setting this directory now will cause the envi_open_file not to open anything
;cd, 'D:\Data\Imagery\RapidEye\2011_01_CIA\887a0053_CharlesStrutUni_RiceAreaColeambally\RadianceScaleFactor'

bnames = ['Blue', 'Green', 'Red', 'Red Edge', 'NIR']

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif
  
  envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave, $
      fname=fname
  map_info = envi_get_map_info(fid=fid)
  
  pos = lonarr(nb)
  for p = 0L, nb-1 do begin 
    pos[p] = p 
  endfor
  
  out_fname = FILE_BASENAME(fname, '.tif')
  directory = 'D:\Data\Imagery\RapidEye\2011_01_CIA\887a0053_CharlesStrutUni_RiceAreaColeambally\RadianceScaleFactor\'
  out_file = directory + out_fname
  
  envi_report_init, out_file, title="Applying Scale Factor", base=base
  
  openw, unit, out_file, /get_lun 
  tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $ 
    interleave=(interleave > 1), xs=dims[1], xe=dims[2], $ 
    ys=dims[3], ye=dims[4]) 
    
  for i=0L, num_tiles-1 do begin 
    envi_report_stat, base, i, num_tiles
    data = envi_get_tile(tile_id, i) 
    data = float(data)/100
    writeu, unit, data 
   ; print, i 
  endfor 
  free_lun, unit 
  
  envi_setup_head, fname=out_file, ns=ns, nl=nl, nb=nb, bnames=bnames, $ 
    data_type=4, offset=0, interleave=(interleave > 1), map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
  envi_tile_done, tile_id
  
  envi_report_init, base=base, /finish 
  
  
 ; t_fid=[fid,fid,fid,fid,fid]
 ; pos=[0,1,2,3,4]
 ; exp = 'float(s1)/100'
  ;out_name= fname + '_ndvi'
 ; out_fname = FILE_BASENAME(fname, '.tif')
  
 ; ENVI_DOIT, 'math_doit', $
;fid=t_fid, pos=pos, dims=dims, $
;exp=exp, out_name=out_fname, $
;r_fid=r_fid, out_bname=bnames

Counter=counter +1
  
ENDWHILE

END