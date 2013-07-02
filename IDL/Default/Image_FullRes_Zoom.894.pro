;+
; <PRO IMAGE_FULLRES_ZOOM_EVENT>
; General description of routine
;
; @Param
;   event {in|out} {optional|required} {type=} {default=}
;     No Description
;
; @Author
;   Adam O'Connor
;
; @Copyright
;   Copyright &#169; 2006 ITT Industries. All rights reserved.
;
; @Hidden
;-
PRO IMAGE_FULLRES_ZOOM_EVENT, event
;obtain state structure from uvalue of top-level-base:
widget_control,event.top,get_uvalue=pstate
case event.type of
  0 : begin ;button press:
        case event.press of
          1 : begin ;left mouse button; display 200 x 200 zoom box:
                ;reset flags:
                (*pstate).mouseButton = 1B
                (*pState).withinFlag = 1B
                ;update mouse location:
                (*pstate).currentX = event.x
                (*pstate).currentY = event.y
                ;overlay zoom box:
                lowerLeftX = round(event.x * (*pstate).magFactor) - 100
                lowerLeftY = round(event.y * (*pstate).magFactor) - 100
                device, copy=[lowerLeftX,lowerLeftY,200,200,(event.x-100),(event.y-100),(*pstate).fullID]
                xcoord=[(event.x-100),(event.x+99),(event.x+99),(event.x-100),(event.x-100)]
                ycoord=[(event.y-100),(event.y-100),(event.y+99),(event.y+99),(event.y-100)]
                plots,xcoord,ycoord,color=255,/dev
              end
          2 : begin ;middle mouse button:
                ;do nothing
              end
          4 : begin ;right mouse button; display 400 x 400 zoom box:
                ;reset flags:
                (*pstate).mouseButton = 4B
                (*pState).withinFlag = 1B
                ;update mouse location:
                (*pstate).currentX = event.x
                (*pstate).currentY = event.y
                ;overlay zoom box:
                lowerLeftX = round(event.x * (*pstate).magFactor) - 200
                lowerLeftY = round(event.y * (*pstate).magFactor) - 200
                device, copy=[lowerLeftX,lowerLeftY,400,400,(event.x-200),(event.y-200),(*pstate).fullID]
                xcoord=[(event.x-200),(event.x+199),(event.x+199),(event.x-200),(event.x-200)]
                ycoord=[(event.y-200),(event.y-200),(event.y+199),(event.y+199),(event.y-200)]
                plots,xcoord,ycoord,color=255,/dev
              end
          else : ;do nothing
        endcase
      end
  1 : begin ;button release
        case event.release of
          1 : begin ;left mouse button:
                (*pstate).mouseButton = 0B
                (*pState).withinFlag = 0B
                (*pstate).currentX = -1L
                (*pstate).currentY = -1L
                ;repair original image:
                device, copy=[0,0,(*pState).drawXSize,(*pState).drawYSize,0,0,(*pstate).subID]
              end
          2 : begin ;middle mouse button:
                ;do nothing
              end
          4 : begin ;right mouse button:
                (*pstate).mouseButton = 0B
                (*pState).withinFlag = 0B
                (*pstate).currentX = -1L
                (*pstate).currentY = -1L
                ;repair original image:
                device, copy=[0,0,(*pState).drawXSize,(*pState).drawYSize,0,0,(*pstate).subID]
              end
          else : ;do nothing
        endcase
      end
  2 : begin ;button motion
        if (*pstate).mouseButton eq 1 then begin ;left-mouse button currently pressed:
          ;determine if mouse cursor is outside image display:
          outsideFlag = (event.x gt (*pState).drawXSize-1) or (event.y gt (*pState).drawYSize-1) or $
                        (event.x lt 0) or (event.y lt 0)
          ;if mouse cursor has come back inside image from outside then reset flag:
          if outsideFlag eq 0 then (*pState).withinFlag = 1B
          ;if mouse cursor has just moved outside image then set flag and repair image:
          if (*pState).withinFlag eq 1 and outsideFlag eq 1 then begin
            ;set flag to "outside image":
            (*pState).withinFlag = 0
            ;repair original image:
            device, copy=[0,0,(*pState).drawXSize,(*pState).drawYSize,0,0,(*pstate).subID]
          endif
          ;if mouse cursor is outside image then don't do anything:
          if outsideFlag eq 1 then return
          ;repair original image where zoom box used to be:
          xDiff = event.x - (*pState).currentX
          yDiff = event.y - (*pState).currentY
          if xDiff NE 0 then begin ;cursor moved horizontally:
            if xDiff gt 0 then begin ;box moved right:
              device, copy=[((*pState).currentX-100),((*pState).currentY-100),xDiff,200,((*pState).currentX-100),((*pState).currentY-100),(*pstate).subID]
            endif else begin ;box moved left:
              device, copy=[((*pState).currentX+100+xDiff),((*pState).currentY-100),-(xDiff),200,((*pState).currentX+100+xDiff),((*pState).currentY-100),(*pstate).subID]
            endelse
          endif
          if yDiff NE 0 then begin ;cursor moved vertically:
            if yDiff gt 0 then begin ;box moved up:
              device, copy=[((*pState).currentX-100),((*pState).currentY-100),200,yDiff,((*pState).currentX-100),((*pState).currentY-100),(*pstate).subID]
            endif else begin ;box moved down:
              device, copy=[((*pState).currentX-100),((*pState).currentY+100+yDiff),200,-(yDiff),((*pState).currentX-100),((*pState).currentY+100+yDiff),(*pstate).subID]
            endelse
          endif
          ;update mouse location:
          (*pstate).currentX = event.x
          (*pstate).currentY = event.y
          ;overlay zoom box:
          lowerLeftX = round(event.x * (*pstate).magFactor) - 100
          lowerLeftY = round(event.y * (*pstate).magFactor) - 100
          device, copy=[lowerLeftX,lowerLeftY,200,200,(event.x-100),(event.y-100),(*pstate).fullID]
          xcoord=[(event.x-100),(event.x+99),(event.x+99),(event.x-100),(event.x-100)]
          ycoord=[(event.y-100),(event.y-100),(event.y+99),(event.y+99),(event.y-100)]
          plots,xcoord,ycoord,color=255,/dev
        endif
        if (*pstate).mouseButton eq 4 then begin ;right-mouse button currently pressed:
          ;determine if mouse cursor is outside image display:
          outsideFlag = (event.x gt (*pState).drawXSize-1) or (event.y gt (*pState).drawYSize-1) or $
                        (event.x lt 0) or (event.y lt 0)
          ;if mouse cursor has come back inside image from outside then reset flag:
          if outsideFlag eq 0 then (*pState).withinFlag = 1B
          ;if mouse cursor has just moved outside image then set flag and repair image:
          if (*pState).withinFlag eq 1 and outsideFlag eq 1 then begin
            ;set flag to "outside image":
            (*pState).withinFlag = 0
            ;repair original image:
            device, copy=[0,0,(*pState).drawXSize,(*pState).drawYSize,0,0,(*pstate).subID]
          endif
          ;if mouse cursor is outside image then don't do anything:
          if outsideFlag eq 1 then return
          ;repair original image where zoom box used to be:
          xDiff = event.x - (*pState).currentX
          yDiff = event.y - (*pState).currentY
          if xDiff NE 0 then begin ;cursor moved horizontally:
            if xDiff gt 0 then begin ;box moved right:
              device, copy=[((*pState).currentX-200),((*pState).currentY-200),xDiff,400,((*pState).currentX-200),((*pState).currentY-200),(*pstate).subID]
            endif else begin ;box moved left:
              device, copy=[((*pState).currentX+200+xDiff),((*pState).currentY-200),-(xDiff),400,((*pState).currentX+200+xDiff),((*pState).currentY-200),(*pstate).subID]
            endelse
          endif
          if yDiff NE 0 then begin ;cursor moved vertically:
            if yDiff gt 0 then begin ;box moved up:
              device, copy=[((*pState).currentX-200),((*pState).currentY-200),400,yDiff,((*pState).currentX-200),((*pState).currentY-200),(*pstate).subID]
            endif else begin ;box moved down:
              device, copy=[((*pState).currentX-200),((*pState).currentY+200+yDiff),400,-(yDiff),((*pState).currentX-200),((*pState).currentY+200+yDiff),(*pstate).subID]
            endelse
          endif
          ;update mouse location:
          (*pstate).currentX = event.x
          (*pstate).currentY = event.y
          ;overlay zoom box:
          lowerLeftX = round(event.x * (*pstate).magFactor) - 200
          lowerLeftY = round(event.y * (*pstate).magFactor) - 200
          device, copy=[lowerLeftX,lowerLeftY,400,400,(event.x-200),(event.y-200),(*pstate).fullID]
          xcoord=[(event.x-200),(event.x+199),(event.x+199),(event.x-200),(event.x-200)]
          ycoord=[(event.y-200),(event.y-200),(event.y+199),(event.y+199),(event.y-200)]
          plots,xcoord,ycoord,color=255,/dev
        endif
      end
  else : ;do nothing
