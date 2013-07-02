pro change_value_where_v2

    COMPILE_OPT STRICTARR

    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos
    IF (fid EQ -1) THEN return
    ENVI_FILE_QUERY, fid, dims=dims, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb, bnames=bnames
    map_info = envi_get_map_info(fid=fid)

    NaN = !VALUES.F_NAN
    ;description = 'Changed -32767 to NaN'
    description = 'Calculated Moments'
    outfname = 'T:\Landsat-Landcover\Data\Optical\Landsat5and7-NDVIts-MidMurray\2004_Q4_Jan_Dec_stack_092-093_085_GDA94-MGA-zone-55_moments_stats_envi'
    ;outfname = 'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\stats_test2'
    out_bnames = ['Sum', 'Mean', 'Variance', 'Stddev', 'Skewness', 'Kurtosis', '1st Quantile', 'Median', '3rd Quantile', 'Min', 'Max', 'Valid Obsv']

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
        data = float(envi_get_tile(tile_id, t))
        ;m_data = (data eq -32767)*NaN + (data ne -32767)*data
        data_dims = size(data, /dimensions)
        ;wh = where(data eq -32767, count)
        ;wh = where(data ne -32767, count)
        ;IF count NE 0 THEN data[wh] = NaN
        ;IF count NE 0 THEN temp = data[wh]
        mom = fltarr(12,data_dims[1])
        FOR i=0L, data_dims[1]-1 DO BEGIN
            ;wh = where(finite(data[*,i]), nanCount)
            temp = data[*,i]
            wh = where(temp ne -32767, count)
            IF count GT 0 THEN temp = temp[wh]
            IF count GT 1 THEN cse = 1 ELSE $
            IF count EQ 1 THEN cse = 2 ELSE cse = 3
            ;IF nanCount gt 1 THEN BEGIN
            ;IF count gt 1 THEN BEGIN
            CASE cse OF
                1: BEGIN
                   ;mom[0,i] = float(total(data[*,i], /NAN))
                    mom[0,i] = float(total(temp))
                   ;mom[1,i] = float(mean(data[*,i], /NAN))
                   mom[1,i] = float(mean(temp))
                   ;mom[2,i] = float(variance(data[*,i], /NAN))
                   mom[2,i] = float(variance(temp))
                   mom[3,i] = sqrt(mom[2,i])
                   ;mom[4,i] = float(skewness(data[*,i], /NAN))
                   mom[4,i] = float(skewness(temp))
                   ;mom[5,i] = float(kurtosis(data[*,i], /NAN))
                   mom[5,i] = float(kurtosis(temp))
                   ;mom[6,i] = float(median(data[*,i], /EVEN))
                   mom[6,i] = float(median(temp, /EVEN))
                   mom[7,i] = float(median(temp[where(temp LE mom[6,i])], /even))
                   mom[8,i] = float(median(temp[where(temp GE mom[6,i])], /even))
                   mom[9,i] = float(min(temp))
                   mom[10,i] = float(max(temp))
                   mom[11,i] = float(count)
                   END
            ;ENDIF ELSE BEGIN
                2: BEGIN
                   ;mom[0,i] = float(total(data[*,i], /NAN))
                   mom[0,i] = float(total(temp))
                   ;mom[1,i] = float(mean(data[*,i], /NAN))
                   mom[1,i] = float(mean(temp))
                   mom[2,i] = NaN
                   mom[3,i] = NaN
                   mom[4,i] = NaN
                   mom[5,i] = NaN
                   ;mom[6,i] = float(median(data[*,i], /EVEN)) ; ;Can return a NaN for zero data points
                   mom[6,i] = float(median(temp, /EVEN)) ; ;Can return a NaN for zero data points
                   mom[7,i] = NaN ; Not needed for 1 (or zero) data points
                   mom[8,i] = NaN ; Not needed for 1 (or zero) data points
                   mom[9,i] = float(min(temp))
                   mom[10,i] = float(max(temp))
                   mom[11,i] = float(count)
                   END
                3: BEGIN
                   mom[*,i] = NaN
                   mom[11,i] = float(count)
                   END
             ENDCASE
            ;ENDELSE
        ENDFOR
        writeu, lun, mom
    ENDFOR

    ;Close the tiling procedure and the Percent Complete window
    envi_tile_done, tile_id
    envi_report_init, base=base, /finish


    free_lun, lun

    ;Create the header file
    envi_setup_head, fname=outfname, ns=ns, nl=nl, nb=12, bnames=out_bnames, $
                   data_type=4, offset=0, interleave=2, map_info=map_info, $
                   descrip=description, r_fid=h_fid, /write, /open

    et = systime(1)
    print, et - st
END