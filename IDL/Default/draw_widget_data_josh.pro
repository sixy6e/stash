;  $Id: //depot/idl/IDL_70/idldir/examples/doc/widgets/draw_widget_data.pro#1 $

;  Copyright (c) 2005-2007, ITT Visual Information Solutions. All
;       rights reserved.
;
; This program is used as an example in the "Widget Application Techniques"
; chapter of the _Building IDL Applications_ manual.
;

; Event handler routine.
PRO draw_widget_data_josh_event, ev

  COMPILE_OPT hidden

  ; Retrieve the anonymous structure contained in the user value of
  ; the top-level base widget.

  WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash

  ; If the event is generated in the draw widget, update the
  ; label values with the current cursor position and the value
  ; of the data point under the cursor. Note that since we have
  ; passed a pointer to the image array rather than the array
  ; itself, we must dereference the pointer in the 'image' field
  ; of the stash structure before getting the subscripted value.

  IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
    ;WIDGET_CONTROL, stash.label1, $
    ;  SET_VALUE='X position: ' + STRING(ev.X)
    ;WIDGET_CONTROL, stash.label2, $
    ;  SET_VALUE='Y position: ' + STRING(215-ev.Y)
    ;WIDGET_CONTROL, stash.label3, $
    ;  SET_VALUE='Hex Value: ' + $
    ;  STRING((*stash.imagePtr)[ev.X, 215-ev.Y], FORMAT='(Z12)')

    x = ev.x
    y = ev.y
    WIDGET_CONTROL, stash.label3, $
      SET_VALUE='Noff Value: ' + STRING((*stash.imagePtr)[x,y], FORMAT='(I12)')
    WIDGET_CONTROL, stash.label4, $
      SET_VALUE='Off Value: ' + STRING((*stash.imagePtr)[ev.X,215-ev.Y])

    print, string(ev.x), ev.y
    ;print, (*stash.imageptr)[ev.x, ev.y]

    ;WIDGET_CONTROL, stash.label5, $
    ;  SET_VALUE='Hex Value: ' + $
    ;  STRING((*stash.imagePtr)[ev.X, 215-ev.Y], FORMAT='(Z12)')
    ;WIDGET_CONTROL, stash.label4, $
    ;  SET_VALUE='Non-offset Value: ' + STRING((*stash.imagePtr)[ev.X,ev.Y])
    ;WIDGET_CONTROL, stash.label5, $
    ;  SET_VALUE='Offset Value: ' + STRING((*stash.imagePtr)[ev.X,215-ev.Y])

  ENDIF

  ; If the event is generated in a button, destroy the widget
  ; hierarchy. We know we can use this simple test because there
  ; is only one button in the application.

  IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_BUTTON') THEN BEGIN
    WIDGET_CONTROL, ev.TOP, /DESTROY
  ENDIF

END

;pro draw_resize_tlb_resize, ev
;widget_control, ev.top, get_uvalue=stash, /no_copy
;widget_control, stash.drawid, draw_xsize=ev.x, draw_ysize=ev.y
;wset, stash.drawid
;erase
;tvscl, *imagePtr
;widget_control, ev.top, set_uvalue=stash, /no_copy
;end

PRO draw_widget_data_josh

  ; Define a monochrome image array for use in the application.
  READ_PNG, FILEPATH('mineral.png', SUBDIR=['examples', 'data']), image

  ; Place the image array in a pointer heap variable, so we can pass
  ; the pointer to the event routine rather than passing the entire
  ; image array.
  imagePtr=PTR_NEW(image, /NO_COPY)

  ; An alternative image array
  ;imagePtr = PTR_NEW(BYTE(DIST(200)), /NO_COPY)

  ; Retrieve the size information from the image array.
  im_size=SIZE(*imagePtr)

  ; Create a base widget to hold the application.
  ;base = WIDGET_BASE(/COLUMN, tlb_move_events=1, tlb_size_events=1)
  base = WIDGET_BASE(/COLUMN, tlb_size_events=1)

  ; Create a draw widget based on the size of the image, and
  ; set the MOTION_EVENTS keyword so that events are generated
  ; as the cursor moves across the image. Setting the BUTTON_EVENTS
  ; keyword rather than MOTION_EVENTS would require the user to click
  ; on the image before an event is generated.
  draw = WIDGET_DRAW(base, XSIZE=im_size[1], YSIZE=im_size[2], $
    /MOTION_EVENTS)

  ; Create 'Done' button.
  button = WIDGET_BUTTON(base, VALUE='Done')

  ; Create label widgets to hold the cursor position and Hexadecimal
  ; value of the pixel under the cursor.
  ;label1 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
  ;  VALUE='X position:')
  ;label2 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
  ;  VALUE='Y position:')
  ;label3 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
  ;  VALUE='Hex Value:')

  label3 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
    VALUE='Noff Value:')
  label4 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
    VALUE='Off Value:')
  ;label5 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
  ;  VALUE='Hex Value:')

;  label4 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
;    VALUE='Noff Value:')
;  label5 = WIDGET_LABEL(base, XSIZE=im_size[1]*.9, $
;    VALUE='Off Value:')



  ; Realize the widget hierarchy.
  WIDGET_CONTROL, base, /REALIZE

  ; Retrieve the widget ID of the draw widget. Note that the widget
  ; hierarchy must be realized before you can retrieve this value.
  WIDGET_CONTROL, draw, GET_VALUE=drawID

  ; Create an anonymous array to hold the image data and widget IDs
  ; of the label widgets.
  ;stash = { imagePtr:imagePtr, label1:label1, label2:label2, $
  ;         label3:label3 }

  ; Set the user value of the top-level base widget equal to the
  ; 'stash' array.
  ;WIDGET_CONTROL, base, SET_UVALUE=stash

  ; Make the draw widget the current IDL drawable area.
  WSET, drawID

  ;stash = { imagePtr:imagePtr, label1:label1, label2:label2, $
  ;          label3:label3, drawid:drawid, draw:draw, label4:label4, $
  ;          label5:label5}

  stash = { imagePtr:imagePtr, label3:label3, drawid:drawid, draw:draw, label4:label4}

  WIDGET_CONTROL, base, SET_UVALUE=stash

  ; Draw the image into the draw widget.
  TVSCL, *imagePtr

  ;base2 = widget_base(group_leader=base)
  ;draw2 = widget_draw(base2, xsize=125,ysize=125, /motion_events)
  ;widget_control, base2, /realize
  ;widget_control, draw2, get_value=drawid2
  ;wset, drawid2
  ;img2=dist(125)
  ;tvscl, img2

  ; Call XMANAGER to manage the widgets.
  XMANAGER, 'draw_widget_data_josh', base, /NO_BLOCK
  ;XMANAGER, 'draw_widget_data_josh', base, event_handler=draw_resize_tlb_resize, /NO_BLOCK

END
