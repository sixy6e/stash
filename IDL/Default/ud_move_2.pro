pro ud_move_2, dn, xloc, yloc, xstart=xstart, ystart=ystart
  common ud_move_2_c, ud_wid, data
  ;
  ; Check for a valid widget id. If the widget ID is not valid
  ; then create the widget, otherwise update the text field.
  ;
  if (n_elements(ud_wid) eq 0) then ud_wid = -1L
  if (widget_info(ud_wid, /valid) eq 0) then begin
    ;
    ; Create the widget used to display the data. Give it a title and
    ; use envi_center to center the widget on the screen. A text widget
    ; is created as a place holder for the user text data.
    ;
    title = 'Custom Move Routine'
    envi_center,  xoff, yoff
    base = widget_base(title=title, xoff=xoff, yoff=yoff, $
      /row, group=envi_main_base())
    sb   = widget_base(base, /column, /frame)
    sb1  = widget_base(sb, /col)
    lab  = widget_label(sb1, value='Line Header Data')
    tw   = widget_text(sb1, value='Data display area.', xs=40, ys=5)
    widget_control,base,/realize
    ;
    ; Use the data structure for any info the you would like to
    ; keep around.
    ;
    data = {tw:tw}
    ud_wid = base

  endif
  ;
  ; Update the text widget with the current information.
  ; For now just display the dn, xloc, yloc, xstart, ystart.
  ;
  msg = ['Display Number ' + string(dn), 'Loc (x,y): ' + string(xloc+1) + $
',' + $
    string(yloc+1), 'Start (x,y): ' + string(xstart+1) + ',' + $
    string(ystart+1)]
  widget_control, data.tw, set_value=msg, /no_copy
end