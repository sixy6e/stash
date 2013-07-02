function linear_3_percent, img

on_error, 2

dims = size(img, /dimensions)
if n_elements(dims) eq 3 then message, 'Only single band images are currently supported'
if size(img, /type) ne 1 then message, 'Only images of type byte are currently supported'

hist = histogram(img)
;hist = histogram(img, reverse_indices=ri)
cumu = total(hist, /cumulative)
ftot = cumu[n_elements(cumu)-1]
;low  = 0.03 * ftot
low = 0 + (percent/100.) * ftot
;high = 0.97 * ftot
high = 100 - (percent/100.) * ftot
if cumu[0] gt low then begin
    x1 = min(img)
endif else begin
    x1 = where(cumu eq max(cumu[where(cumu le low)]))
endelse

x2 = where(cumu eq max(cumu[where(cumu le high)]))

y2 = 255
y1 = 0

m = float(y2-y1)/(x2[0]-x1) ; Only dealing with byte data so can use x2[0]
; otherwise might need reverse indices. Then do img[ri[ri[x2]]]
b = m*(-x1)

scl = img*m + b
over = where(scl gt 255, count)
if (count ne 0) then scl[over] = 255
under = where(scl lt 0, count)
if (count ne 0) then scl[under] = 0

return, byte(round(scl))
end