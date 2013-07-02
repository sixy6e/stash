function num_samples, header

    compile_opt hidden
    on_error, 2

    fnsw = where(strpos(header, "samples") ne -1, count)
    ;stop
    if (count ne 0) then begin
        fns  = strtrim(header[fnsw], 2)
        fns1 = strpos(fns, '=')
        ns   = strmid(fns, fns1 + 2)

        return, (long(ns))[0]
    endif else begin
        message, 'Number of Samples Not Found.'
    endelse

end

;-----------------------------------------------------------------------

function num_lines, header

    compile_opt hidden
    on_error, 2

    fnlw = where(strpos(header, "lines") ne -1, count)
    if (count ne 0) then begin
        fnl  = strtrim(header[fnlw], 2)
        fnl1 = strpos(fnl, '=')
        nl   = strmid(fnl, fnl1 + 2)

        return, (long(nl))[0]
    endif else begin
        message, 'Number of Lines Not Found.'
    endelse

end

;-----------------------------------------------------------------------

function num_bands, header

    compile_opt hidden
    on_error, 2

    ;fnb = strtrim(header[where(strpos(header, "bands")ne-1)], 2)
    fnbw = where(strpos(header, "bands") ne -1, count)
    if (count ne 0) then begin
        fnb = strtrim(header[fnbw], 2)
        fnb1 = strpos(fnb, '=')
        nb = strmid(fnb, fnb1 + 2)

        return, (long(nb))[0]
    endif else begin
        message, 'Number of Bands Not Found.'
    endelse

end

;-----------------------------------------------------------------------

function map_info, header

    compile_opt hidden
    on_error, 2

    fmiw = where(strpos(header, "map") ne -1, count)
    if (count ne 0) then begin
        fmi = strtrim(header[fmiw], 2)
        b1 = strpos(fmi, '{')
        b2  = strpos(fmi, '}', /reverse_search)
        b2b = strsplit(strmid(fmi, b1+1, b2-b1-1), ',', /extract)
        mi  = {MapInfo, ProjectionName:b2b[0], ULRefX:b2b[1], ULRefY:b2b[2],$
            ULXCoord:b2b[3], ULYCoord:b2b[4], XS:b2b[5], YS:b2b[6], Zone:b2b[7], $
            Units:b2b[8]}

    endif else begin
        mi = {map_info, empty:''}
    endelse

    return, mi

end

;-----------------------------------------------------------------------

function datatype, header

    compile_opt hidden
    on_error, 2

    ; Maybe need a check for correct data type, using filesize and array
    ; dimensions.

    fdtw = where(strpos(header, "data type") ne -1, count)
    if (count ne 0) then begin
        fdt =  strtrim(header[fdtw], 2)
        fdt1 = strpos(fdt, '=')
        dtype   = strmid(fdt, fdt1 + 2)

        return, (fix(dtype))[0]
    endif else begin
        message, 'No Data Type Found.'
    endelse

end

;-----------------------------------------------------------------------

function interleave, header

    compile_opt hidden
    on_error, 2

    filw = where(strpos(header, "interleave") ne -1, count)
    if (count ne 0) then begin
        fil = strtrim(header[filw], 2)
        fil1 = strpos(fil, '=')
        ileave   = strmid(fil, fil1 + 2)

        if (strcmp(ileave, 'BSQ', /fold_case)) eq 1 then begin
            intleave = 0
        endif else begin
            if (strcmp(ileave, 'BIL', /fold_case)) eq 1 then begin
                intleave = 1
            endif else begin
                if (strcmp(ileave, 'BIP', /fold_case)) eq 1 then begin
                   intleave = 2
                endif else begin
                    message, 'Unknown Interleaving; Need either BSQ/BIL/BIP.'
                endelse
            endelse
        endelse

    endif else begin
        message, 'No Interleave Found, Assuming BSQ.', /continue
        intleave = 0
    endelse

    return, intleave

end

;-----------------------------------------------------------------------

function read_header, filename

    compile_opt hidden
    on_error, 2

    openr, lun, filename, /get_lun
    array = ''
    line = ''

    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      array = [array, line]
    ENDWHILE

    FREE_LUN, lun
    return, array[1:*]

