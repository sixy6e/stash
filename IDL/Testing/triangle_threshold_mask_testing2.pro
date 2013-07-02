;+
; Name:
;     TRIANGLE_THRESHOLD_MASK
;-
;
;+
; Description:
;     Creates a binary mask from an image using the Triangle threshold method.
;     The threshold is calculated as the point of maximum perpendicular distance
;     of a line between the histogram peak and the farthest non-zero histogram edge
;     to the histogram.
;-
;
;+ 
; Input options:
;     Min: The minumum value to be included in the histogram.
;     Max: The maximum value to be included in the histogram.
;     Nbins: The number of bins to use in calculating the histogram.
;-
;
;+
; Output options:
;     The output mask can be inverted.
;     A plot of the histogram and calculated threshold.
;-
;
;+
; Requires:
;     This function is written for use only with an interactive ENVI session.
;-
;
;+
; @Author:
;     Josh Sixsmith; joshua.sixsmith@ga.gov.au
;-
;
;+
; Sources:
;     G.W. Zack, W.E. Rogers, and S.A. Latt. Automatic measurement of sister 
;         chromatid exchange frequency. Journal of Histochemistry & Cytochemistry, 
;         25(7):741, 1977. 1, 2.1
;-
;
;+
; @History:
;     2013/06/08: Created
;-
;
;+    
; @TODO:
;     Need to set up a datatype conversion for proper inputs into the histogram function.
;     Coyote Library maybe ???
;-

;Adding an extra button to the ENVI Menu bar
PRO triangle_threshold_mask_define_buttons, buttonInfo
;+
; @Hidden
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Triangle', $
   EVENT_PRO = 'triangle_threshold_mask', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

FUNCTION calculate_triangle_threshold, hist=hist
;+
; @Hidden
;-
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
    b = m*(-mx_loc) + mx
    x1 = (ABS(left_span) GT ABS(right_span)) ? DINDGEN(ABS(x_dist) + 1) :  DINDGEN(ABS(x_dist) + 1) + mx_loc
    y1 = h[x1]
    y2 = m*x1 + b
    dists = SQRT((y2 - y1)^2)
    thresh_max = MAX(dists, thresh_loc)
    thresh = (ABS(left_span) GT ABS(right_span)) ? thresh_loc : thresh_loc + mx_loc
    RETURN, thresh
END

PRO triangle_threshold_mask, event

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2
    
    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos, /band_only, dims=dims
    IF (fid EQ -1) THEN RETURN
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb
    map_info = ENVI_GET_MAP_INFO(fid=fid)
    
    ENVI_DOIT, 'envi_stats_doit', fid=fid, pos=pos, $ 
        dims=dims, comp_flag=1, dmin=dmin, dmax=dmax
    
    data_mx = MAX(dmax)
    data_mn = MIN(dmin)
    
    base = WIDGET_AUTO_BASE(title='Histogram Parameters')
    row_base1 = WIDGET_BASE(base, /row)
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p1', xsize=10, default=data_mn)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p2', xsize=10, default=data_mx)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, default=256, $  
      prompt='Nbins', uvalue='p3', xsize=10)
    
    p_list = ['Plot Threshold?']
    i_list = ['Invert Mask?']
    s_list = ['Segment Binary Mask?']
    
    wm = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm2 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wm3 = WIDGET_MENU(base, list=s_list, uvalue='segment', rows=1, auto_manage=0)
    wo = WIDGET_OUTFM(base, uvalue='outfm', prompt='Mask Ouput', /auto)
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Mask Segmentation Output', /auto)
    
    result = AUTO_WID_MNG(base)

    IF (result.accept EQ 0) THEN RETURN

    mn_ = result.p1
    mx_ = result.p2
    nbins_ = result.p3
    binsz = (mx_ - mn_) / (nbins_ - 1)
    invert_mask = result.invert
   
    IF ((result.outfm.in_memory) EQ 1) THEN BEGIN
        PRINT, 'Output to memory selected'
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
            ystart=dims[3], map_info=map_info, r_fid=mfid, $
            bnames=['Triangle Threshold Result: Band 1']

        ;if the plot box is ticked produce an envi plot
        IF result.plot eq 1 THEN BEGIN
            ENVI_PLOT_DATA, DINDGEN(nbins_), h, plot_title='Triangle Threshold', $
                title='Triangle Threshold'
            PLOTS, [thresh,thresh], !Y.CRange, color=color24([0,255,0])
        ENDIF 
        
    ENDIF ELSE BEGIN
        PRINT, 'Selected File: ', result.outfm.name
        PRINT, result
        outfname = result.outfm.name
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        ; get the histogram of the first tile
        data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
        h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_)

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

        ;now loop over the other tiles
        FOR i=1, num_tiles-1 DO BEGIN 
            ENVI_REPORT_STAT, rbase, i, num_tiles
            data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
            h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
        ENDFOR

        ENVI_REPORT_INIT, base=rbase, /finish

        ;calculate threshold
        thresh = CALCULATE_TRIANGLE_THRESHOLD(hist=h)
        thresh_convert = thresh * binsz

        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        ;mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]
        
        OPENW, lun, outfname, /get_lun
        
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output File: ' + outfname]
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase

        ;now loop over tiles again and apply threshold
        CASE invert_mask OF
            0: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    ;mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
                    mask = (data LT thresh_convert) AND (data GE mn_)
                    WRITEU, lun, mask
                ENDFOR
               END
            1: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    envi_report_stat, rbase, i, num_tiles
                    data=envi_get_tile(tile_id, i, ys=ys, ye=ye)
                    ;mask[0:xe,ys:ye] = (data LT thresh_convert) AND (data GE mn_)
                    mask = (data LT thresh_convert) AND (data GE mn_)
                    WRITEU, lun, mask
                ENDFOR
               END
        ENDCASE

        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /finish
        
        ; Close the file
        FREE_LUN, lun
        
        ;Create the header file
        envi_setup_head, fname=outfname, ns=samples, nl=lines, nb=1, $
            bnames=['Triangle Threshold Result: Band 1'], data_type=1, $
            offset=0, interleave=0, map_info=map_info, $
            descrip='Triangle Threshold Result', r_fid=mfid, /write, /open

        ;ENVI_ENTER_DATA, mask, descrip='Triangle Threshold Result', xstart=dims[1], $
        ;    ystart=dims[3], map_info=map_info, bnames=['Triangle Threshold Result: Band 1']

        ;if the plot box is ticked produce an envi plot
        IF (result.plot EQ 1) THEN BEGIN
            ENVI_PLOT_DATA, DINDGEN(nbins_), h, plot_title='Triangle Threshold', $
                title='Triangle Threshold'
            PLOTS, [thresh,thresh], !Y.CRange, color=color24([0,255,0])
        ENDIF
                
    ENDELSE
    
    IF (result.segment EQ 1) THEN BEGIN
        ENVI_FILE_QUERY, mfid, ns=m_ns, nl=m_nl, interleave=m_interleave, $
            fname=m_fname, nb=m_nb, dims=m_dims
        seg_outfname = result.outf
        pos = LINDGEN(m_nb)
        class = LONG([1]) ; Dealing with a binary mask, so only interested in 1
        ENVI_DOIT, 'ENVI_SEGMENT_DOIT', fid=mfid, pos=pos, dims=m_dims, $
            class_ptr=class, out_name=seg_outfname, /ALL_NEIGHBORS
    ENDIF
    
    
 END
