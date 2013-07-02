PRO muscle_view

file = 'C:\Program Files\ITT\IDL\IDL80\examples\data\muscle.jpg'
result = query_jpeg(file, info)
if result eq 0 then return
read_jpeg, file, image
shrink = congrid(image, 150, 150)
;window, xsize=info.dimensions[0], ysize=info.dimensions[1]
window, 1,  xsize = 1800, ysize = 1000
device, decomposed=0
;device, decomposed=0, filename='muscle_colours.ps', /color, xsize=21, ysize=29.7, xoffset=0.0, yoffset=0.0
;need to create a loop that places the new image into a new position each time
;so the co-ordinates will be stepping through 
for i = 0, 40 do begin
;loadct, i, get_names = name
loadct, i
;tvscl, image, /order, i
tvscl, shrink, /order, i
;1st img co-ord x=0.02, y=0.89 using normalised co-ords (range 0.0 to 1.0)
;0.83 is the last x co-ord that can draw the image
;0.02 is the last y co-ord that can draw the image
;xstep = 0.16, ystep = 0.12
;tvscl, image, 0.02, 0.88, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.18, 0.89, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.34, 0.89, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.50, 0.89, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.66, 0.89, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.82, 0.89, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.76, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.64, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.52, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.40, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.28, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.16, xsize=0.15, ysize=0.1, /normal, /order
;tvscl, shrink, 0.02, 0.04, xsize=0.15, ysize=0.1, /normal, /order
;text x + 0.075, y - 0.01
xyouts, 0.095, 0.87, 'Rainbow + Black', alignment = 0.5, /normal
;xyouts, 0.095, 0.87, name, alignment = 0.5, /normal
endfor
;device, /close
;wdelete
END