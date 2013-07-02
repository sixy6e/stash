pro test_write_envi, data, out_name=outname, ns=ns, nl=nl, nb=nb, $
                     interleave=interleave, bnames=bnames, data_type=dtype, $
                     offset=offset, byte_order=byte_order, descrip=descrip, $
                     Help=help

    if keyword_set(help) then begin
        print, 'procedure TEST_WRITE_ENVI, data, out_name=outname, ns=ns, $'
        print,                'nl=nl, nb=nb, interleave=interleave, $'
        print,                'bnames=bnames, data_type=dtype, $'
        print,                'offset=offset, byte_order=byte_order, $'
        print,                'descrip=descrip, Help=help'
    endif else begin

        if n_elements(outname) eq 0 then message, 'Output filename not specified.'
        if n_elements(ns) eq 0 then message, 'Number of samples not specified.'
        if n_elements(nl) eq 0 then message, 'Number of lines not specified.'
        if n_elements(nb) eq 0 then message, 'Number of bands not specified.'

        if n_elements(interleave) eq 0 then interleave=0
        if n_elements(offset) eq 0 then offset=0
        if n_elements(byte_order) eq 0 then byte_order = (byte(1,0,1))[0] ? 0 : 1
        if n_elements(dtype) eq 0 then dtype = size(data, /type)

        ; TODO check for incompatible stuff eg interleave

        ; Write the header file
        hname = outname + '.hdr'
        openw, lun, hname, /get_lun

        ; TODO allow for user to input description
        ;printf, lun, format = '(%"ENVI \ndescription= {\n    Create New File Result [%s]}")', systime()
        if n_elements(descrip) eq 0 then begin
            printf, lun, format = '(%"ENVI \ndescription= {\n    Create New File Result [%s]}")', systime()
        endif else begin
            printf, lun, format = '(%"ENVI \ndescription= {\n    %s [%s]}")', descrip, systime()
        endelse

        printf, lun, format = '(%"samples = %i")', ns
        printf, lun, format = '(%"lines = %i")', nl
        printf, lun, format = '(%"bands = %i")', nb
        printf, lun, format = '(%"data type = %i")', dtype

        case interleave of
            0: intleave = 'bsq'
            1: intleave = 'bil'
            2: intleave = 'bip'
        endcase

        printf, lun, format='(%"interleave = %s")', intleave
        printf, lun, format='(%"byte order = %i")', byte_order

        if n_elements(bnames) eq 0 then begin

            band=string(lonarr(nb))
            number=string(lonarr(nb))
            bnames=string(lonarr(nb))

            ;create the array with value 'Band' placed in each element
            for i=0L, nb-1 do begin
                band[i]= 'Band '
            endfor

            ;create the array with values of 1 to the total number of files
            for i=0L, nb-1 do begin
                number[i]= strtrim(i+1,1)
            endfor

            ;concatenate (join) the band and number arrays into one singular array
            for i=0L, nb-1 do begin
                bnames[i]= band[i] + number[i]
            endfor

        endif

        printf, lun, "band names = {"

        if nb le 2 then begin
            if nb eq 1 then begin
                printf, lun, format='(%"%s}")', bnames
            endif else begin
                printf, lun, format='(%"%s,")', bnames[0]
                printf, lun, format='(%"%s}")', bnames[1]
            endelse
        endif else begin
            for i=0, nb-2 do begin
                printf, lun, format='(%"%s,")', bnames[i]
            endfor
            printf, lun, format='(%"%s}")', bnames[i]
        endelse

        free_lun, lun

        ; Write the image file (maybe write as last step in case of errors)
        openw, lun, outname, /get_lun
        writeu, lun, data
        free_lun, lun
    endelse

end  
