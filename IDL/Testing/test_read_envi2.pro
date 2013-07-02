;function num_samples, header

;    compile_opt hidden
;    on_error, 2

;    fnsw = where(strpos(header, "samples") ne -1, count)
;    if (count ne 0) then begin
;        fns  = strtrim(header[fnsw], 2)
;        fns1 = strpos(fns, '=')
;        ns   = strmid(fns, fns1 + 2)

;        return, ns
;    endif else begin
        ;message, 'Number of Samples Not Found.'
;        return, ns

;end

;-----------------------------------------------------------------------

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
    endelse

end

;-----------------------------------------------------------------------

;function num_bands, header

;    compile_opt hidden
;    on_error, 2

    ;fnb = strtrim(header[where(strpos(header, "bands")ne-1)], 2)
;    fnbw = where(strpos(header, "bands") ne -1, count)
;    if (count ne 0) then begin
;        fnb = strtrim(header[fnbw], 2)
;        fnb1 = strpos(fnb, '=')
;        nb = strmid(fnb, fnb1 + 2)

;        return, nb
;    endif else begin
;        message, 'Number of Bands Not Found.'

;end

;-----------------------------------------------------------------------

;function map_info, header

;    compile_opt hidden
;    on_error, 2

;    fmiw = where(strpos(header, "map") ne -1, count)
;    if (count ne 0) then begin
;        fmi = strtrim(header[fmiw], 2)
;        b1 = strpos(fmi, '{')
;        b2  = strpos(fmi, '}', /reverse_search)
;        b2b = strsplit(strmid(fmi, b1+1, b2-b1-1), ',', /extract)
;        mi  = {MapInfo, ProjectionName:b2b[0], ULRefX:b2b[1], ULRefY:b2b[2],$
;            ULXCoord:b2b[3], ULYCoord:b2b[4], XS:b2b[5], YS:b2b[6], Zone:b2b[7], $
;            Units:b2b[8]}

;        return, mi

;    endif else begin
;        mi = {Map_Info, empty:''}
;        return, mi

;end

;-----------------------------------------------------------------------

;function datatype, header

;    compile_opt hidden
;    on_error, 2

    ; Maybe need a check for correct data type, using filesize and array
    ; dimensions.

;    fdtw = where(strpos(header, "data type") ne -1, count)
;    if (count ne 0) then begin
;        fdt =  strtrim(header[fdtw], 2)
;        fdt1 = strpos(fdt, '=')
;        dtype   = strmid(fdt, fdt1 + 2)

;        return, fix(dtype)
;    endif else begin
;        message, 'No Data Type Found.'
;    endelse

;end

;-----------------------------------------------------------------------

;function interleave, header

;    compile_opt hidden
;    on_error, 2

;    filw = where(strpos(header, "interleave") ne -1, count)
;    if (count ne 0) then begin
;        fil = strtrim(header[filw], 2)
;        fil1 = strpos(fil, '=')
;        ileave   = strmid(fil, fil1 + 2)

;        if (strcmp(ileave, 'BSQ', /fold_case)) eq 1 then begin
;            intleave = 0
;        endif else begin
;            if (strcmp(ileave, 'BIL', /fold_case)) eq 1 then begin
;                intleave = 1
;            endif else begin
;                if (strcmp(ileave, 'BIP', /fold_case)) eq 1 then begin
;                   intleave = 2
;                endif else begin
;                    message, 'Unknown Interleaving; Need either BSQ/BIL/BIP.'
;                endelse
;            endelse
;        endelse

        ;return, intleave
;    endif else begin
;        message, 'No Interleave Found, Assuming BSQ.', /continue
;        intleave = 0
;    endelse

;    return, intleave

;end

;-----------------------------------------------------------------------

;function read_header, filename

;    compile_opt hidden
;    on_error, 2

;    openr, lun, filename, /get_lun
;    array = ''
;    line = ''

;    WHILE NOT EOF(lun) DO BEGIN
;      READF, lun, line
;      array = [array, line]
;    ENDWHILE

