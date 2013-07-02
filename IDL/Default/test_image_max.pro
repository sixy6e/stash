function test_image_max, x

;Used for calculating the max value for each of the bands within
;a multispectral image
;
;band1 = [[65, 63, 67],[64, 68, 62],[70, 66, 68],[67, 69, 71]]
;band2 = [[68, 66, 68],[65, 69, 66],[68, 65, 72],[67, 68, 70]]
;band3 = [[100, 99, 101],[105, 104, 103],[100, 97, 102],[100, 101, 102]]
;band4 = [[65, 62, 67],[106, 104, 103],[70, 66, 68],[100, 101, 102]]
;band5 = [[100, 99, 101],[61, 69, 66],[100, 97, 102],[67, 68, 70]]
;
;testimage = [[[band1]],[[band2]],[[band3]],[[band4]],[[band5]]]
;
;Use: band_max = test_image_max(testimage)
;Answer (Band 1 to Band 5). Returns floating point.
;71.0000      72.0000      105.000      106.000      102.000

 on_error, 2

 dims = size(x, /dimensions)
 
 if n_elements(dims) LT 3 then message, 'Expecting Multiband Image'
 
 array = fltarr(dims[2],1)
  
 for i =0, dims[2]-1 do begin
  array[i] = max(x[*,*,i])
 endfor
 
 ;if keyword_set(mn) then begin
  ;mn = 
  ;array = [array, sdv]
  ;return, array
 ;endif 
 
 return, array
 
end