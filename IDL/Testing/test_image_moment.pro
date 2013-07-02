function test_image_moment, x, Double = dbl, sdev = stdv

;Used for calculating the mean, variance, skewness, kurtosis and
;standard deviation (if set) for each of the bands within
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
;Use: band_moment = test_image_moment(testimage)
;Answer (mean, variance, skewness, kurtosis)
;band1      66.6667      7.69697    -0.151760       -1.27610
;band2      67.6667      4.24242     0.468361       -0.674657
;band3     101.167       4.87879    -0.00687066     -0.823629
;band4      84.5000    365.545      -0.00926462     -2.10747
;band5      83.3333    302.970      -0.0308008      -2.08525
;
;Use with standard deviation
;Answer (mean, variance, skewness, kurtosis, standard deviation
;band1      66.6667      7.69697    -0.151760       -1.27610      2.77434
;band2      67.6667      4.24242     0.468361       -0.674657     2.05971
;band3     101.167       4.87879    -0.00687066     -0.823629     2.20880
;band4      84.5000    365.545      -0.00926462     -2.10747     19.1192
;band5      83.3333    302.970      -0.0308008      -2.08525     17.4060

 on_error, 2
 
 dims = size(x, /dimensions)
 
 if n_elements(dims) LT 3 then message, 'Expecting Multiband Image'
 
 dbl = keyword_set(dbl)
 
 array = dbl ? dblarr(4, dims[2]) : fltarr(4, dims[2])
 
 ;if keyword_set(dbl) then begin
  ;array = dblarr(4, dims[2])
 ;endif else begin
 
  ;array = fltarr(4, dims[2])
 ;endelse
 
 
 for i =0, dims[2]-1 do begin
  array[*,i] = moment(x[*,*,i], Double = dbl)
 endfor
 
 if keyword_set(stdv) then begin
  sdv = dbl ? dblarr(1, dims[2]) : fltarr(1, dims[2])
  sdv = sqrt(array[1,*])
  array = [array, sdv]
  return, array
 endif
 
 return, array
 
end