;    FREE_LUN, lun
;    return, array[1:*]

;end

;-----------------------------------------------------------------------

;function sensor_type, header

;    compile_opt hidden
;    on_error, 2

;    fstw = where(strpos(header, "sensor type") ne -1, count)
;    if (count ne 0) then begin
;        fst = strtrim(header[fstw], 2)
;        fst1 = strpos(fst, '=')
;        stype   = strmid(fst, fst1 + 2)

        ;return, stype
;    endif else begin
;        stype = "Unknown"

;    return, stype
;end

;-----------------------------------------------------------------------

;function wavelength_units, header

;    compile_opt hidden
;    on_error, 2

;    fwuw = where(strpos(header, "wavelength units") ne -1, count)
;    if (count ne 0) then begin
;        fwu = strtrim(header[fwuw], 2)
;        fwu1 = strpos(fwu, '=')
;        wvunits   = strmid(fwu, fwu1 + 2)

;    endif else begin
;        wvunits = "Unknown"

;    return, wvunits
;end

;-----------------------------------------------------------------------

;function band_names, header

    ;compile_opt hidden
    ;on_error, 2

    ;fbnw = where(strpos(header, "band names") ne -1, count)
    ;if (count ne 0) then begin
    ;    fbn = strtrim(header[fbnw], 2)
    ;    fbn1 = strpos(fbn, '{')

    ;    n_bands = strpos(header[fbnw+1:*], '}')
    ;    names = ''
    ;    for i = 1, n_elements(len) do begin
    ;        names = names + header[fbnw+i]
    ;    endfor
    ;    eb = strpos(names, '}')
    ;    names  = strtrim(strmid(names, 0, eb), 2)
    ;    b_names = strsplit(names, ',', /extrct)

        ;return, bnames
    ;endif else begin
    ;    nb   = num_bands(header)
    ;    band = string(lonarr(nb))
    ;    number=string(lonarr(nb))
    ;    b_names=string(lonarr(nb))

        ;create the array with value 'Band' placed in each element
    ;    for i=0L, nb[0]-1 do begin
    ;        band[i]= 'Band '
    ;    endfor

        ;create the array with values of 1 to the total number of files
    ;    for i=0L, nb[0]-1 do begin
    ;        number[i]= strtrim(i+1,1)
    ;    endfor

        ;concatenate (join) the band and number arrays into one singular array
    ;    for i=0L, nb[0]-1 do begin
    ;        b_names[i]= band[i] + number[i]
    ;    endfor
    ;endelse

    ;bnames = {BandNames, Names:b_names}
    ;return, bnames
;end

;-----------------------------------------------------------------------