endcase
END

;+
; <PRO IMAGE_FULLRES_ZOOM_CLEANUP>
; General description of routine
;
; @Param
;   widgetID {in|out} {optional|required} {type=} {default=}
;     No Description
;
; @Author
;   Adam O'Connor
;
; @Copyright
;   Copyright &#169; 2006 ITT Industries. All rights reserved.
;
; @Hidden
;-
PRO IMAGE_FULLRES_ZOOM_CLEANUP, widgetID
;obtain state structure:
widget_control,widgetID,get_uvalue=pstate
;delete the pixmap windows:
if size((*pState).subID,/type) NE 0 then wdelete,(*pState).subID
if size((*pState).fullID,/type) NE 0 then wdelete,(*pState).fullID
;free heap memory:
if ptr_valid(pstate) then ptr_free,temporary(pstate)
END


;+
; <PRO IMAGE_FULLRES_ZOOM>
;   The purpose of this program is to demonstrate a methodlogy to display large images
;   and provide full resolution zoom box overlay functionality.  This program is meant
;   to be used with large image files that have a spatial size that exceeds the
;   monitor's current display area.  This program currently supports the input of image
;   files in either TIFF or JPEG format.<BR>
;   <BR>
;   User-Contributed Library webpage :
;   <A HREF="http://www.rsinc.com/codebank/search.asp?FID=196">http://www.rsinc.com/codebank/search.asp?FID=196</A>
;
; @Author
;   Adam O'Connor<BR>
;   <A HREF="mailto:adam_e_oconnor\@yahoo.com">&lt;adam_e_oconnor\@yahoo.com&gt;</A>
;
; @Copyright
;   Copyright &#169; 2006 ITT Industries. All rights reserved.
;
; @Categories
;   Direct_Graphics, Visualization, Graphic, Image, Full, Resolution, Zoom, Box, Widget
;
; @Examples
;   IDL> image_fullres_zoom <BR>
;   <BR>
;   NOTE: An example dataset is included with this program in the "Data" subfolder.
;
; @History
;   Created: December, 2002
;
; @Requires
;   5.5
;
; @Restrictions
;   Although this program was generated by an ITT employee, it is in no way supported,
;   maintained, warranted, or guaranteed by ITT Industries.  Consequently, the ITT
;   Technical Support Group is not obligated to address questions related to this
;   program.  Use this program at your own risk.
;-
PRO IMAGE_FULLRES_ZOOM
;reset error state system variable and establish catching mechanism:
message,/reset_error_state
catch, error
;if error occurred display message and terminate program:
if error NE 0 then begin
  if !ERROR_STATE.NAME EQ 'IDL_M_GRAPHICS_CNTMKPIXMAP' then begin
    memReq = round((((info.dimensions[0] * info.dimensions[1] * screenDepth) / 8D) / 1024D) /1024D)
    dummy=dialog_message(['IDL was unable to obtain the necessary video resources (VRAM) needed to execute',$
                          'this program according to the visual depth of the computer monitor display and the',$
                          'spatial size of the selected image file :','',$
                          strtrim(info.dimensions[0],2)+' cols  x  '+strtrim(info.dimensions[1],2)+$
                          ' rows  x  '+strtrim(screenDepth,2)+' bits  =  '+strtrim(memReq,2)+' MB'],$
                          /error,title=!ERROR_STATE.MSG)
    if size(fullID,/type) NE 0 then wdelete,fullID
    if size(subID,/type) NE 0 then wdelete,subID
    if size(tlb,/type) NE 0 then widget_control,tlb,/destroy
    return
  endif else begin
    dummy=dialog_message(!ERROR_STATE.MSG,/error)
    if size(fullID,/type) NE 0 then wdelete,fullID
    if size(subID,/type) NE 0 then wdelete,subID
    if size(tlb,/type) NE 0 then widget_control,tlb,/destroy
    return
  endelse
