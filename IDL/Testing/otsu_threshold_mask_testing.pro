PRO otsu_threshold_mask_testing_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Otsu', $
   EVENT_PRO = 'otsu_threshold_mask_testing', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

PRO otsu_button_help, ev
;+
; :Hidden:
;-
    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'otsu_threshold_mask.html' 
    ONLINE_HELP, book=book
    
END

FUNCTION calculate_otsu_threshold, histogram=h, locations=loc
;+
; :Hidden:
;-
    rh = REVERSE(h)
    rloc = REVERSE(loc)

    cumu_hist  = TOTAL(h, /CUMULATIVE, /DOUBLE)
    rcumu_hist = REVERSE(cumu_hist)

    h_dim = N_ELEMENTS(h)

    total_ = cumu_hist[h_dim-1]

    ; Calculate probabilities per threshold class
    bground_weights = cumu_hist / total_

    ; Calculate reverse probabilities
    fground_weights = 1 - bground_weights

    mean_bground = DBLARR(h_dim)
    mean_fground = DBLARR(h_dim)

    ; Calculate background class means
    tmp = TOTAL(h * loc, /CUMULATIVE, /DOUBLE)
    mean_bground[0:h_dim-2] = tmp[0:h_dim-2]

    ; Calculate foreground class means
    tmp = REVERSE(TOTAL(rh * rloc, /CUMULATIVE) / rcumu_hist)
    mean_fground[0:h_dim-2] =  tmp[1:h_dim-1]

    ; Calculate between class variance
    sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)^2

    thresh = MAX(sigma_between, mx_loc)
    RETURN, thresh

END

