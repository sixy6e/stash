; Resize event handler
PRO basic_draw_doc_event, event

  ; Get the state structure. Use WIDGET_CONTROL
  ; to copy the state structure into a
  ; local "state" variable.
  WIDGET_CONTROL, event.top, GET_UVALUE=state

  ; The new x and y sizes of the base widget are stored
  ; in the event.x and event.y variables. The size of the
  ; base widget defines the width and height of the
  ; draw window (event.x and event.y)
  state.width=event.x
  state.height=event.y

  ; Resize the draw widget. The widgetID for the draw widget
  ; is taken from the state structure (state.draw).
  ; The DRAW_XSIZE and DRAW_YSIZE keywords to WIDGET_CONTROL
  ; resize the draw widget, based on the new x and y sizes
  ; (event.x and event.y). The size of the base2 widget,
  ; (which contains the controls) is subtracted
  ; so that the draw window resizes correctly.
  WIDGET_CONTROL, state.draw, Draw_XSize=event.x,  $
    Draw_YSize=event.y - state.base2_ysize

  ; Use CONGRID to resize the image based on the
  ; top-level base widget's size, taken from the
  ; state structure. The /CENTER keyword centers the image.
  TV, CONGRID(*(state.image), event.x, $
    event.y - state.base2_ysize, /CENTER)

  ; Store the state structure.
  WIDGET_CONTROL, event.top, SET_UVALUE=state
END

; Event handler for the droplist widget.
PRO basic_draw_doc_droplist, event

  ; Get the state structure. Use WIDGET_CONTROL
  ; to copy the state structure into a
  ; local "state" variable.
  WIDGET_CONTROL, event.TOP, GET_UVALUE=state

  ; The case statement lists the images to choose from
  ; in the dropdown list.  Users can select only one of
  ; these options. The case statement begins with CASE
  ; and concludes with ENDCASE. Each image file corresponds
  ; to the names listed in the "select" variable in basic_draw_doc.
  CASE event.index OF
    0 : BEGIN
      file = FILEPATH('pdthorax124.jpg', $
        SUBDIR=['examples', 'data'])
    END
    1 : BEGIN
      file = FILEPATH('md1107g8a.jpg', $
        SUBDIR=['examples', 'data'])
    END
    2 : BEGIN
      file = FILEPATH('md5290fc1.jpg', $
        SUBDIR=['examples', 'data'])
    END
  ENDCASE

  ; Define the image variable to read the image selected.
  image = READ_IMAGE(file)

  ; Store the new image selection back into the state structure.
  *(state.image)=image

  ; Set the user value to state.
  WIDGET_CONTROL, event.top, SET_UVALUE=state

  ; Use CONGRID to resize the image based on the
  ; top-level base widget's size, taken from the
  ; state structure. The /CENTER keyword centers the image.
  ; If the draw widget has not been resized or if its
  ; height is less than or equal to 200, use the
  ; first CONGRID command.
  ; If the draw widget has been resized, use the
  ; other CONGRID command that calculates the size
  ; of the base2 widget.

  IF state.height LE 200 then BEGIN
    TV, CONGRID(*(state.image), state.width, $
      state.height, /CENTER)
  ENDIF ELSE BEGIN
    TV, CONGRID(*(state.image), state.width, $
      state.height - state.base2_ysize, /CENTER)
  ENDELSE
END

; Event handler for the Done button.
PRO basic_draw_doc_done, event

  ; Destroy the top-level widget
  ; (which destroys all other widgets).
  WIDGET_CONTROL, event.top, /DESTROY
END

; Cleanup procedure cleans up the pointers on closing the widget.
PRO basic_draw_doc_cleanup, base

  ; Clean up pointers.
  WIDGET_CONTROL, base, GET_UVALUE=state
  IF N_Elements(state) EQ 0 THEN RETURN
  PTR_FREE, state.image
END


; The main routine that defines the widgets.
PRO basic_draw_doc

  ; Create the top-level base (TLB) widget.
  ; The base variable contains the widget id of the
  ; base widget, which will contain all the other widgets.
  ; The WIDGET_BASE routine uses the COLUMN keyword to layout
  ; the widgets in a column orientation.
  ; The TLB_SIZE_EVENTS keyword tells the widget
  ; to return resize events.
  base = WIDGET_BASE(COLUMN=1, TITLE='Widget Example', $
    TLB_SIZE_EVENTS=1, xpad=0, ypad=0, /ALIGN_CENTER)

  ; Create the draw widget with a size of 200x200 pixels.
  draw = WIDGET_DRAW(base, XSize=200, YSize=200)

  ; Create the base widget that contains the
  ; label, droplist and button widgets.
  base2 = WIDGET_BASE(base, Column=1, $
    xpad=0, ypad=5, /ALIGN_CENTER)

  ; Create a variable containing the values
  ; to choose from in the droplist widget.
  select = ['Thorax', 'Head', 'Head and neck']

  ; Create a label for the droplist.
  label = WIDGET_LABEL(base2, VALUE='Select an image:')

  ; Create a droplist widget to select an image.
  ; The values are the items listed in droplist,
  ; defined above by the select variable.
  drop = WIDGET_DROPLIST(base2, VALUE=select, $
    EVENT_PRO='basic_draw_doc_droplist')


  ; Create some space between the dropdown list and the button.
  space = WIDGET_BASE(base2, XSIZE=30)

  ; Create a done button to cancel the window
  button = WIDGET_BUTTON(base2, VALUE='Done', $
      UVALUE='done', $
      EVENT_PRO='basic_draw_doc_done')

  ; Use WIDGET_INFO to determine the size of base2
  ; so that we can subtract that size from the
  ; base widget when it is resized.
  base2Geom = Widget_Info(base2, /Geometry)
  base2_ysize = base2Geom.ysize

  ; Realize the widgets.
  WIDGET_CONTROL, base, /Realize

  ; Create a variable containing an image to display.
  READ_JPEG, FILEPATH('pdthorax124.jpg', $
    SUBDIR=['examples', 'data']), image

  ; Retrieve the window ID from the draw widget.
  WIDGET_CONTROL, draw, GET_VALUE=drawID

  ; Define the widget in which to display the image.
  WSET, drawID
   ; Define the state structure.
state = { image:Ptr_New(image), $
            draw:draw, $
            width:200, $
            height:200, $
            base2_ysize:base2_ysize $
         }

  ; Display the data.
  TVSCL, CONGRID(image, 200, 200, /CENTER)
  WIDGET_CONTROL, base, SET_UVALUE=state
   ; Register the top-level base widget with
  ; XMANAGER by providing the name of the widget program
  XMANAGER, 'basic_draw_doc', base, $
      Cleanup='basic_draw_doc_cleanup';, /no_block


END