;
; Josh Sixsmith 16 May 2012, under GNU GPL v3 or later
;
; A simple statistical test for distribution shape
;
; After HIST_EQUAL we check that:
; -- kurtosis of the image is roughly -1.2
; -- skewness of the image is roughly 0
; This should describe a Uniform distribution
;
; A seperate test for the percent variable of the hist_equal function.
;
pro test_percent_hist_equal, samples=samples, percent=percent, test=test, $
                             verbose=verbose, help=help
;
if keyword_set(help) then begin
    print, 'pro test_hist_equal, samples=samples, percent=percent, $
    print, '                     test=test, verbose=verbose. help=help'
    return
endif
;
if n_elements(samples) eq 0 then samples=100
;
if n_elements(percent) eq 0 then percent=2
;
; We will calculate an image from a random normal distribution.
; This should (roughly) have a skewness of 0 and a kurtosis of 0.
img = randomn(sd, samples,samples)
;
; compute the histogram equalisation on the image
scl = hist_equal(img, percent=percent)
;
; compute the moment of the raw image and the scaled image
m_raw    = moment(img)
m_scl = moment(scl)
;
; The more samples used in the image creation, the closer the
; image is to being a normal distribution.
; As such, some variation will be expected, so an error of 0.1
; should suffice.
err = 0.1
total_pb = 0
;
if (abs(m_scl[3] + 1.2) ge err) then begin
    if keyword_set(verbose) then message, 'pb with kurtosis ofimage', /continue
    total_pb = total_pb + 1
endif
;
if (abs(m_scl[2]) ge err) then begin
    if keyword_set(verbose) then message, 'pb with skewness of image', /continue
    total_pb = total_pb + 1
endif
;
if keyword_set(verbose) then begin
    print, 'Stats on Raw Image:'
    print, 'Mean: ', m_raw[0] & print, 'Variance: ', m_raw[1] & print, 'Skewness: ', $
        m_raw[2] & print, 'Kurtosis: ', m_raw[3]
    print, 'Stats on Equalised Image:'
    print, 'Mean: ', m_scl[0] & print, 'Variance: ', m_scl[1] & print, 'Skewness: ', $
        m_scl[2] & print, 'Kurtosis: ', m_scl[3]
endif
;
if keyword_set(test) then stop
;
if (total_pb gt 0) then begin
    if keyword_set(no_exit) then begin
        message, 'Tests failed. Increase sample size?', /continue
    endif else begin
        exit, status=1
    endelse
endif else begin
    message, 'Tests successful.', /continue
endelse
;
end