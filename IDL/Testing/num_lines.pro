function num_lines, header

    compile_opt hidden
    on_error, 2

    fnlw = where(strpos(header, "lines") ne -1, count)
    if (count ne 0) then begin
        fnl  = strtrim(header[fnlw], 2)
        fnl1 = strpos(fnl, '=')
        nl   = strmid(fnl, fnl1 + 2)

        return, nl
    endif else begin
        message, 'Number of Lines Not Found.'

end