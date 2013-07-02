function test_image_correlation, x, Covariance = covar

;Calculates the correlation matrix of a multiband image or
;the covariance matrix (if set).
;Depending on the image size, this can be very memory intensive, as
;it creates several copies of the data.
;correlation.  Due to rounding, the diagonals on the correlation matrix
;may not always equal 1
;
;band1 = [[65, 63, 67],[64, 68, 62],[70, 66, 68],[67, 69, 71]]
;band2 = [[68, 66, 68],[65, 69, 66],[68, 65, 72],[67, 68, 70]]
;band3 = [[100, 99, 101],[105, 104, 103],[100, 97, 102],[100, 101, 102]]
;band4 = [[65, 62, 67],[106, 104, 103],[70, 66, 68],[100, 101, 102]]
;band5 = [[100, 99, 101],[61, 69, 66],[100, 97, 102],[67, 68, 70]]
;
;testimage = [[[band1]],[[band2]],[[band3]],[[band4]],[[band5]]]
;
;For correlation use: 
;Correlation = test_image_correlation(testimage)
;Answer (Band 1 to Band 5)
;  1.00000     0.662871   -0.0346153    0.0908348    0.0269833
;  0.662871    1.00000     0.213144    -0.0646380    0.201167
; -0.0346153   0.213144    1.00000      0.688859    -0.625822
;  0.0908348  -0.0646380   0.688859     1.00000     -0.985880
;  0.0269833   0.201167   -0.625822    -0.985880     1.00000
;
;For covariance use:
;Covariance = test_image_correlation(testimage, /covariance)
;Answer
;   7.69697      3.78788     -0.212121      4.81818       1.30303
;   3.78788      4.24242      0.969697     -2.54545       7.21212
;  -0.212121     0.969697     4.87879      29.0909      -24.0606
;   4.81818     -2.54545     29.0909      365.545      -328.091
;   1.30303      7.21212    -24.0606     -328.091       302.970

 on_error, 2

 dims = size(x, /dimensions)

 if n_elements(dims) LT 3 then message, 'Expecting Multiband Image'
 
 nbands = dims[2]

 npixels = dims[0] * dims[1]

 bandmeans = test_image_mean(x)

;create a dummy array for the bandmeans. Allows for easier array subtraction.
 dummyarray = fltarr(dims[0], dims[1])

 residuals = fltarr(dims[0], dims[1], dims[2])

 for i = 0, dims[2]-1 do begin
   residuals[*,*,i] = x[*,*,i] - (bandmeans[i])[dummyarray]
 endfor

;for i = 0, dims[2]-1 do residuals[*,*,i] = x[*,*,i] - (bandmeans[i])[dummyarray]

 covm = fltarr(dims[2], dims[2], dims[0])

;Need to operate on the spectral domain, so several transposes are needed
 residuals = temporary(transpose(residuals))
 residtr = transpose(residuals, [1,0,2])

;This may not be feasible as it will now be looping over the number of columns which could be quite large,
;but didn't seem too bad when testing images of [2580, 2058, 6].

 for i =0, dims[0] -1 do covm[*,*,i] = residuals[*,*,i] # residtr[*,*,i]

 covm = temporary(total(covm, 3))

 if keyword_set(covar) then begin
  return, covm / (npixels-1)
 endif else begin

;correlation
;Sum of squared residuals
;Need to reverse transpose the residuals in order to get the original dimensions back 
 residuals = temporary(transpose(residuals)) 
 ssresids = test_image_total((residuals^2))
 ssr = ssresids # ssresids

 return, covm / sqrt(ssr)
 endelse

end