PRO otsu_threshold_mask_testing, event
;+
; :Hidden:
;-

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    CATCH, error 
    IF (error NE 0) THEN BEGIN 
        ok = DIALOG_MESSAGE(!error_state.msg, /CANCEL) 
        IF (STRUPCASE(ok) EQ 'CANCEL') THEN RETURN
    ENDIF
    
    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos, /BAND_ONLY, dims=dims
    IF (fid EQ -1) THEN RETURN
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb, $
        data_type=dtype
    map_info = ENVI_GET_MAP_INFO(fid=fid)
    
    ENVI_DOIT, 'envi_stats_doit', fid=fid, pos=pos, $ 
        dims=dims, comp_flag=1, dmin=dmin, dmax=dmax
    
    data_mx = MAX(dmax)
    data_mn = MIN(dmin)
    
    base = WIDGET_AUTO_BASE(title='Histogram Parameters')
    row_base1 = WIDGET_BASE(base, /ROW)
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p1', xsize=10, default=data_mn)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p2', xsize=10, default=data_mx)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, default=1, $  
      prompt='Binsize', uvalue='p3', xsize=10)
    p4 = WIDGET_PARAM(row_base1, auto_manage=0, default=256, $  
      prompt='Nbins', uvalue='p4', xsize=10, dt=12)
      
    bn_list = ['Binsize', 'Nbins']
    wm1 = WIDGET_MENU(base, list=bn_list, uvalue='bnsz_nbin', /EXCLUSIVE, /AUTO)
    
    p_list = ['Plot Threshold?']
    i_list = ['Invert Mask?']
    s_list = ['Segment Binary Mask?']
    
    wm2 = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm3 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wm4 = WIDGET_MENU(base, list=s_list, uvalue='segment', rows=1, auto_manage=0)
    wo1 = WIDGET_OUTFM(base, uvalue='outfm', prompt='Mask Output', /AUTO)
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Mask Segmentation Output', auto_manage=0)
    wb  = WIDGET_BUTTON(base, value='Help', event_pro='tri_button_help', /ALIGN_CENTER, /HELP)
    
    result = AUTO_WID_MNG(base)

    IF (result.accept EQ 0) THEN RETURN
    
    mn_ = CONVERT_TO_TYPE(result.p1, dtype)
    mx_ = CONVERT_TO_TYPE(result.p2, dtype)
    binsz = CONVERT_TO_TYPE(result.p3, dtype)
    nbins_ = result.p4
    
    bnsz_nbin = result.bnsz_nbin

    binsz = (bnsz_nbin EQ 0) ? binsz : (mx_ - mn_) / (nbins_ - 1)
    invert_mask = result.invert
    
    IF ((result.outfm.in_memory) EQ 1) THEN BEGIN
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        CASE bnsz_nbin OF
            0: BEGIN
               ; get the histogram of the first tile
               data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
               h = HISTOGRAM(data, min=mn_, max=mx_, binsize=binsz, locations=loc)

               rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
               ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

               ;now loop over tiles
               FOR i=1, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, i, num_tiles
                   data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                   h = HISTOGRAM(data, input=h, min=mn_, max=mx_, binsize=binsz)
               ENDFOR
               ENVI_REPORT_INIT, base=rbase, /FINISH
               END
            1: BEGIN
               ; get the histogram of the first tile
               data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
               h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_, locations=loc)

               rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
               ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

               ;now loop over tiles
               FOR i=1, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, i, num_tiles
                   data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                   h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
               ENDFOR
               ENVI_REPORT_INIT, base=rbase, /FINISH
               END
        ENDCASE
        
        rh = REVERSE(h)
        rloc = REVERSE(loc)
        
        cumu_hist  = TOTAL(h, /CUMULATIVE, /DOUBLE)
        rcumu_hist = REVERSE(cumu_hist)
        
        h_dim = N_ELEMENTS(h)
        
        total_ = cumu_hist[h_dim-1]
        
        ; Calculate probabilities per threshold class
        bground_weights = cumu_hist / total_
        
        ; Calculate reverse probabilities
        fground_weights = 1 - bground_weights

        mean_bground = DBLARR(h_dim)
        mean_fground = DBLARR(h_dim)
        
        ; Calculate background class means
        tmp = TOTAL(h * loc, /CUMULATIVE, /DOUBLE)
        mean_bground[0:h_dim-2] = tmp[0:h_dim-2]
        
        ; Calculate foreground class means
        tmp = REVERSE(TOTAL(rh * rloc, /CUMULATIVE) / rcumu_hist)
        mean_fground[0:h_dim-2] =  tmp[1:h_dim-1]
        
        ; Calculate between class variance
        sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)^2
        
        thresh = MAX(sigma_between, mx_loc)
        
        ; The above could be replaced with a function call.
        ; thresh = calculate_otsu_threshold(histogram=h, locations=loc)
        ; thresh_convert = thresh * binsz + omin
        
        thresh_convert = (mx_loc * binsz) + omin

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
        ENVI_REPORT_INIT, base=rbase, /FINISH

        ENVI_ENTER_DATA, mask, descrip='Otsu Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info, r_fid=mfid, $
            bnames=['Otsu Threshold Result: Band 1']

    ENDIF ELSE BEGIN
        outfname = result.outfm.name
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        CASE bnsz_nbin OF
            0: BEGIN
               ; get the histogram of the first tile
               data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
               h = HISTOGRAM(data, min=mn_, max=mx_, binsize=binsz, locations=loc)

               rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
               ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

               ;now loop over tiles
               FOR i=1, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, i, num_tiles
                   data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                   h = HISTOGRAM(data, input=h, min=mn_, max=mx_, binsize=binsz)
               ENDFOR
               ENVI_REPORT_INIT, base=rbase, /FINISH
               END
            1: BEGIN
               ; get the histogram of the first tile
               data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
               h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_, locations=loc)

               rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
               ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

               ;now loop over tiles
               FOR i=1, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, i, num_tiles
                   data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                   h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
               ENDFOR
               ENVI_REPORT_INIT, base=rbase, /FINISH
               END
        ENDCASE
        
        rh = REVERSE(h)
        rloc = REVERSE(loc)
        
        cumu_hist  = TOTAL(h, /CUMULATIVE, /DOUBLE)
        rcumu_hist = REVERSE(cumu_hist)
        
        h_dim = N_ELEMENTS(h)
        
        total_ = cumu_hist[h_dim-1]
        
        ; Calculate probabilities per threshold class
        bground_weights = cumu_hist / total_
        
        ; Calculate reverse probabilities
        fground_weights = 1 - bground_weights

        mean_bground = DBLARR(h_dim)
        mean_fground = DBLARR(h_dim)
        
        ; Calculate background class means
        tmp = TOTAL(h * loc, /CUMULATIVE, /DOUBLE)
        mean_bground[0:h_dim-2] = tmp[0:h_dim-2]
        
        ; Calculate foreground class means
        tmp = REVERSE(TOTAL(rh * rloc, /CUMULATIVE) / rcumu_hist)
        mean_fground[0:h_dim-2] =  tmp[1:h_dim-1]
        
        ; Calculate between class variance
        sigma_between = bground_weights * fground_weights *(mean_bground - mean_fground)^2
        
        thresh = MAX(sigma_between, mx_loc)
        
        ; The above could be replaced with a function call.
        ; thresh = calculate_otsu_threshold(histogram=h, locations=loc)
        ; thresh_convert = thresh * binsz + omin
        
        thresh_convert = (mx_loc * binsz) + omin

        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        xe = dims[2] - dims[1]
        
        OPENW, lun, outfname, /GET_LUN
        
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output File: ' + outfname]
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase

        ;now loop over tiles again and apply threshold
        CASE invert_mask OF
            0: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask = (data LT thresh_convert) AND (data GE mn_)
                    WRITEU, lun, mask
                ENDFOR
               END
            1: BEGIN
                FOR i=1, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data=ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask = (data LT thresh_convert) AND (data GE mn_)
                    WRITEU, lun, mask
                ENDFOR
               END
        ENDCASE

        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /FINISH
        
        ; Close the file
        FREE_LUN, lun
        
        ;Create the header file
        ENVI_SETUP_HEAD, fname=outfname, ns=samples, nl=lines, nb=1, $
            bnames=['Otsu Threshold Result: Band 1'], data_type=1, $
            offset=0, interleave=0, map_info=map_info, $
            descrip='Otsu Threshold Result', r_fid=mfid, /WRITE, /OPEN
    
    ENDELSE

    IF (result.plot EQ 1) THEN BEGIN
        ENVI_PLOT_DATA, DINDGEN(N_ELEMENTS(h)), h, plot_title='Otsu Threshold', $
            title='Otsu Threshold', base=plot_base

        ; An undocumented routine, sp_import
        ;http://www.exelisvis.com/Learn/VideoDetail/TabId/323/ArtMID/1318/ArticleID/3974/3974.aspx
        sp_import, plot_base, [thresh,thresh], !Y.CRange, plot_color=[0,255,0]
    ENDIF 

    IF (result.segment EQ 1) THEN BEGIN
        ENVI_FILE_QUERY, mfid, ns=m_ns, nl=m_nl, interleave=m_interleave, $
            fname=m_fname, nb=m_nb, dims=m_dims
        seg_outfname = result.outf
        pos = LINDGEN(m_nb)
        class = LONG([1]) ; Dealing with a binary mask, so only interested in the value 1
        ENVI_DOIT, 'ENVI_SEGMENT_DOIT', fid=mfid, pos=pos, dims=m_dims, $
            class_ptr=class, out_name=seg_outfname, /ALL_NEIGHBORS
    ENDIF

END