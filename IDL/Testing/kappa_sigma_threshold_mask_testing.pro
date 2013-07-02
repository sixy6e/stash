;Adding an extra button to the ENVI Menu bar
PRO kappa_sigma_threshold_mask_testing_define_buttons, buttonInfo
;+
; @Hidden
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Kappa Sigma', $
   EVENT_PRO = 'kappa_sigma_threshold_mask_testing', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

PRO kappa_sigma_threshold_mask_testing, event

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2
    
    CATCH, error 
    IF (error NE 0) THEN BEGIN 
        ok = DIALOG_MESSAGE(!error_state.msg, /cancel)
        ;print, ok 
        IF (STRUPCASE(ok) EQ 'CANCEL') THEN RETURN
    ENDIF
    
    
    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos, /band_only, dims=dims
    IF (fid EQ -1) THEN RETURN
    ENVI_FILE_QUERY, fid, ns=ns, nl=nl, interleave=interleave, fname=fname, nb=nb, $
        data_type=dtype
    map_info = ENVI_GET_MAP_INFO(fid=fid)

    ENVI_DOIT, 'envi_stats_doit', fid=fid, pos=pos, $ 
        dims=dims, comp_flag=1, dmin=dmin, dmax=dmax
    
    data_mx = MAX(dmax)
    data_mn = MIN(dmin)

    base = WIDGET_AUTO_BASE(title='Kappa Sigma Parameters')
    row_base1 = WIDGET_BASE(base, /row)
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p1', xsize=10, default=data_mn)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p2', xsize=10, default=data_mx)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, default=2, $  
      prompt='Iterations', uvalue='p3', xsize=10)
    p4 = WIDGET_PARAM(row_base1, auto_manage=0, default=0.5, $  
      prompt='Kappa', uvalue='p4', xsize=10)
    
    t_list = ['Background', 'Foreground', 'Middle']
    ;t_list = ['Background', 'Foreground']
    p_list = ['Plot threshold?']
    i_list = ['Invert Mask?']
    s_list = ['Segment Binary Mask?']
    
    wpm = WIDGET_PMENU(base, list=t_list, default=0, prompt='Select a Threshold Method', $
        uvalue='method', auto_manage=0)
    wm  = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm2 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wm3 = WIDGET_MENU(base, list=s_list, uvalue='segment', rows=1, auto_manage=0)
    wo  = WIDGET_OUTFM(base, uvalue='outfm', prompt='Mask Output', /auto)
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Mask Segmentation Output', auto_manage=0)
    
    result = AUTO_WID_MNG(base)

    IF (result.accept EQ 0) THEN RETURN

    ; Get the Min, Max, Kappa and the number of iterations
    mn_    = result.p1
    mx_    = result.p2
    iter   = result.p3
    kappa_ = result.p4
    
    ; Maybe set a starting min and max.
    ; If the new thresholds are smaller or larger then reset to start min/max
    mn_start = mn_
    mx_start = mx_
    
    thresh_method = result.method
    invert_mask   = result.invert
    
    ; Could be used for data ignore value, and stats exclusion 
    NaN = !Values.F_NAN

    ; Set up output mask    
    ;samples = (dims[2] - dims[1]) + 1
    ;lines = (dims[4] - dims[3]) + 1
    ;mask = BYTARR(samples, lines)
    ;xe = dims[2] - dims[1]

      
    IF ((result.outfm.in_memory) EQ 1) THEN BEGIN
        PRINT, 'Output to memory selected'
        
        ; Set up the image tiling routine
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])
        
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        ;ENVI_REPORT_INIT, rstr, title="Calculating Threshold", base=rbase
        
        FOR i=0, iter-1 DO BEGIN
            ; Initialise the sum, square sums and pixel count. Double Precision.
            sum    = 0.D
            sq_sum = 0.D
            cnt    = 0.D
            title = STRING(FORMAT='(%"Iteration %i")', i+1)
            ENVI_REPORT_INIT, rstr, title=title, base=rbase
            
            print, 'mn_: ', mn_
            print, 'mx_: ', mx_
            print, 'sum: ', sum
            print, 'sq_sum: ', sq_sum
            
            FOR t=0, num_tiles-1 DO BEGIN
                ;print, 'cnt: ', cnt
                ENVI_REPORT_STAT, rbase, t, num_tiles
                data = (dtype EQ 5) ? DOUBLE(ENVI_GET_TILE(tile_id, t, ye=ye, ys=ys)) : $
                    FLOAT(ENVI_GET_TILE(tile_id, t, ye=ye, ys=ys))
                wh = WHERE(((data LT mn_) OR (data GT mx_)), whcount)
                IF (whcount NE -1) THEN data[wh] = NaN
                cnt += TOTAL(FINITE(data))
                sum += TOTAL(data, /NAN)
                sq_sum += TOTAL(data^2, /NAN)
                ; need to get a proper count of pixels. As using the dimensions
                ; will still include pixels that should be excluded.
            ENDFOR
            
            ENVI_REPORT_INIT, base=rbase, /finish
            
            ; Calculate the mean
            mu_     = sum/cnt
            print, 'mu_: ', mu_
            print, 'cnt: ', cnt
            print, 'sum: ', sum
            print, 'sq_sum: ', sq_sum
            
            ; This is a way of calculating the standard deviation in a tiling mechanism
            sigma_  = SQRT((sq_sum - cnt * mu_^2)/(cnt - 1))
            print, 'sigma_', sigma_
            
            CASE thresh_method OF
                0 : BEGIN
                    ; Find background
                    thresh = mu_ + sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mx_ = (thresh GT mx_start) ? mx_start : thresh
                    END
                1 : BEGIN
                    ; Find foreground
                    ; Add or Subtract?
                    thresh = mu_ - sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mn_ = (thresh LT mn_start) ? mn_start : thresh
                    END
                2 : BEGIN
                    ; Exclude upper and lower
                    thresh_upper = mu_ + sigma_ * kappa_
                    thresh_lower = mu_ - sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mx_     = (thresh_upper GT mx_start) ? mx_start : thresh_upper
                    mn_     = (thresh_lower LT mn_start) ? mn_start : thresh_lower
                    END
            ENDCASE
            print, 'mn_: ', mn_
            print, 'mx_: ', mx_            
        ENDFOR
        
        ; Set up output mask. Potentially could do this within the 
        ; threshold detection loop. It would save an extra pass over the data.
        ; Inversion might become a problem though    
        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output to Memory']
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase
        
        ; Loop over the tiles and apply the threshold
        ; Shouldn't need to split this up by threshold method.
        ; The min/max are either moving or staying put,
        ; and applying the query should be irrelevant
        ;FOR t=0, num_tiles-1 DO BEGIN
        ;    ENVI_REPORT_STAT, rbase, t, num_tiles
        ;    data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
        ;    mask[0:xe,ys:ye] = (data GE mn_) AND (data LE mx_)
        ;ENDFOR
        
        CASE invert_mask OF
            0: BEGIN
               FOR t=0, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, t, num_tiles
                   data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
                   mask[0:xe,ys:ye] = (data GE mn_) AND (data LE mx_)
               ENDFOR
               END
            1: BEGIN
               FOR t=0, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, t, num_tiles
                   data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
                   mask[0:xe,ys:ye] = ((data LE mn_) AND (data GE mn_start)) OR ((data GE mx_) AND (data LE mx_start))
               ENDFOR
               END
        ENDCASE
            
        
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /finish
        
        ENVI_ENTER_DATA, mask, descrip='Kappa Sigma Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info, r_fid=mfid, $
            bnames=['Kappa Sigma Threshold Result: Band 1']

        ; Loop over the tiles and apply the threshold
        ;CASE invert_mask OF
        ;    0: BEGIN
        ;           CASE thresh_method OF
        ;               0: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data LE mx_) AND (data GE mn_)
        ;                   ENDFOR
        ;                  END
        ;               1: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               2: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;           ENDCASE
        ;       END
        ;    1: BEGIN
        ;           CASE thresh_method OF
        ;               0: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               1: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               2: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;           ENDCASE
        ;       END
        ;ENDCASE

        
        ; Loop over the tiles and calculte the mean and standard deviation
    ENDIF ELSE BEGIN
        PRINT, 'Selected File: ', result.outf.name
        outfname = result.outfm.name
        
        ; Set up the image tiling
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])
            
        FOR i=0, iter-1 DO BEGIN
            ; Initialise the sum, square sums and pixel count. Double Precision.
            sum    = 0.D
            sq_sum = 0.D
            cnt    = 0.D
            
            title = STRING(FORMAT='(%"Iteration %i")', i+1)
            ENVI_REPORT_INIT, rstr, title=title, base=rbase
            
            FOR t=0, num_tiles-1 DO BEGIN
                ENVI_REPORT_STAT, rbase, t, num_tiles
                data = (dtype EQ 5) ? DOUBLE(ENVI_GET_TILE(tile_id, t, ye=ye, ys=ys)) : $
                    FLOAT(ENVI_GET_TILE(tile_id, t, ye=ye, ys=ys))
                wh = WHERE(((data LT mn_) OR (data GT mx_)), whcount)
                IF (whcount NE -1) THEN data[wh] = NaN
                cnt += TOTAL(FINITE(data, /NAN))
                sum += TOTAL(data, /NAN)
                sq_sum += TOTAL(data^2, /NAN)
                ; need to get a proper count of pixels. As using the dimensions
                ; will still include pixels that should be excluded.
            ENDFOR
            
            ENVI_REPORT_INIT, base=rbase, /finish
            
            ; Calculate the mean
            mu_     = sum/cnt
            
            ; This is a way of calculating the standard deviation in a tiling mechanism
            sigma_  = SQRT((sq_sum - cnt * mu_^2)/(cnt - 1))
            
            CASE thresh_method OF
                0 : BEGIN
                    ; Find background
                    thresh = mu_ + sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mx_ = (thresh GT mx_start) ? mx_start : thresh
                    END
                1 : BEGIN
                    ; Find foreground
                    thresh = mu_ - sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mn_ = (thresh LT mn_start) ? mn_start : thresh
                    END
                2 : BEGIN
                    ; Exclude upper and lower
                    thresh_upper = mu_ + sigma_ * kappa_
                    thresh_lower = mu_ - sigma_ * kappa_
                    ; Check that the new threshold isn't outside the original bound
                    mx_     = (thresh_upper GT mx_start) ? mx_start : thresh_upper
                    mn_     = (thresh_lower LT mn_start) ? mn_start : thresh_lower
                    END
            ENDCASE            
        ENDFOR
        
        ; Set up output mask. Potentially could do this within the 
        ; threshold detection loop. It would save an extra pass over the data.
        ; Inversion might become a problem though    
        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]
        
        OPENW, lun, outfname, /get_lun
        
        ; Loop over the tiles and apply the threshold
        ; Shouldn't need to split this up by threshold method.
        ; The min/max are either moving or staying put,
        ; and applying the query should be irrelevant
        ;FOR t=0, num_tiles-1 DO BEGIN
        ;    ENVI_REPORT_STAT, rbase, t, num_tiles
        ;    data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
        ;    mask[0:xe,ys:ye] = (data GE mn_) AND (data LE mx_)
        ;ENDFOR
        
        CASE invert_mask OF
            0: BEGIN
               FOR t=0, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, t, num_tiles
                   data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
                   mask = (data GE mn_) AND (data LE mx_)
                   WRITEU, lun, mask
               ENDFOR
               END
            1: BEGIN
               FOR t=0, num_tiles-1 DO BEGIN
                   ENVI_REPORT_STAT, rbase, t, num_tiles
                   data = ENVI_GET_TILE(tile_id, t, ys=ys, ye=ye)
                   mask = ((data LE mn_) AND (data GE mn_start)) OR ((data GE mx_) AND (data LE mx_start))
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
            bnames=['Kappa Sigma Threshold Result: Band 1'], data_type=1, $
            offset=0, interleave=0, map_info=map_info, r_fid=mfid, $
            descrip='Kappa Sigma Threshold Result', r_fid=mfid, /write, /open
        
        ;ENVI_ENTER_DATA, mask, descrip='Triangle Threshold Result', xstart=dims[1], $
        ;    ystart=dims[3], map_info=map_info, bnames=['Kappa Sigma Threshold Result: Band 1']

        ; Loop over the tiles and apply the threshold
        ;CASE invert_mask OF
        ;    0: BEGIN
        ;           CASE thresh_method OF
        ;               0: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data LE mx_) AND (data GE mn_)
        ;                   ENDFOR
        ;                  END
        ;               1: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               2: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;           ENDCASE
        ;       END
        ;    1: BEGIN
        ;           CASE thresh_method OF
        ;               0: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               1: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;               2: BEGIN
        ;                   FOR i=1, num_tiles-1 DO BEGIN 
        ;                       ENVI_REPORT_STAT, rbase, i, num_tiles
        ;                       data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
        ;                       mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
        ;                   ENDFOR
        ;                  END
        ;           ENDCASE
        ;       END
        ;ENDCASE
    ENDELSE

    ;if the plot box is ticked produce an envi plot
    IF (result.plot EQ 1) THEN BEGIN

        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        ; Defaulting to 256 bins
        nbins = 256
        mx_start = CONVERT_TO_TYPE(mx_start, dtype)
        mn_start = CONVERT_TO_TYPE(mn_start, dtype)
        binsz = CONVERT_TO_TYPE((mx_start - mn_start) / (nbins - 1), dtype)
        print, 'mn_start: ', mn_start
        print, 'binsz: ', binsz
        print, 'mx_ change: ', nbins * binsz + mn_start

        ; get the histogram of the first tile
        data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
        ;data = FLOAT(ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys))
        h = HISTOGRAM(data, min=mn_start, max=mx_start, nbins=nbins, locations=loc, omax=omax)
        ;h = HISTOGRAM(data, min=mn_start, max=mx_start, binsize=binsz, locations=loc, omax=omax)
        print, loc
        print, omax

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

        ;now loop over tiles
        FOR i=1, num_tiles-1 DO BEGIN
            ENVI_REPORT_STAT, rbase, i, num_tiles
            data = FLOAT(ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye))
            h = HISTOGRAM(data, input=h, min=mn_start, max=mx_start, nbins=nbins)
        ENDFOR
        
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /finish
    
        ENVI_PLOT_DATA, DINDGEN(nbins), h, plot_title='Kappa Sigma Threshold', $
            title='Kappa Sigma Threshold', base=plot_base
        
        

        ; An undocumented routine, sp_import
        ;http://www.exelisvis.com/Learn/VideoDetail/TabId/323/ArtMID/1318/ArticleID/3974/3974.aspx           
        CASE thresh_method OF
            0: BEGIN
               mn_ = mn_ / binsz + mn_start
               mx_ = mx_ / binsz + mn_start
               print, 'mn_ thresh: ', mn_
               print, 'mx_ thresh: ', mx_
               sp_import, plot_base, [mn_,mn_], !Y.CRange, plot_color=[0,255,0]
               sp_import, plot_base, [mx_,mx_], !Y.CRange, plot_color=[0,0,255]
               END
            1: BEGIN
               mn_ = mn_ / binsz + mn_start
               mx_ = mx_ / binsz + mn_start
               mx_ = (mx_ ge nbins) ? 255 : mx_
               print, 'mn_ thresh: ', mn_
               print, 'mx_ thresh: ', mx_
               sp_import, plot_base, [mn_,mn_], !Y.CRange, plot_color=[0,255,0]
               sp_import, plot_base, [mx_,mx_], !Y.CRange, plot_color=[0,0,255]
               END
            2: BEGIN
               mn_ = mn_ / binsz + mn_start
               mx_ = mx_ / binsz + mn_start
               print, 'mn_ thresh: ', mn_
               print, 'mx_ thresh: ', mx_
               sp_import, plot_base, [mn_,mn_], !Y.CRange, plot_color=[0,255,0]
               sp_import, plot_base, [mx_,mx_], !Y.CRange, plot_color=[0,0,255]
               END
        ENDCASE     
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