PRO histogram_segmentation_testing_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Segment via Histogram', $
   EVENT_PRO = 'histogram_segmentation_testing', $
   REF_VALUE = 'Segmentation', POSITION = 'last', UVALUE = ''

END

PRO histogram_segmentation_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'histogram_segmentation.html' 
    ONLINE_HELP, book=book
    
END

PRO histogram_segmentation_testing, event
;+
; :Hidden:
;-

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    ;CATCH, error 
    ;IF (error NE 0) THEN BEGIN 
    ;    ok = DIALOG_MESSAGE(!error_state.msg, /CANCEL) 
    ;    IF (STRUPCASE(ok) EQ 'CANCEL') THEN RETURN
    ;ENDIF
    
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
    
    
    s_list = ['Smooth Histogram?']
    wm2 = WIDGET_MENU(base, list=s_list, uvalue='smooth', rows=1, auto_manage=0)
    row_base2 = WIDGET_BASE(base, /ROW)
    p5 = WIDGET_PARAM(row_base2, auto_manage=0, default=3, $
        prompt='Window Size', uvalue='p5', xsize=10, dt=12)
    
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Output filename', auto_manage=0)
    wb  = WIDGET_BUTTON(base, value='Help', event_pro='histogram_segmentation_help', /ALIGN_CENTER, /HELP)
    
    result = AUTO_WID_MNG(base)
    
    IF (result.accept EQ 0) THEN RETURN
    
    PRINT, 'result.accept ', result.accept
    PRINT, 'Selected File ', result.outf
    
    mn_ = CONVERT_TO_TYPE(result.p1, dtype)
    mx_ = CONVERT_TO_TYPE(result.p2, dtype)
    binsz = CONVERT_TO_TYPE(result.p3, dtype)
    nbins_ = result.p4
    sm_width = result.p5
    
    bnsz_nbin   = result.bnsz_nbin
    smooth_hist = result.smooth 

    binsz = (bnsz_nbin EQ 0) ? binsz : (mx_ - mn_) / (nbins_ - 1)
    
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
           FOR i=1L, num_tiles-1 DO BEGIN
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
           FOR i=1L, num_tiles-1 DO BEGIN
               ENVI_REPORT_STAT, rbase, i, num_tiles
               data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
               h = HISTOGRAM(data, input=h, min=mn_, max=mx_, nbins=nbins_)
           ENDFOR
           ENVI_REPORT_INIT, base=rbase, /FINISH
           END
    ENDCASE
    
    h = (smooth_hist EQ 0) ? h : SMOOTH(h, sm_width, /EDGE_TRUNCATE)
    
    ;derivative kernel. We could use the DERIV() function.
    k = [-1,1]
    h_deriv = CONVOL(h, k, /EDGE_TRUNCATE)
    pks = WHERE((h_deriv LT 0) OR (h_deriv GT 0), count)
    
    n   = N_ELEMENTS(h)
    pkn = N_ELEMENTS(pks)
    print, n, pkn
    
    samples = (dims[2] - dims[1]) + 1
    lines   = (dims[4] - dims[3]) + 1
    
    outfname = result.outf
    OPENW, lun, outfname, /GET_LUN
    
    rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output File: ' + outfname]
           ENVI_REPORT_INIT, rstr, title="Segmenting Array", base=rbase
    
    CASE bnsz_nbin OF
        0: BEGIN
           ; Loop through each tile
           FOR i=0L, num_tiles-1 DO BEGIN
               ENVI_REPORT_STAT, rbase, i, num_tiles
               data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
               tile_hist = HISTOGRAM(data, min=mn_, max=mx_, binsize=binsz, reverse_indices=ri)
               lines = (ye - ys) + 1
               seg_arr = ULONARR(samples, lines)
               ; There is probably a faster way to implement this looping structure
               ; Loop through each segment
               ;FOR s=0L, pkn-1 DO BEGIN
               ;    IF (tile_hist[s] EQ 0) THEN CONTINUE
               ;    ; First segment
               ;    IF ((s EQ 0) AND (ri[pks[s]] GT ri[0])) THEN BEGIN
               ;        seg_arr[ri[ri[0]:ri[pks[s]]-1]] = s + 1
               ;    ENDIF ELSE BEGIN
               ;        ; Last segment
               ;        IF ((s EQ pkn-1) AND (ri[n] GT ri[pks[s]])) THEN BEGIN
               ;            seg_arr[ri[ri[pks[s]]:ri[n]-1]] = s + 1
               ;        ENDIF ELSE BEGIN
               ;            ; In-between segments
               ;            IF (ri[pks[s+1]+1] GT ri[pks[s]]) THEN BEGIN
               ;                seg_arr[ri[ri[pks[s]]:ri[pks[s+1]]-1]] = s + 1
               ;            ENDIF
               ;        ENDELSE
               ;    ENDELSE
               ;ENDFOR
               FOR s=0L, pkn-1 DO BEGIN
                   ;IF (tile_hist[s] EQ 0) THEN CONTINUE
                   IF ((s EQ pkn-1) AND (ri[n] GT ri[pks[s]])) THEN BEGIN
                       seg_arr[ri[ri[pks[s]]:ri[n]-1]] = s + 1
                   ENDIF ELSE BEGIN
                       IF (ri[pks[s+1]] GT ri[pks[s]]) THEN BEGIN
                           seg_arr[ri[ri[pks[s]]:ri[pks[s+1]]-1]] = s + 1
                       ENDIF
                   ENDELSE
               ENDFOR
               WRITEU, lun, seg_arr
           ENDFOR
           END
        1: BEGIN
           FOR i=0L, num_tiles-1 DO BEGIN
               ENVI_REPORT_STAT, rbase, i, num_tiles
               data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
               tile_hist = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_, reverse_indices=ri)
               tile_lines = (ye - ys) + 1
               seg_arr = ULONARR(samples, tile_lines)
               ; There is probably a faster way to implement this looping structure
               ; Loop through each segment
               FOR s=0L, pkn-1 DO BEGIN
                   IF (tile_hist[s] EQ 0) THEN CONTINUE
                   ; First segment
                   IF ((s EQ 0) AND (ri[pks[s]] GT ri[0])) THEN BEGIN
                       seg_arr[ri[ri[0]:ri[pks[s]]-1]] = s + 1
                   ENDIF ELSE BEGIN
                       ; Last segment
                       IF ((s EQ pkn-1) AND (ri[n] GT ri[pks[s]])) THEN BEGIN
                           seg_arr[ri[ri[pks[s]]:ri[n]-1]] = s + 1
                       ENDIF ELSE BEGIN
                           ; In-between segments
                           IF (ri[pks[s+1]+1] GT ri[pks[s]]) THEN BEGIN
                               seg_arr[ri[ri[pks[s]]:ri[pks[s+1]]-1]] = s + 1
                           ENDIF
                       ENDELSE
                   ENDELSE
               ENDFOR
               WRITEU, lun, seg_arr
           ENDFOR
           END
    ENDCASE
    
    ; Close id's, report widget and allocation unit number
    ENVI_TILE_DONE, tile_id
    ENVI_REPORT_INIT, base=rbase, /FINISH
    FREE_LUN, lun
    
    ;Create the header file
        ENVI_SETUP_HEAD, fname=outfname, ns=samples, nl=lines, nb=1, $
            bnames=['Segmentation Result: Band 1'], data_type=13, $
            offset=0, interleave=0, map_info=map_info, $
            descrip='Segmentation Via Histogram Result', r_fid=rfid, /WRITE, /OPEN
    
END