pro mss_quicklook
; Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au
;
; Written as a substitute for the original python script, as GDAL coudn't handle the nlaps files.
;
; Needs to run in an ENVI+IDL session as it uses code from both features.
;
; HOW TO RUN!!!!
; Change the directory variable (dir) to the directory of interest. Then save, compile and run.

    ; the directory to search within for valid mss nlaps files
    dir = 'E:\LandsatMSS'

    ; rescale factor
    rs = 0.3

    ;the search method for finding files. Assuming *.H1 are the header files for nlaps files.
    files=file_search(dir,'*.H1',COUNT=numfiles)

    for i=0L, n_elements(files)-1 do begin
        dirname = file_dirname(files[i], /mark_directory)
        envi_open_data_file, files[i], r_fid=fid, /nlaps
        envi_file_query, fid, dims=dims, fname=fname, ns=ns, nl=nl, nb=nb, data_type=dtype
        map_info = envi_get_map_info(fid=fid)

        ; calcualte the rescaled dimensions
        new_x = ns * rs
        new_y = nl * rs

        ; create the output array to hold the rescaled dataset
        q_look = bytarr(new_x,new_y,3, /nozero)

        ; extract each band, apply a stretch and resize it
        for band=0, nb-2 do begin
            data = hist_equal(envi_get_data(fid=fid, dims=dims, pos=band))
            q_look[*,*,band] = congrid(data, new_x, new_y)
        endfor

        ; reverse the band ordering
        q_look = reverse(q_look, 3)

        ; output the jpeg image
        out_fname = dirname + file_basename(fname, '.H1') + '.jpg'
        write_jpeg, out_fname, q_look, true=3, order=1

        ; close the file
        envi_file_mng, id=fid, /remove

    endfor

end
