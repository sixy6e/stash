pro spec_disk, out_name 
  ; Check for an output filename 
  ;if (n_elements(out_name) eq 0) then begin 
   ; print, 'Please specify a valid output filename' 
   ; return 
  ;endif 
  out_name='D:\Data\Imagery\Temporary\spec'
  envi_select, title='Input Filename', fid=fid, $ 
    pos=pos, dims=dims 
  if (fid eq -1) then return 
  envi_file_query, fid, data_type=data_type, xstart=xstart,$ 
    ystart=ystart, interleave=interleave 
  ns = dims[2] - dims[1] + 1 
  nl = dims[4] - dims[3] + 1 
  nb = n_elements(pos) 
  openw, unit, out_name, /get_lun 
  tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $ 
    interleave=(interleave > 1), xs=dims[1], xe=dims[2], $ 
    ys=dims[3], ye=dims[4]) 
  for i=0L, num_tiles-1 do begin 
    data = envi_get_tile(tile_id, i) 
    writeu, unit, data 
    print, i 
  endfor 
  free_lun, unit 
  envi_setup_head, fname=out_name, ns=ns, nl=nl, nb=nb, $ 
    data_type=data_type, offset=0, interleave=(interleave > 1),$ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], $ 
    descrip='Test routine output', /write, /open 
  envi_tile_done, tile_id 
end