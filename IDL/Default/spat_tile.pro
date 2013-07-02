pro spat_tile
envi_select, title='Input Filename', fid=fid, $
pos=pos, dims=dims
if (fid eq -1) then return
tile_id = envi_init_tile(fid, pos, interleave=interleave, $
num_tiles=num_tiles, xs=dims[1], xe=dims[2], $
ys=dims[3], ye=dims[4])
for i=0L, num_tiles-1 do begin
data = envi_get_tile(tile_id, i, band_index=band_index)
print, i, band_index
help, data
endfor
envi_tile_done, tile_id
end