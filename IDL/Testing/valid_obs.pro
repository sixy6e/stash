pro valid_obs

    COMPILE_OPT STRICTARR

    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos
    IF (fid EQ -1) THEN return
    ENVI_FILE_QUERY, fid, dims=dims, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb, bnames=bnames
    map_info = envi_get_map_info(fid=fid)

    NaN = !VALUES.F_NAN
    ;description = 'Changed -32767 to NaN'
    description = 'Number of Valid Observations'
    ;outfname = 'T:\Landsat-Landcover\Data\Optical\Landsat5and7-NDVIts-MidMurray\2010_Q4_Jan_Dec_stack_092-093_085_GDA94-MGA-zone-55_valid_obsv_envi'
    outfname = 'T:\Landsat-Landcover\Data\Optical\Landsat5and7-NDVIts-MidMurray\2002-2010_Jan_Dec_stack_092-093_085_GDA94-MGA-zone-55_valid_obsv_envi'
    ;outfname = 'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\stats_test2'
    out_bnames = ['Valid Obsv']

    openw, lun, outfname, /get_lun

    ;Display the Percent Complete Window
    ostr = 'Output File: ' + outfname
    rstr = ["Input File :" + fname, ostr]


    envi_report_init, rstr, title="Processing Where values", base=base

    tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
                  interleave=2, xs=dims[1], xe=dims[2], $
                  ys=dims[3], ye=dims[4])

    st = systime(1)

    FOR t=0L, num_tiles-1 DO BEGIN
        envi_report_stat, base, t, num_tiles
        data = (envi_get_tile(tile_id, t))
        ;m_data = (data eq -32767)*NaN + (data ne -32767)*data
        data_dims = size(data, /dimensions)
        ;wh = where(data eq -32767, count)
        ;wh = where(data ne -32767, count)
        ;IF count NE 0 THEN data[wh] = NaN
        ;IF count NE 0 THEN temp = data[wh]
        mom = intarr(1,data_dims[1])
        FOR i=0L, data_dims[1]-1 DO BEGIN
            ;wh = where(finite(data[*,i]), nanCount)
            temp = data[*,i]
            wh = where(temp ne -32767, count)
            mom[0,i] = fix(count)
         ENDFOR
        writeu, lun, mom
    ENDFOR

    ;Close the tiling procedure and the Percent Complete window
    envi_tile_done, tile_id
    envi_report_init, base=base, /finish


    free_lun, lun

    ;Create the header file
    envi_setup_head, fname=outfname, ns=ns, nl=nl, nb=1, bnames=out_bnames, $
                   data_type=2, offset=0, interleave=2, map_info=map_info, $
                   descrip=description, r_fid=h_fid, /write, /open

    et = systime(1)
    print, et - st
END