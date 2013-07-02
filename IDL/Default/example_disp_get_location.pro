pro example_disp_get_location
  ;
  ; Get all the display numbers and
  ; check to make sure at least one
  ; display is present.
  ;
  display = envi_get_display_numbers()
  if (display[0] eq -1) then return
  ;
  ; Print out the location of the
  ; current pixel for each display
  ;
  for i=0, n_elements(display)-1 do begin
    disp_get_location, display[i], xloc, yloc
    print, display[i], xloc, yloc
  endfor
end