pro test_read_envi, filename, image=image, info=info

    ; Could turn this into a procedure. Return the image, and a structure
    ; containing ns, nl, nb, datatype, interleave, map_info.  DONE!!!!
    ;
    ; Could include other functions such as sensor type, band names,
    ; wavelength units, header offset, byte order

    on_error, 2


    ; Check the data file has been selected, eg throw message if the '.hdr' is selected
    ; Do by if last four characters is '.hdr'. CHANGED!!!! Now accepts either.

    ;if strpos(filename, '.', /reverse_search)
    if (strcmp(strmid(filename, 2, /reverse_offset), 'hdr', /fold_case)) eq 1 then begin
        fname = file_dirname(filename, /mark_directory) + $
            file_basename(filename, '.hdr', /fold_case)
        hname = filename
    endif else begin
        fname = filename
        hname = fname + '.hdr'
    endelse

    print, 'fname = ', fname
    print, 'hname = ', hname
    print, file_dirname(hname, /mark_directory)

    hdr = read_header(hname)

    ; Get samples, lines, bands, datatype, interleave
    ns = num_samples(hdr)
    nl = num_lines(hdr)
    nb = num_bands(hdr)

    dtype    = datatype(hdr)
    intleave = interleave(hdr)

    ; Need to work out map_info stuff
    ; m_info = map_info(hdr)

    case intleave of
       ; BSQ Interleaving
        0: begin
            case dtype of
                0: message, 'Undefined Data Type.'
                1: image = bytarr(ns, nl, nb, /nozero)
                2: image = intarr(ns, nl, nb, /nozero)
                3: image = lonarr(ns, nl, nb, /nozero)
                4: image = fltarr(ns, nl, nb, /nozero)
                5: image = dblarr(ns, nl, nb, /nozero)
                6: image = complexarr(ns, nl, nb, /nozero)
                7: image = strarr(ns, nl, nb)
                8: message, 'Structured Arrays Not Supported.'
                9: image = dcomplexarr(ns, nl, nb, /nozero)
                10: image = ptrarr(ns, nl, nb, /nozero)
                11: image = objarr(ns, nl, nb, /nozero)
                12: image = uintarr(ns, nl, nb, /nozero)
                13: image = ulonarr(ns, nl, nb, /nozero)
                14: image = lon64arr(ns, nl, nb, /nozero)
                15: image = ulon64arr(ns, nl, nb, /nozero)
                else: message, 'Unknown Data Type.'
            endcase
            break
            end
        ; BIL Interleaving
        1: begin
            case dtype of
                0: message, 'Undefined Data Type.'
                1: image = bytarr(ns, nb, nl, /nozero)
                2: image = intarr(ns, nb, nl, /nozero)
                3: image = lonarr(ns, nb, nl, /nozero)
                4: image = fltarr(ns, nb, nl, /nozero)
                5: image = dblarr(ns, nb, nl, /nozero)
                6: image = complexarr(ns, nb, nl, /nozero)
                7: image = strarr(ns, nb, nl)
                8: message, 'Structured Arrays Not Supported.'
                9: image = dcomplexarr(ns, nb, nl, /nozero)
                10: image = ptrarr(ns, nb, nl, /nozero)
                11: image = objarr(ns, nb, nl, /nozero)
                12: image = uintarr(ns, nb, nl, /nozero)
                13: image = ulonarr(ns, nb, nl, /nozero)
                14: image = lon64arr(ns, nb, nl, /nozero)
                15: image = ulon64arr(ns, nb, nl, /nozero)
                else: message, 'Unknown Data Type.'
            endcase
            break
            end
        ; BIP Interleaving
        2: begin
            case dtype of
                0: message, 'Undefined Data Type.'
                1: image = bytarr(nb, ns, nl, /nozero)
                2: image = intarr(nb, ns, nl, /nozero)
                3: image = lonarr(nb, ns, nl, /nozero)
                4: image = fltarr(nb, ns, nl, /nozero)
                5: image = dblarr(nb, ns, nl, /nozero)
                6: image = complexarr(nb, ns, nl, /nozero)
                7: image = strarr(nb, ns, nl)
                8: message, 'Structured Arrays Not Supported.'
                9: image = dcomplexarr(nb, ns, nl, /nozero)
                10: image = ptrarr(nb, ns, nl, /nozero)
                11: image = objarr(nb, ns, nl, /nozero)
                12: image = uintarr(nb, ns, nl, /nozero)
                13: image = ulonarr(nb, ns, nl, /nozero)
                14: image = lon64arr(nb, ns, nl, /nozero)
                15: image = ulon64arr(nb, ns, nl, /nozero)
                else: message, 'Unknown Data Type.'
            endcase
            break
            end
        else: message, 'Unknown Interleave.'
    endcase

    ; Open and read the image file
    openr, lun, fname, /get_lun
    readu, lun, image
    free_lun, lun

    stype = sensor_type(hdr)
    wl_units = wavelength_units(hdr)
    bnames = band_names(hdr)

    ;info = {Image_Info, Samples:ns, Lines:nl, Bands:nb, Data_Type:dtype,$
    ;               Interleaving:intleave, Filename:fname, SensorType:stype, $
    ;               WavelengthUnits:wl_units, BandNames:bnames}

    ;return, image

end