endif
;ignore beta and development build versions of IDL because string to float conversion will fail:
betaTest=strpos(strlowcase(!VERSION.RELEASE),'beta')
buildTest=strpos(strlowcase(!VERSION.RELEASE),'build')
;check to make sure the version of IDL running is 5.5 or newer:
if betaTest EQ -1 and buildTest EQ -1 then begin
  if float(!VERSION.RELEASE) LT 5.5 then begin
    dummy=dialog_message('IMAGE_FULLRES_ZOOM is only supported in IDL version 5.5 or newer.')
    return
  endif
endif
;obtain infomation about display:
device,get_screen_size=screenSize,get_visual_depth=screenDepth
if screenDepth LE 8 then begin
  dummy=dialog_message('IMAGE_FULLRES_ZOOM requires the monitor to be setup in TrueColor (16-bit) color mode or better !')
  return
endif
;prompt user to select file on disk:
file=dialog_pickfile(title='Select JPEG or TIFF format image file to open',/must_exist,$
                     filter=['*.TIFF','*.TIF','*.tiff','*.tif','*.JPEG','*.jpeg','*.JPG','*.jpg'])
;if user hit "Cancel" then return:
if file eq '' then return
;parse filename extension:
extension=strupcase(strmid(file,strpos(file,'.',/reverse_search)+1))
;check file validity:
if extension NE 'TIFF' and extension NE 'TIF' and extension NE 'JPEG' and extension NE 'JPG' then begin
  dummy=dialog_message(['Unable to determine image format of selected file according to its extension :','',file])
  return
