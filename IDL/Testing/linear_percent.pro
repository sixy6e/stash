function linear_percent, img, percent=percent

on_error, 2

dims = size(img, /dimensions)
if n_elements(dims) eq 3 then message, 'Only single band images are currently supported'
;if size(img, /type) ne 1 then message, 'Only images of type byte are currently supported'

if n_elements(percent) eq 0 then percent = 2
if (percent le 0) or (percent ge 100) then message, 'Percent must be between 0 and 100'

;print percent

;hist = histogram(img)
nbins=256
if size(img, /type) eq 1 then begin
    hist = histogram(img, omin=omin, omax=omax)
    binsize = 1
endif else begin
    hist = histogram(img, omin=omin, omax=omax, nbins=nbins)
    binsize = (omax - omin)/(nbins - 1)
endelse
cumu = total(hist, /cumulative)
n = cumu[n_elements(cumu)-1]
imgmax = max(double(img), min=imgmin)
;binsize = (imgmax - imgmin)/(nbins - 1)

;low  = 0.03 * n
low = (percent/100.) ;* n
;high = 0.97 * n
high = (1 - (percent/100.)) ;* n

x1 = value_locate(cumu, n * low)
if x1 eq -1 then x1 = 0
while cumu[x1] eq cumu[x1 + 1] do begin
    x1 = x1 + 1
endwhile
;if abs(low - cumu[x1]/n) le abs(low - cumu[x1 + 1]/n) then x1 else x1 +1
close1 = abs(low - cumu[x1]/n)
close2 = abs(low - cumu[x1 + 1]/n)
x1 = (close1 le close2) ? x1 : x1 + 1
minDN = x1 * binsize + omin

x2 = value_locate(cumu, n * high)
while cumu[x2] eq cumu[x2 - 1] do begin
    x2 = x2 - 1
endwhile
close1 = abs(high - cumu[x2]/n)
close2 = abs(high - cumu[x2 + 1]/n)
x2 = (close1 le close2) ? x2 : x2 + 1
maxDN = x2 * binsize + omin


scaled_img = bytscl(img, max=maxDN, min=minDN)

;'''if cumu[0] gt low then begin
;    x1 = min(img)
;endif else begin
;    x1 = where(cumu eq max(cumu[where(cumu le low)]))
;    x1 = x1[0]
;endelse
;'''

;'''
;x2 = where(cumu eq max(cumu[where(cumu le high)]))
;xf = where(cumu eq max(cumu[where(cumu le high)]))
;x2 = img[ri[ri[xf]]]
;x2 = x2[0]
;ri=0

;y2 = 255
;y1 = 0

;m = float(y2-y1)/(x2[0]-x1) ; Only dealing with byte data so can use x2[0]
; otherwise might need reverse indices. Then do img[ri[ri[xf]]]
;m = float(y2-y1)/(x2-x1)
;b = m*(-x1)

;scale = img*m + b

;over = where(scale gt 255, count)
;if (count ne 0) then scale[over] = 255
;under = where(scale lt 0, count)
;if (count ne 0) then scale[under] = 0
;'''

;return, byte(round(scale))
return, scaled_img
end
