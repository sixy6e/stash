pro ps_test

;file = 'C:\Program Files\ITT\IDL\IDL80\examples\data\muscle.jpg'
;result = query_jpeg(file, info)
;if result eq 0 then return
;read_jpeg, file, image

image = fltarr(400, 400, 46, /nozero)
openr, lun, 'D:\Data\Imagery\MODIS_Imagery\NDVI\Movie\2008_2009_Cubby', /get_lun
readu, lun, image
close, lun
free_lun, lun

;set the plot output device
mydevice = !D.NAME
set_plot, 'ps'

;page size in cm
xsz = 21.0
ysz = 29.7

;starting co-ordinates (normalised) of 1st image
xstart = 0.02
ystart = 0.88

;step size (normalised units) for image placement
xstep = 0.16
ystep = 0.12

;ending co-ordinates (normalised
xend = 0.83
yend = 0.02

;image size (normalised units)
ximg = 0.15
yimg = 0.1

;new x and y co-ordinates, for the fisrt image they equal xstart/ystart
xnew = xstart
ynew = ystart

;text positions
;x = x + 0.075
;y = y - 0.01

;get the colour table names
;loadct, get_names = name

juldate = [2008001, 2008017, 2008033, 2008049, 2008065, 2008081, 2008097, 2008113, 2008129, 2008145, 2008161, $
            2008177, 2008193, 2008209, 2008225, 2008241, 2008257, 2008273, 2008289, 2008305, 2008321, 2008337, $
            2008353, 2009001, 2009017, 2009033, 2009049, 2009065, 2009081, 2009097, 2009113, 2009129, 2009145, $
            2009161, 2009177, 2009193, 2009209, 2009225, 2009241, 2009257, 2009273, 2009289, 2009305, 2009321, $
            2009337, 2009353]

;value array
;num = sindgen(41)

;setting decomposed = 0 makes the text display as different colours
;device, decomposed=1, filename='muscle_colours_final.ps', /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0
device, decomposed=1, filename='Cubby_Station_2008_2009.ps', /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0

  for i =0, 45 do begin
    ;loadct, i
    tvscl, image[*,*,i], xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
    ;xyouts, xnew + 0.055, ynew - 0.01, num[i] + ': ' + name[i], alignment = 0.5, /normal, charsize=0.5
    xyouts, xnew + 0.06, ynew - 0.01, juldate[i], alignment = 0.5, /normal, charsize=1
  
    if xnew + xstep lt xend then begin
       xnew = xnew + xstep
    endif else begin
      xnew = xstart
      ynew = ynew - ystep
      endelse
  endfor

;Title
;xyouts, 0.5, 0.075, 'Predefined Colour Tables', alignment = 0.5, /normal, charsize=2
xyouts, xnew + xstep, 0.12, 'Cubby Station', alignment = 0.5, /normal, charsize=2
xyouts, xnew + xstep, 0.095, 'Jan 2008', alignment = 0.5, /normal, charsize=2
xyouts, xnew + xstep, 0.07, 'to', alignment = 0.5, /normal, charsize=2
xyouts, xnew + xstep, 0.045, 'Dec 2009', alignment = 0.5, /normal, charsize=2
  
device, /close

;return to original plot output device
set_plot, mydevice

end

