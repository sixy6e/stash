pro spec_tile
envi_select, title='Input Filename', fid=fid, $
pos=pos, dims=dims
if (fid eq -1) then return
cd, 'D:\Data\Imagery\Temporary'
out_name='testfl'
envi_file_query, fid, dims=dims, nb=nb, nl=nl, ns=ns, $
      xstart=xstart, ystart=ystart, interleave=interleave
map_info = envi_get_map_info(fid=fid)
tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
interleave=interleave, xs=dims[1], xe=dims[2], $
ys=dims[3], ye=dims[4])
svg=SAVGOL(3,3,0,2)
openw, unit, out_name, /get_lun
for i=0L, num_tiles-1 do begin
data = envi_get_tile(tile_id, i)
filter=CONVOL(data,svg, /EDGE_TRUNCATE)
writeu, unit, filter
;print, i
;help, data
endfor
FREE_LUN, unit
envi_setup_head, fname=out_name, ns=ns, nl=nl, nb=nb, $ 
    data_type=4, offset=0, interleave=2, map_info=map_info, $ 
    xstart=xstart+dims[1], ystart=ystart+dims[3], /write, /open
envi_tile_done, tile_id

end