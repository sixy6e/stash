;+
; Name:
;     triangle_threshold_mask_testing
;
; Purpose:
;     To mask an image via the Triangle threshold method.
;     The threshold is calculated as the point of maximum perpendicular distance
;     of a line between the histogram peak and the farthest non-zero histogram edge
;     and the histogram.
;
; Notes:
;     This function is written for use only with an interactive ENVI session.
;
; Author:
;     Josh Sixsmith; joshua.sixsmith@ga.gov.au
;
; Sources:
;     G.W. Zack, W.E. Rogers, and S.A. Latt. Automatic measurement of sister 
;         chromatid exchange frequency. Journal of Histochemistry & Cytochemistry, 
;         25(7):741, 1977. 1, 2.1
;
; History:
;     2013/06/08: Created

;Adding an extra button to the ENVI Menu bar
PRO triangle_threshold_mask_testing_define_buttons, buttonInfo

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Triangle', $
   EVENT_PRO = 'triangle_threshold_mask_testing', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

FUNCTION calculate_triangle_threshold, hist=hist

    h = hist
    mx = MAX(h, mx_loc)
    wh = WHERE(h NE 0, count)
    first_non_zero = wh[0]
    last_non_zero = wh[N_ELEMENTS(wh)-1]
    left_span = (first_non_zero - mx_loc)
    right_span = (last_non_zero - mx_loc)
    x_dist = (ABS(left_span) GT ABS(right_span)) ? left_span : right_span
    non_zero_point = (ABS(left_span) GT ABS(right_span)) ? first_non_zero : last_non_zero
    y_dist = h[non_zero_point] - mx
    m = FLOAT(y_dist)/x_dist
    ;y = m*x + b
    ;y - yo = m(x - x0)
    ;y = mx - m*x0 + m*(-x0) + y0
    b = m*(-mx_loc) + mx
    x1 = (ABS(left_span) GT ABS(right_span)) ? DINDGEN(ABS(x_dist) + 1) :  DINDGEN(ABS(x_dist) + 1) + mx_loc
    y1 = h[x1]
    y2 = m*x1 + b
    dists = SQRT((y2 - y1)^2)
    thresh_max = MAX(dists, thresh_loc)
    thresh = (ABS(left_span) GT ABS(right_span)) ? thresh_loc : thresh_loc + mx_loc
    RETURN, thresh
END

PRO triangle_threshold_mask_testing, event

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2
    
    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos, /band_only, dims=dims
    IF (fid EQ -1) THEN RETURN
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb
    map_info = envi_get_map_info(fid=fid)
    
    ;pos = lindgen(nb)
    envi_doit, 'envi_stats_doit', fid=fid, pos=pos, $ 
        dims=dims, comp_flag=1, dmin=dmin, dmax=dmax, $ 
        mean=mean, stdv=stdv
    
    data_mx = MAX(dmax)
    data_mn = MIN(dmin)
    
    ;need a widget that accepts binsize, min, max, nbins, and whether or not to produce a plot
    base = WIDGET_AUTO_BASE(title='Histogram Parameters')
    row_base1 = WIDGET_BASE(base, /row)
    ;p1 = WIDGET_PARAM(row_base1, auto_manage=0, default='', $  
    ;  prompt='Binsize', uvalue='p1', xsize=10)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p2', xsize=10, default=data_mn)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p3', xsize=10, default=data_mx)
    p4 = WIDGET_PARAM(row_base1, auto_manage=0, default=256, $  
      prompt='Nbins', uvalue='p4', xsize=10)
    
    p_list = ['Plot threshold?']
    i_list = ['Invert Mask?']
    wm = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm2 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wo = WIDGET_OUTFM(base, uvalue='outf', /auto)
    result = AUTO_WID_MNG(base)
    ;help, result, /structure
    ;print, result.plot
    mn_ = result.p2
    mx_ = result.p3
    nbins_ = result.p4
    binsz = (mx_ - mn_) / (nbins_ - 1)
    ;help, mn_, mx_
    invert_mask = result.invert

    ;TODO
    ;Need to set up a datatype conversion for proper inputs into histogram
    
    IF (result.accept EQ 0) THEN RETURN
    IF ((result.outf.in_memory) EQ 1) THEN BEGIN
        PRINT, 'Output to memory selected'
        ;print, result
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        ; get the histogram of the first tile
        data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
        h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_)

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

        ;now loop over tiles
        FOR i=1, num_tiles-1 DO BEGIN
            ENVI_REPORT_STAT, rbase, i, num_tiles
            data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
            h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
        ENDFOR
        ENVI_REPORT_INIT, base=rbase, /finish

        ;calculate threshold
        thresh = CALCULATE_TRIANGLE_THRESHOLD(hist=h)
        PRINT, thresh
        PRINT, thresh * binsz
        thresh_convert = thresh * binsz

        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output to Memory']
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase

        ;now loop over tiles again and apply threshold
        CASE invert_mask OF
            0: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
                ENDFOR
               END
            1: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data LT thresh_convert) AND (data GE mn_)
                ENDFOR
               END
        ENDCASE

        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /finish

        ENVI_ENTER_DATA, mask, descrip='Triangle Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info

        ;if the plot box is ticked produce an envi plot
        IF result.plot eq 1 THEN BEGIN
            ENVI_PLOT_DATA, DINDGEN(nbins_), h, plot_title='Triangle Threshold', $
                title='Triangle Threshold'
            ;OPLOT, x1, y2, color=color24([0,0,255])
            PLOTS, [thresh,thresh], !Y.CRange, color=color24([0,255,0])
        ENDIF 
        
    ENDIF ELSE BEGIN
        PRINT, 'Selected File: ', result.outf.name
        PRINT, result
        outfname = result.outf
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        ; get the histogram of the first tile
        data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
        h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_)

        rstr = ['Input File: ' + fname, 'Band Number: ' + string(pos + 1)]
        ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

        ;now loop over the other tiles
        FOR i=1, num_tiles-1 DO BEGIN 
            ENVI_REPORT_STAT, rbase, i, num_tiles
            data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
            h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
        ENDFOR

        ENVI_REPORT_INIT, base=rbase, /finish

        ;calculate threshold
        thresh = calculate_triangle_threshold(hist=h)
        thresh_convert = thresh * binsz

        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output File: ' + outfname]
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase

        ;now loop over tiles again and apply threshold
        CASE invert_mask OF
            0: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
                ENDFOR
               END
            1: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    envi_report_stat, rbase, i, num_tiles
                    data=envi_get_tile(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data LT thresh_convert) AND (data GE mn_)
                ENDFOR
               END
        ENDCASE

        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /finish

        ENVI_ENTER_DATA, mask, descrip='Triangle Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info

        ;if the plot box is ticked produce an envi plot
        IF (result.plot EQ 1) THEN BEGIN
            ENVI_PLOT_DATA, DINDGEN(nbins_), h, plot_title='Triangle Threshold', $
                title='Triangle Threshold'
            ;OPLOT, x1, y2, color=color24([0,0,255])
            PLOTS, [thresh,thresh], !Y.CRange, color=color24([0,255,0])
        ENDIF 
    ENDELSE
    
 END
