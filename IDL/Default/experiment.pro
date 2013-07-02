PRO experiment_event, ev                                          ; event handler
  widget_control, ev.id, get_uvalue=uvalue                        ; get the uvalue

  CASE uvalue OF                                                  ; choose case
  'go'  : print, 'GO button'                                      ; GO button
  'draw': print, 'draw event', ev.x, ev.y, ev.press, ev.release   ; graphics event
  END
END

PRO experiment
  main = widget_base (title='A401 experiments')             ; main base
  cntl = widget_base (main, /column, /frame)
  btn = widget_button (main, uvalue='go', value='GO')             ; GO button
  draw = widget_draw (main, uvalue='draw', /button, xsize=500, ysize=500)               ; graphics pane
  sld = widget_slider (cntl, title='A', min=0, max=100, value=10, uval='a')     ; slider
  widget_control, main, /realize                                  ; create the widgets
  xmanager, 'experiment', main, /no_block                         ; wait for events
END

