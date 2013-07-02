pro window_group_event, event

WIDGET_CONTROL, event.TOP, GET_UVALUE=stash
uname = WIDGET_INFO(event.ID, /UNAME) ; or event.id?
help, uname

; Using a CASE switch to handle different events
; img base, img window, scroll base, scroll window, zoom base, zoom window
CASE uname OF
    'Image Base': BEGIN
        print, 'Image Base'
        IF (TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_BASE') THEN BEGIN
        ;print, ev
        ;help, ev, /structure
        ;print, tag_names(ev)
            widget_control, stash.ImWindow, draw_xsize=event.x, draw_ysize=event.y
            ;print, ev.x
            ;print, ev.y
            wset, stash.ImageWindowId
            erase
            tvscl, *stash.img, /order
            widget_control, event.Top, set_uvalue=stash, tlb_get_size=wsize, tlb_get_offset=ofset
            baseGeom = Widget_Info(event.Top, /Geometry)

            ;print, wsize
            ;print, ofset
            ;help, baseGeom, /structure

            ;widget_control, stash.draw2, tlb_set_xoffset=ofset[0], tlb_set_yoffset= $
            ;         wsize[1]+ofset[1]+36
            widget_control, stash.ScWindow, tlb_set_xoffset=baseGeom.xoffset, tlb_set_yoffset=$
                          baseGeom.yoffset+baseGeom.scr_ysize
            ;widget_control, stash.draw2, tlb_get_offset=ofset2, tlb_get_size=wsize2
            p = widget_info(stash.ScWindow, /parent)
            ;print, p
            baseGeom2 = Widget_Info(p, /Geometry)
            ;help, baseGeom2, /structure
            widget_control, stash.ZmWindow, tlb_set_xoffset=baseGeom2.xoffset+baseGeom2.scr_xsize, $
                             tlb_set_yoffset=baseGeom2.yoffset
        ENDIF
        IF (TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_TLB_MOVE') THEN BEGIN
            ;widget_control, ev.top, set_uvalue=stash, tlb_get_size=wsize, tlb_get_offset=ofset
            baseGeom = Widget_Info(event.Top, /Geometry)
            ;help, baseGeom, /struc
            ;widget_control, stash.draw2, tlb_set_xoffset=ofset[0], tlb_set_yoffset=$
                    ;wsize[1]+ofset[1]+36
            widget_control, stash.ScWindow, tlb_set_xoffset=baseGeom.xoffset, tlb_set_yoffset=$
                     baseGeom.yoffset + baseGeom.scr_ysize
            ;widget_control, stash.draw2, tlb_get_offset=ofset2, tlb_get_size=wsize2
            p = widget_info(stash.ScWindow, /parent)
            baseGeom2 = Widget_Info(p, /Geometry)
            ;widget_control, stash.draw3, tlb_set_xoffset=ofset2[0]+wsize2[0]+9, $
                     ;tlb_set_yoffset=ofset2[1]
            widget_control, stash.ZmWindow, tlb_set_xoffset=baseGeom2.xoffset+baseGeom2.scr_xsize, $
                       tlb_set_yoffset=baseGeom2.yoffset
        ENDIF

        widget_control, event.top, set_uvalue=stash, /no_copy



        ENDCASE
    'Image Window': BEGIN
        print, 'Image Window'
        IF (TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_DRAW') THEN BEGIN
            ;print, tag_names(ev)
            IF event.press EQ 1 THEN BEGIN
                Widget_Control, stash.ImWindow, Draw_Motion_Events=1

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
                tvscl, *stash.img, /order

                x = [event.x-25, event.x+25, event.x+25, event.x-25, event.x-25]
                y = [event.y-25, event.y-25, event.y+25, event.y+25, event.y-25]
                ;y = [stash.ioffset -(ev.y-25), stash.ioffset -(ev.y-25), $
                ;    stash.ioffset -(ev.y+25), stash.ioffset -(ev.y+25),$
                ;    stash.ioffset -(ev.y-25)]
                plots, x, y, /device
                ;endwhile
            ENDIF
            IF event.type EQ 2 THEN BEGIN
                ;print, ev.x
                ;print, ev.y

                tvscl, *stash.img, /order

                x = [event.x-25, event.x+25, event.x+25, event.x-25, event.x-25]
                y = [event.y-25, event.y-25, event.y+25, event.y+25, event.y-25]
                plots, x, y, /device

            ENDIF
            IF event.type EQ 1 THEN BEGIN
                Widget_Control, stash.ImWindow, Draw_Motion_Events=0
            ENDIF
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
        ENDIF


        ENDCASE
    'Scroll Base': BEGIN
        print, 'Scroll Base'

        ENDCASE
    'Scroll Window': BEGIN
        print, 'Scroll Window'

        ENDCASE
    'Zoom Base': BEGIN
        print, 'Zoom Base'

        ENDCASE
    'Zoom Window': BEGIN
        print, 'Zoom Window'
        if (event.release eq 1) then begin
        ;get click coords
            print, event.x
            print, event.y
            x = [1,14,14,1,1]
            y = [1,1,14,14,1]
            minx1 = min(x, max=maxx1)
            minx2 = min(x + 15, max=maxx2)
            minx3 = min(x + 30, max=maxx3)
            miny = min(y, max=maxy)
            if ((event.y ge miny) and (event.y le maxy)) eq 1 then begin
                if((event.x ge minx1) and (event.x le maxx1)) eq 1 then begin
                    print, 'minus'
                endif else begin
                    if ((event.x ge minx2) and (event.x le maxx2)) eq 1 then begin
                        print, 'plus'
                    endif else begin
                        if ((event.x ge minx3) and (event.x le maxx3)) eq 1 then begin
                            print, 'crosshair'
                        endif
                    endelse
                endelse
            endif
        endif


        ENDCASE
ENDCASE
END

pro window_group;, img

img = dist(1000)

; Maybe specify: event_pro='pro name' for events that occur at each base?
; Rather than use xmanager?
;base = widget_base(tlb_size_events=1, tlb_move_events=1, title='Image')

; Set up the Image Window
ImBase = widget_base(tlb_size_events=1, tlb_move_events=1, title='Image', $
                    event_pro='window_group_event', uname='Image Base')

ImWindow = WIDGET_DRAW(ImBase, XSIZE=400, YSIZE=400, /button_events, uname='Image Window')

widget_control, ImBase, /realize
WIDGET_CONTROL, ImWindow, GET_VALUE=ImageWindowID, tlb_get_size=ImWsize
widget_control, ImBase, tlb_get_size=ImBsize, tlb_get_offset=ImBoffset
ImBaseGeom = Widget_Info(ImBase, /Geometry)
wset, ImageWindowId
tvscl, img[0:399,0:399], /order

; Display co-ordinates: Origin = LL corner
; Image co-ordinates:   Origin = UL corner
; image to display is offset - iy ; changed to be just the size of the image
; display to image is offset - dy ; no -1
ImXoffset = ImWsize[0] -1
ImYoffset = ImWsize[1] -1


; Create the image window box
;
; Box co-ords will be ordered like this
;
;  1----2
;  |    |
;  |    |
;  4----3
;
inx = ImWsize[0]/8
iny = ImWsize[1]/8
;starting co-ords. Will create the box in the centre of the display
ixo = ImWsize[0]/2 - inx/2
iyo = ImWsize[1]/2 - iny/2
ix = [ixo, ixo + inx, ixo + inx, ixo, ixo]
iy = [ImYoffset-iyo, ImYoffset-iyo, ImYoffset-(iyo + iny), ImYoffset-(iyo + iny), ImYoffset-iyo]
print, 'image box co-ords'
print, ix, iy
print, ix[0], ix[1], iy[2], iy[0]
plots, ix, iy, /device


; Set up the Scroll Window
ScBase = widget_base(group_leader=ImBase, title='Scroll', event_pro='window_group_event', $
                    uname='Scroll Base', tlb_size_events=1)
ScWindow = widget_draw(ScBase, xsize=256,ysize=256, uname='Scroll Window', /BUTTON_EVENTS)
;widget_control, base2, /realize, tlb_set_xoffset=ofset[0], tlb_set_yoffset=wsize[1]+ofset[1]+36
widget_control, ScBase, /realize, tlb_set_xoffset=ImBoffset[0], tlb_set_yoffset=ImBaseGeom.scr_ysize
widget_control,ScBase, tlb_get_size=ScBsize, tlb_get_offset=ScBoffset
ScBaseGeom = Widget_Info(ScBase, /Geometry)
;help, base2Geom, /structure
widget_control, ScWindow, get_value=ScrollWindowID, tlb_get_size=ScWsize
wset, ScrollWindowID
img2=congrid(img,256, 256)

ScXoffset = ScWsize[0] - 1
ScYoffset = ScWsize[1] - 1

tvscl, img2, /order

; Create the scroll box window
; Calculate the ratio of the full image, to the congrid version
ImgDims = float(size(img, /dimensions))
ScrDims = float(size(img2, /dimensions))
RatioX = ImgDims[0]/ScrDims[0]
RatioY = ImgDims[1]/ScrDims[1]
; The initial position of the box is the top left corner of the display
; Plotting will use display co-ordinates
;sxo = ScXoffset - 0
sxo = 0
syo = ScYoffset - 0
;sxe = ScXoffset - floor((ImWsize[0]/RatioX))
sxe = floor(ImWsize[0]/RatioX)
sye = ScYoffset - floor((ImWsize[1]/RatioY))
sx  = [sxo, sxe, sxe, sxo, sxo]
sy  = [syo, syo, sye, sye, syo]
print, sx, sy
plots, sx, sy, /DEVICE

; the following would be used to index the image in order to display on the image window
;startimgxcoord = 0
;endimgxcoord   = ScrDims[0] - 1
;startimgycoord = ScYoffset-0
;endimgycoord   = ScYoffset-(ScrDims[1] - 1)
;sxo = floor(startimgxcoord/ratiox)
;syo = floor(startimgycoord/ratioy)
;sxe = floor(endimgxcoord/ratiox)
;sye = floor(endimgycoord/ratioy)
;sbxlength = sxe - sxo
;sbylength = sye - syo

; Set up the Zoom Window
;base3 = widget_base(group_leader=base, title='Zoom', event_pro='zoom_event', $
;                    tlb_size_events=1, uname='Zoom Base')
ZmBase = widget_base(group_leader=ImBase, title='Zoom', event_pro='window_group_event', $
                    tlb_size_events=1, uname='Zoom Base')

ZmWindow = widget_draw(ZmBase, xsize=200,ysize=200, /button_events, uname='Zoom Window')
widget_control, ZmBase, /realize, tlb_set_xoffset=ScBaseGeom.scr_xsize, $
               tlb_set_yoffset=ScBoffset[1]
widget_control, ZmWindow, get_value=ZoomWindowId, tlb_get_size=ZmWsize

wset, ZoomWindowId

; Creating the actual zoom. Get the box coordinates.
; Initially there shouldn't be any array indexing offsets from the image display
; as the image will load by default the first [400,400].
print, ix[0], ix[1]
print, iy[2], iy[0]
zoomed = congrid(img[ix[0]:ix[1], iy[2]:iy[0]], ZmWsize[0], ZmWsize[1])
tvscl, zoomed, /order


; Zoom window controls (bottom left corner of display)
x=[1,14,14,1,1]
y=[1,1,14,14,1]
xm = [3,12]
ym = [7,7]
xp = [7,7]
yp = [3,12]
;tvscl, img3
plots, x,y, /device
plots, x+15,y, /device
plots, x+30,y, /device
plots, xm, ym, /device
plots, xm+15, ym, /device
plots, xp+15, yp, /device

; Create pointers for the images
imgPtr = PTR_NEW(img, /NO_COPY)
scrPtr = PTR_NEW(img2, /NO_COPY)
zm_Ptr = PTR_NEW(zoomed, /NO_COPY)

; Storing variables in a structure to pass to the events procedure
stash = {img:imgPtr, $
         scimg:scrPtr, $
         zmimg:zm_Ptr, $
         imgbox:[ix,iy], $
         scrbox:[sx,sy], $
         ImWindow:ImWindow, $
         ImageWindowId:ImageWindowId, $
         ScWindow:ScWindow, $
         ScrollWindowID:ScrollWindowID, $
         ZmWindow:ZmWindow, $
         ZoomWindowId:ZoomWindowId, $
         RatioX:RatioX, $
         RatioY:RatioY, $
         ImgDims:ImgDims, $
         ScrDims:ScrDims, $
         ImXoffset:ImXoffset, $
         ImYoffset:ImYoffset, $
         ScXoffset:ScXoffset, $
         ScYoffset:ScYoffset, $
         ImXstart:0, $
         ImYstart:0 $
        }
WIDGET_CONTROL, ImBase, SET_UVALUE=stash
xmanager, 'window_group', ImBase, /NO_BLOCK
end
