pro js_recursive_hist

; Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au
;
; Recursively applies a histogram to an image with multiple bands.
; Designed for the analysing the water results by finding counts of 1 within
; each band.
;
; An interactive ENVI+IDL session is required to run this code.
; At the moment to run the script, open it in the IDL workbench, compile then
; run.

    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos
    IF (fid EQ -1) THEN return
    ENVI_FILE_QUERY, fid, dims=dims, ns=ns, nl=nl, interleave=interleave, fname=fname
    map_info = envi_get_map_info(fid=fid)

    ; an array to store the histogram value. looking for a value of 1.
    res = lonarr(n_elements(pos))

    FOR i=0L, n_elements(pos)-1 DO BEGIN
        data = envi_get_data(fid=fid, dims=dims, pos=i)
        hist = histogram(data, min=0)
        ; check that hist has values other than 0
        res[i] = (n_elements(hist) ge 2) ? hist[1] : 0
    ENDFOR

    mx = max(res, loc)
    str = ['This is the droid you are looking for is:', string(loc+1)]
    print, format = '(%"The band number you are looking for is %i")', loc+1
    str_res = strarr(n_elements(pos))

    for i=0L, n_elements(pos)-1 DO BEGIN
        str_res[i] = 'Band ' + strtrim(string(i+1),1) + ':' + string(res[i])
    endfor

    ENVI_INFO_WID, str, title='Band With Most Ones'
    ENVI_INFO_WID, str_res, title='Counts'


end