endif
if extension EQ 'JPG' or extension EQ 'JPEG' then begin
  result=query_jpeg(file,info)
  if result EQ 0 then begin
    dummy=dialog_message(['Selected file :','',file,'','does not appear to be a valid JPEG file !'])
    return
  endif
endif
if extension EQ 'TIF' or extension EQ 'TIFF' then begin
  result=query_tiff(file,info)
  if result EQ 0 then begin
    dummy=dialog_message(['Selected file :','',file,'','does not appear to be a valid TIFF file !'])
    return
  endif
  if info.orientation NE 0 and info.orientation NE 1 and info.orientation NE 4 then begin
    dummy=dialog_message('IMAGE_FULLRES_ZOOM only works with standard orientation TIFF files !')
    return
  endif
endif
;determine appropriate display size:
if info.dimensions[0] LT screenSize[0] and info.dimensions[1] LT screenSize[1] then begin
  drawXSize=info.dimensions[0]
  drawYSize=info.dimensions[1]
  magFactor=1D
  dummy=dialog_message(['IMAGE_FULLRES_ZOOM is meant to be used with images that are larger than the',$
                        'computer monitor display.  The selected image file is small enough to be displayed',$
                        'within the current display.  Consequently, the full resolution zoom functionality',$
                        'does not accomplish anything with the selected file :','',$
                        'Computer Monitor Display Size = '+strtrim(screenSize[0],2)+' x '+strtrim(screenSize[1],2),'',$
                        'Selected Image File Size = '+strtrim(info.dimensions[0],2)+' x '+strtrim(info.dimensions[1],2)],$
                        /info)