end

;-----------------------------------------------------------------------

function sensor_type, header

    compile_opt hidden
    on_error, 2

    fstw = where(strpos(header, "sensor type") ne -1, count)
    if (count ne 0) then begin
        fst = strtrim(header[fstw], 2)
        fst1 = strpos(fst, '=')
        stype   = (strmid(fst, fst1 + 2))[0]

    endif else begin
        stype = "Unknown"
    endelse

    return, stype
end

;-----------------------------------------------------------------------

function wavelength_units, header

    compile_opt hidden
    on_error, 2

    fwuw = where(strpos(header, "wavelength units") ne -1, count)
    if (count ne 0) then begin
        fwu = strtrim(header[fwuw], 2)
        fwu1 = strpos(fwu, '=')
        wvunits   = (strmid(fwu, fwu1 + 2))[0]

    endif else begin
        wvunits = "Unknown"
    endelse

    return, wvunits
end

;-----------------------------------------------------------------------

function band_names, header

    compile_opt hidden
    on_error, 2

    fbnw = where(strpos(header, "band names") ne -1, count)
    if (count ne 0) then begin
        fbn = strtrim(header[fbnw], 2)
        fbn1 = strpos(fbn, '{')

        ; This can pose some problems, as it finds any line that has } on it.
        ; So if band names isn't last it will include all other lines
        ; NOPE. This still works as strpos of } will find the first occurence.
        eb_array = strpos(header[fbnw+1:*], '}')
        names = ''
        for i = 1, n_elements(eb_array) do begin
            names = names + header[fbnw+i]
        endfor
        eb = strpos(names, '}')
        names  = strtrim(strmid(names, 0, eb), 2)
        b_names = strsplit(names, ',', /extract)

    endif else begin
        nb   = num_bands(header)
        band = string(lonarr(nb))
        number=string(lonarr(nb))
        b_names=string(lonarr(nb))

        ;create the array with value 'Band' placed in each element
        for i=0L, nb[0]-1 do begin
            band[i]= 'Band '
        endfor

        ;create the array with values of 1 to the total number of files
        for i=0L, nb[0]-1 do begin
            number[i]= strtrim(i+1,1)
        endfor

        ;concatenate (join) the band and number arrays into one singular array
        for i=0L, nb[0]-1 do begin
            b_names[i]= band[i] + number[i]
        endfor
    endelse

    ;bnames = {BandNames, Names:b_names}
    return, b_names
end

;-----------------------------------------------------------------------

function byteorder, header

    compile_opt hidden
    on_error, 2

    fbow = where(strpos(header, "byte order") ne -1, count)
    if (count ne 0) then begin
        fbo = strtrim(header[fbow], 2)
        fbo1 = strpos(fbo, '=')
        byt_order   = (fix(strmid(fbo, fbo1 + 2)))[0]
    endif else begin
        message, 'Byte order not found, assuming byte order of current machine.', /continue
        byt_order = (byte(1,0,1))[0] ? 0 : 1
    endelse

    return, byt_order

end

;-----------------------------------------------------------------------

function header_offset, header

    compile_opt hidden
    on_error, 2

    fhow = where(strpos(header, "header offset") ne -1, count)
    if (count ne 0) then begin
        fho = strtrim(header[fhow], 2)
        fho1 = strpos(fho, '=')
        offset = (long(strmid(fho, fho1 + 2)))[0]
    endif else begin
        message, 'No offset found, assuming zero.', /continue
        offset = 0L
    endelse

    return, offset

end

;-----------------------------------------------------------------------

