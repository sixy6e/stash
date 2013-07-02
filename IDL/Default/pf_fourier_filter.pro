function pf_fourier_filter, x, y, bbl, bbl_list, _extra=_extra

     ptr= where(bbl_list eq 1, count)
     result = fltarr(n_elements(y))
     fftr = fft(y[ptr])
     powerspectrum = abs(fftr)^2
     meanpwr = mean(powerspectrum)
     mask = real_part(powerspectrum) gt meanpwr
     masked = fftr * mask
     inverse = real_part(fft(masked, /inverse))
     
     return, inverse
end