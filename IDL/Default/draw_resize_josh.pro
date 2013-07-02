pro draw_resize_josh_event, ev

COMPILE_OPT hidden
;r=widget_event
;print, r
;uname = widget_info(ev.id,/uname)
;print, uname
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
help, stash
help, ev,  /structure
;print, tag_names(ev)
wset, stash.drawid
IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_BASE') THEN BEGIN
;print, ev
;help, ev, /structure
;print, tag_names(ev)
    widget_control, stash.draw, draw_xsize=ev.x, draw_ysize=ev.y
    ;print, ev.x
    ;print, ev.y
    wset, stash.drawid
    erase
    tvscl, *stash.image, /order
    widget_control, ev.top, set_uvalue=stash, tlb_get_size=wsize, tlb_get_offset=ofset
    baseGeom = Widget_Info(ev.Top, /Geometry)

    ;print, wsize
    ;print, ofset
    ;help, baseGeom, /structure

    ;widget_control, stash.draw2, tlb_set_xoffset=ofset[0], tlb_set_yoffset=wsize[1]+ofset[1]+36
    widget_control, stash.draw2, tlb_set_xoffset=baseGeom.xoffset, tlb_set_yoffset=baseGeom.yoffset+baseGeom.scr_ysize
    ;widget_control, stash.draw2, tlb_get_offset=ofset2, tlb_get_size=wsize2
    p = widget_info(stash.draw2, /parent)
    ;print, p
    baseGeom2 = Widget_Info(p, /Geometry)
    ;help, baseGeom2, /structure
    widget_control, stash.draw3, tlb_set_xoffset=baseGeom2.xoffset+baseGeom2.scr_xsize, $
                             tlb_set_yoffset=baseGeom2.yoffset
endif
IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_TLB_MOVE') THEN BEGIN
    ;widget_control, ev.top, set_uvalue=stash, tlb_get_size=wsize, tlb_get_offset=ofset
    baseGeom = Widget_Info(ev.Top, /Geometry)
    ;help, baseGeom, /struc
    ;widget_control, stash.draw2, tlb_set_xoffset=ofset[0], tlb_set_yoffset=wsize[1]+ofset[1]+36
    widget_control, stash.draw2, tlb_set_xoffset=baseGeom.xoffset, tlb_set_yoffset=baseGeom.yoffset + $
                    baseGeom.scr_ysize
    ;widget_control, stash.draw2, tlb_get_offset=ofset2, tlb_get_size=wsize2
    p = widget_info(stash.draw2, /parent)
    baseGeom2 = Widget_Info(p, /Geometry)
    ;widget_control, stash.draw3, tlb_set_xoffset=ofset2[0]+wsize2[0]+9, tlb_set_yoffset=ofset2[1]
    widget_control, stash.draw3, tlb_set_xoffset=baseGeom2.xoffset+baseGeom2.scr_xsize, $
                       tlb_set_yoffset=baseGeom2.yoffset
