pro ud_move_1, dn, xloc, yloc, xstart=xstart, ystart=ystart
 ; Get the file FIDs
  envi_disp_query, dn, fid=fid, pos=pos, color=color
  if (color eq 8) then nb = 3 $
  else nb = 1
; Print the DN and zoom location
  print, dn, xloc + 1, yloc + 1
; Print out the current pixel for each displayed band
  for i=0, nb-1 do begin
    envi_file_query, fid[i], xstart=xstart, ystart=ystart
dims = long([0, $
      xloc - xstart, xloc - xstart, $
      yloc - ystart, yloc - ystart])
print, envi_get_data(fid=fid[i], pos=pos[i], dims=dims)
  endfor
end