function description, header

    compile_opt hidden
    on_error, 2

    fdsw = where(strpos(header, "description") ne -1, count)
    if (count ne 0) then begin
        fds = strtrim(header[fdsw], 2)
        fds1 = strpos(fds, '{')

        ; This can pose some problems, as it finds any line that has } on it.
        ; TODO find a work around
        ;dlines = strpos(header[fdsw+1:*], '}')
        ;fhow2 = where(dlines ne -1, count)
        ;if (count ne 0) then begin
            ; The first } after the found { should be at element 0 of where
        ;    fhow2 = fhow2[0]
        ;endif
        ;desc = ''
        ;looping?
        ;for i=0, fhow2 do begin
        ;    desc = desc + header[fdsw +1 +i]
        ;endfor
      
        ;eb = strpos(desc, '}')
        ;descrip  = strtrim(strmid(desc, 0, eb), 2)
        ;dlines[fhow2]

        ; Using the same method as for band names. It seems to work fine.
        eb_array = strpos(header[fdsw+1:*], '}')
        desc = ''
        for i = 1, n_elements(eb_array) do begin
            desc = desc + header[fdsw+i]
        endfor
        eb = strpos(desc, '}')
        descrip  = (strtrim(strmid(desc, 0, eb), 2))[0]

    endif else begin
        descrip = 'None'
    endelse

    return, descrip

end

;-----------------------------------------------------------------------

function filetype, header

    compile_opt hidden
    on_error, 2

    fftw = where(strpos(header, "file type") ne -1, count)
    if (count ne 0) then begin
        fft = strtrim(header[fftw], 2)
        fft1 = strpos(fft, '=')
        ftype = (strmid(fft, fft1 + 2))[0]
    endif else begin
        message, 'File type not found, assumed ENVI Standard.', /continue
        ftype = 'ENVI Standard'
    endelse

    return, ftype

end

;-----------------------------------------------------------------------

pro test_read_envi, filename, image=image, info=info, Help=help

    ; Could turn this into a procedure. Return the image, and a structure
    ; containing ns, nl, nb, datatype, interleave, map_info.  DONE!!!!
    ;
    ; Could include other functions such as sensor type, band names,
    ; wavelength units, header offset, byte order
    ;
    ; include file type, description

    on_error, 2

    if keyword_set(help) then begin
        print, 'procedure TEST_READ_ENVI filname, image=image, info=info'
        print, 'Help=help'
        print, 'Reads an ENVI style image format. Set info to a variable'
        print, 'that will contain a structure containing the image'
        print, 'information such as samples, lines, bands, data type etc.'
    endif else begin

        ; Check the data file has been selected, eg throw message if the '.hdr' is selected
        ; Do by if last four characters is '.hdr'. CHANGED!!!! Now accepts either.

        ;if strpos(filename, '.', /reverse_search)
        if (strcmp(strmid(filename, 2, /reverse_offset), 'hdr', /fold_case)) eq 1 then begin
            fname = file_dirname(filename, /mark_directory) + $
                file_basename(filename, '.hdr');, /fold_case) ; fold_case not implemented in gdl yet
            fname = fname[0]
            hname = filename
        endif else begin
            fname = filename
            hname = fname + '.hdr'
        endelse

        print, 'fname = ', fname
        print, 'hname = ', hname
        print, file_dirname(hname, /mark_directory)

        hdr = read_header(hname)

        ; Get the description info
        descript = description(hdr)

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

        ; byte order of file
        f_byte_order = byteorder(hdr)

        ; file type
        ftype = filetype(hdr)

        ; byte order of current machine
        m_byte_order = (byte(1,0,1))[0] ? 0 : 1

        ; header offset
        h_offset = header_offset(hdr)

        if (f_byte_order ne m_byte_order) then begin
            openr, lun, fname, /get_lun, /swap_endian
            point_lun, lun, h_offset
            readu, lun, image
            free_lun, lun
        endif else begin
            ; Open and read the image file
            openr, lun, fname, /get_lun
            point_lun, lun, h_offset
            readu, lun, image
            free_lun, lun
        endelse

        stype = sensor_type(hdr)
        wl_units = wavelength_units(hdr)
        bnames = band_names(hdr)

        info = {Image_Info, Samples:ns, Lines:nl, Bands:nb, Data_Type:dtype,$
                       Interleave:intleave, Filename:fname, Sensor_Type:stype, $
                       Wavelength_Units:wl_units, Band_Names:bnames, $
                       Byte_Order:f_byte_order, Header_offset:h_offset, $
                       Description:descript, File_Type:ftype}

        ;return, image

    endelse

end    
