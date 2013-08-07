function pf_2nd_derivative, x, y, bbl, bbl_list, _extra=_extra

ptr= where(bbl_list eq 1, count)
result = fltarr(n_elements(y))
if (count ge 3) then $
   result(ptr) = deriv(x[ptr], deriv(x[ptr], y[ptr]))
return, result
end