endif else begin
  dataRatio = info.dimensions[0] / double(info.dimensions[1])
  screenRatio = screenSize[0] / double(screenSize[1])
  if dataRatio LT screenRatio then begin ;match to Y dimension:
    drawYSize = screenSize[1] - 55
    drawXSize = ROUND(info.dimensions[0] * (drawYSize / double(info.dimensions[1])))
    magFactor = info.dimensions[1] / double(drawYSize)
  endif else begin ;match to X dimension:
    drawXSize = screenSize[0] - 10
    drawYSize = ROUND(info.dimensions[1] * (drawXSize / double(info.dimensions[0])))
    magFactor = info.dimensions[0] / double(drawXSize)
  endelse
endelse
;create display window:
tlb=widget_base(xoff=0,yoff=0,title='Full Resolution Zoom (click with left or right mouse button)',tlb_frame_attr=1)
draw=widget_draw(tlb,xs=drawXSize,ys=drawYSize,/button_events,/motion_events,retain=1)
widget_control,tlb,/realize
widget_control,/hourglass
;read-in image data:
if extension EQ 'JPG' or extension EQ 'JPEG' then begin
  if info.channels EQ 3 then begin
    read_jpeg,file,image,true=1
  endif
  if info.channels EQ 1 then begin
    read_jpeg,file,pseudoimage
    image=bytarr(3,info.dimensions[0],info.dimensions[1])
    image[0,*,*]=pseudoimage
    image[1,*,*]=pseudoimage
    image[2,*,*]=temporary(pseudoimage)
  endif
endif
if extension EQ 'TIF' or extension EQ 'TIFF' then begin
  if info.channels EQ 3 then begin
    image=read_tiff(file,interleave=0,order=order,image_index=0)
    if info.pixel_type NE 1 then image=bytscl(temporary(image))
    if order EQ 1 then begin
      rImage=reform(image[0,*,*])
      rImage=rotate(rImage,7)
      gImage=reform(image[1,*,*])
      gImage=rotate(gImage,7)
      bImage=reform(image[2,*,*])
      bImage=rotate(bImage,7)
      image=bytarr(3,info.dimensions[0],info.dimensions[1])
      image[0,*,*]=temporary(rImage)
      image[1,*,*]=temporary(gImage)
      image[2,*,*]=temporary(bImage)
    endif
  endif
  if info.channels EQ 1 then begin
    pseudoimage=read_tiff(file,red,green,blue,order=order,image_index=0)
    if info.pixel_type NE 1 then pseudoimage=bytscl(temporary(pseudoimage))
    if order EQ 1 then pseudoimage=rotate(temporary(pseudoimage),7)
    if info.has_palette EQ 0 then begin
      red=bindgen(!D.TABLE_SIZE)
      green=bindgen(!D.TABLE_SIZE)
      blue=bindgen(!D.TABLE_SIZE)
    endif
    image=bytarr(3,info.dimensions[0],info.dimensions[1])
    image[0,*,*]=red[pseudoimage]
    image[1,*,*]=green[pseudoimage]
    image[2,*,*]=blue[temporary(pseudoimage)]
  endif
endif
;reduce resolution of image to fit within display:
subsampled=congrid(image,3,drawXSize,drawYSize)
;display subsampled image in display:
widget_control,draw,get_value=drawID
wset,drawID
tv,subsampled,true=1
;create invisible window to hold display of full resolution image:
window,xs=info.dimensions[0],ys=info.dimensions[1],/free,/pixmap
fullID = !D.WINDOW
tv,temporary(image),true=1
;create invisible window to hold copy of subsampled image for repair:
window,xs=drawXSize,ys=drawYSize,/free,/pixmap
subID = !D.WINDOW
tv,temporary(subsampled),true=1
wset,drawID
;create state structure pointer:
pstate=ptr_new({fullID:fullID,subID:subID,mouseButton:0B,magFactor:magFactor,$
                currentX:-1L,currentY:-1L,withinFlag:0B,drawXSize:drawXSize,drawYSize:drawYSize})
;store state structure in uvalue of top-level-base widget:
widget_control,tlb,set_uvalue=pstate
;register widget with event manager:
xmanager,'image_fullres_zoom',tlb,cleanup='image_fullres_zoom_cleanup'
END
