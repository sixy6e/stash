function pf_savitsky_golay_filter, x, y, bbl, bbl_list, _extra=_extra

ptr= where(bbl_list eq 1, count)
result = fltarr(n_elements(y))
savgolFilter = SAVGOL(3,3,0,2)

result(ptr) = CONVOL(y[ptr], savgolFilter, /EDGE_TRUNCATE)
return, result
end