endif
;print, 'test'
;print, tag_names(ev)
if (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
    ;print, tag_names(ev)
    if ev.press eq 1 then begin
        Widget_Control, stash.draw, Draw_Motion_Events=1

        ;if ev.type eq 0 then begin
        ;    print, ev.x
        ;    print, ev.y
        ;endif
        ;widget_control, stash.draw, tlb_get_size=wsize
        ;Window, /Free, /Pixmap, XSize=wsize[0], YSize=YSize=wsize[1]
        ;info.pixID = !D.Window
        ;Device, Copy=[0, 0, wsize[0], wsize[1], 0, 0, stash.drawid]
        ;wset, stash.drawid
        ;Device, Copy=[0, 0, wsize[0], wsize[1], 0, 0, stash.pixID]
        ;WDelete, info.pixID
        tvscl, *stash.image, /order

        x = [ev.x-25, ev.x+25, ev.x+25, ev.x-25, ev.x-25]
        y = [ev.y-25, ev.y-25, ev.y+25, ev.y+25, ev.y-25]
        ;y = [stash.ioffset -(ev.y-25), stash.ioffset -(ev.y-25), $
        ;    stash.ioffset -(ev.y+25), stash.ioffset -(ev.y+25),$
        ;    stash.ioffset -(ev.y-25)]
        plots, x, y, /device
        ;endwhile
    endif
    if ev.type eq 2 then begin
        ;print, ev.x
        ;print, ev.y

        tvscl, *stash.image, /order

        x = [ev.x-25, ev.x+25, ev.x+25, ev.x-25, ev.x-25]
        y = [ev.y-25, ev.y-25, ev.y+25, ev.y+25, ev.y-25]
        plots, x, y, /device

    endif
    if ev.type eq 1 then begin
        Widget_Control, stash.draw, Draw_Motion_Events=0
    endif
    ;if ev.motion eq 1 then begin
    ;    print, ev.x
    ;    print, ev.y
    ;endif
    ;if ev.press eq 1 then begin
    ;    print, 'pressed'
    ;    Widget_Control, stash.drawID, Draw_Motion_Events=1
    ;    print, ev.x
    ;    print, ev.y
    ;endif
endif
;help, stash.draw, /structure
;if (ev.release eq 1) then begin
;    print, ev.x
;    print, ev.y
;endif
widget_control, ev.top, set_uvalue=stash, /no_copy
end

pro zoom_event, ev
uname = widget_info(ev.top,/uname)
;print, uname
help, uname
WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
help, stash
;wset, drawid3
;help, ev, /structure
baseGeom = Widget_Info(ev.Top, /Geometry)
;help, baseGeom, /structure
IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_BASE') THEN BEGIN
    widget_control, stash.draw3, draw_xsize=ev.x, draw_ysize=ev.y
    wset, stash.drawid3
    erase
    tvscl, *stash.image
    widget_control, ev.top, set_uvalue=stash, tlb_get_size=wsize, tlb_get_offset=ofset
    baseGeom = Widget_Info(ev.Top, /Geometry)
endif
if (ev.release eq 1) then begin
;get click coords
    print, ev.x
    print, ev.y
    x = [1,14,14,1,1]
    y = [1,1,14,14,1]
    minx1 = min(x, max=maxx1)
    minx2 = min(x + 15, max=maxx2)
    minx3 = min(x + 30, max=maxx3)
    miny = min(y, max=maxy)
    if ((ev.y ge miny) and (ev.y le maxy)) eq 1 then begin
        if((ev.x ge minx1) and (ev.x le maxx1)) eq 1 then begin
            print, 'minus'
        endif else begin
            if ((ev.x ge minx2) and (ev.x le maxx2)) eq 1 then begin
                print, 'plus'
            endif else begin
                if ((ev.x ge minx3) and (ev.x le maxx3)) eq 1 then begin
                    print, 'crosshair'
                endif
            endelse
        endelse
    endif
endif
widget_control, ev.top, set_uvalue=stash, /no_copy
end

pro scroll_event, ev
PRINT, 'Event structure type: ', TAG_NAMES(ev, /STRUCTURE_NAME)
WIDGET_CONTROL, ev.top, GET_UVALUE=stash2
;help, ev, /structure
;help, ev.top
help, stash2
p = widget_info(ev.id, /parent)
help, p
d = widget_info(p, /parent)
help, d
widget_control, p, get_uvalue=stash2
help, stash2
if (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
    if ev.press eq 1 then begin
        print, 'test'
        ;p = widget_info(stash.draw2)
        ;help, p, /structure
        ;Widget_Control, stash.draw2, Draw_Motion_Events=1
        ;tvscl, *stash.im2, /order
        ;xlength = stash.sbxlength/2
        ;ylentgh = stash.sbylength/2
        ;x = [ev.x-xlength, ev.x+xlength, ev.x+xlength, ev.x-xlength, ev.x-xlength]
        ;y = [ev.y-ylength, ev.y-ylength, ev.y+ylength, ev.y+ylength, ev.y-ylength]
        ;y = [stash.ioffset -(ev.y-25), stash.ioffset -(ev.y-25), $
        ;    stash.ioffset -(ev.y+25), stash.ioffset -(ev.y+25),$
        ;    stash.ioffset -(ev.y-25)]
        ;plots, x, y, /device
    endif
    if ev.type eq 2 then begin
        tvscl, *stash.im2, /order
        xlength = stash.sbxlength/2
        ylentgh = stash.sbylength/2
        x = [ev.x-xlength, ev.x+xlength, ev.x+xlength, ev.x-xlength, ev.x-xlength]
        y = [ev.y-ylength, ev.y-ylength, ev.y+length, ev.y+length, ev.y-length]
        plots, x, y, /device
    endif
    ;if ev.type eq 1 then begin
    ;    Widget_Control, stash.draw, Draw_Motion_Events=0
    ;endif
endif      
widget_control, ev.top, set_uvalue=stash, /no_copy   
end

pro draw_resize_josh

img = dist(1000)

; Maybe specify: event_pro='pro name' for events that occur at each base?
; Rather than use xmanager?
;base = widget_base(tlb_size_events=1, tlb_move_events=1, title='Image')
base = widget_base(tlb_size_events=1, tlb_move_events=1, title='Image', $
                    event_pro='draw_resize_josh_event')

draw = WIDGET_DRAW(base, XSIZE=400, YSIZE=400, /button_events)

widget_control, base, /realize
WIDGET_CONTROL, draw, GET_VALUE=drawID
widget_control, base, tlb_get_size=wsize, tlb_get_offset=ofset
baseGeom = Widget_Info(base, /Geometry)
;print, wsize
;print, baseGeom
;print, baseGeom.xsize
;print, baseGeom.ysize
;help, baseGeom, /structure

wset, drawid
tvscl, img, /order

;stash = {image:ptr_new(img), draw:draw, drawid:drawid}
;widget_control, base, set_uvalue=stash, /no_copy

  base2 = widget_base(group_leader=base, title='Scroll', event_pro='scroll_event')
  draw2 = widget_draw(base2, xsize=256,ysize=256, /button_events)
  ;widget_control, base2, /realize, tlb_set_xoffset=ofset[0], tlb_set_yoffset=wsize[1]+ofset[1]+36
  widget_control, base2, /realize, tlb_set_xoffset=ofset[0], tlb_set_yoffset=baseGeom.scr_ysize
  widget_control,base2, tlb_get_size=wsize2, tlb_get_offset=ofset2
  base2Geom = Widget_Info(base2, /Geometry)
  ;help, base2Geom, /structure
  widget_control, draw2, get_value=drawid2
  wset, drawid2
  img2=congrid(img,256, 256)
  tvscl, img2

  ; the zoom window can hold a congrid of the box in the image window
  ;base3 = widget_base(group_leader=base, title='Zoom')
  base3 = widget_base(group_leader=base, title='Zoom', event_pro='zoom_event', $
                      tlb_size_events=1)
  draw3 = widget_draw(base3, xsize=200,ysize=200, /button_events)
  ;widget_control, base3, /realize, tlb_set_xoffset=ofset2[0]+wsize2[0]+9, $
  ;          tlb_set_yoffset=ofset2[1]
  widget_control, base3, /realize, tlb_set_xoffset=base2Geom.scr_xsize, $
            tlb_set_yoffset=ofset2[1]
  widget_control, draw3, get_value=drawid3, tlb_get_size=wsize3
  ;print, wsize3
  wset, drawid3
  x=[1,14,14,1,1]
  y=[1,1,14,14,1]
  img3=dist(200,200)
  tvscl, img3
  plots, x,y, /device
  plots, x+15,y, /device
  plots, x+30,y, /device
  xm = [3,12]
  ym = [7,7]
  plots, xm, ym, /device
  plots, xm+15, ym, /device
  xp = [7,7]
  yp = [3,12]
  plots, xp+15, yp, /device

; create the image box
wset, drawid
inx = !D.X_SIZE/8
iny = !D.Y_SIZE/8
;starting co-ords. Will create the box in the centre of the display
ixo = !D.X_SIZE/2 - inx/2
iyo = !D.Y_SIZE/2 - iny/2
ix = [ixo, ixo + inx, ixo + inx, ixo, ixo]
iy = [iyo, iyo, iyo + iny, iyo + iny, iyo]
plots, ix, iy, /device

; create the scroll box
; calculate the ratio of the full image, to the congrid version
imgdims = float(size(img, /dimensions))
scrdims = float(size(img2, /dimensions))
ratiox = imgdims[0]/scrdims[0]
ratioy = imgdims[1]/scrdims[0]
idispoffset = !D.Y_Size -1
startimgxcoord = 0
endimgxcoord   = !D.X_SIZE - 1
startimgycoord = idispoffset-0
endimgycoord   = idispoffset-(!D.Y_SIZE - 1)
sxo = floor(startimgxcoord/ratiox)
syo = floor(startimgycoord/ratioy)
sxe = floor(endimgxcoord/ratiox)
sye = floor(endimgycoord/ratioy)
sbxlength = sxe - sxo
sbylength = sye - syo
;scroll box
wset, drawid2
sdispoffset = 255
; maybe when dealing with the moving boxes, don't use offsets. only offset when dealing with
; image coords, but convert back to device when plotting the box?
; image to display is offset - iy
; display to image is offset - dy
;sx = [sxo, sxe, sxe, sxo, sxo]
;sy = [syo, syo, sye, sye, syo]
sx = [sxo, sxe, sxe, sxo, sxo]
sy = [sdispoffset-syo, sdispoffset-syo, sdispoffset-sye, sdispoffset-sye, sdispoffset-syo]
plots, sx, sy, /device

zdispoffset=199
stash = {image:ptr_new(img), draw:draw, drawid:drawid, draw2:draw2, drawid2:drawid2, $
         im2:ptr_new(img2), draw3:draw3, drawid3:drawid3, im3:ptr_new(img3), $
         ibx:ix, iby:iy, PixID:-1, sbx:sx, sby:sy, ioffset:idispoffset, $
         soffset:sdispoffset, zoffet:zdispoffset, sbxlength:sbxlength, $
         sbylength:sbylength}

stash2 = {image:ptr_new(img), draw:draw, drawid:drawid, draw2:draw2, drawid2:drawid2, $
         im2:ptr_new(img2), draw3:draw3, drawid3:drawid3, im3:ptr_new(img3), $
         ibx:ix, iby:iy, PixID:-1, sbx:sx, sby:sy, ioffset:idispoffset, $
         soffset:sdispoffset, zoffet:zdispoffset, sbxlength:sbxlength, $
         sbylength:sbylength}
print, draw, draw2, draw3
;bid = widget_info(base)
;widget_control, drawid2, group_leader=bid
;a = widget_info(base, /all_children)
;b = widget_info(base2)
;c = widget_info(base3)
;print, a
;help, a, /structure
;help, b, /structure
;help, c, /structure
; how to get stash with each widget base?
;widget_control, base3, set_uvalue=stash, /no_copy
widget_control, base, set_uvalue=stash, /no_copy
;widget_control, base2, set_uvalue=stash2, /no_copy
;widget_control, base3, set_uvalue=stash, /no_copy
;widget_control, draw2, set_uvalue=stash, /no_copy
;widget_control, draw3, set_uvalue=stash, /no_copy

;xmanager, 'draw_resize_josh', base, /just_reg
;xmanager, 'draw_resize_josh', base, /no_block
;xmanager, 'zoom', base3, /no_block
end
