;+
; Name:
; -----
;     KAPPA_SIGMA_THRESHOLD_MASK
;-
;
;+
; Description:
; ------------
;     Creates a binary mask from an image using the Kappa-Sigma threshold method.
;     The threshold is calculated using the mean and a standard deviation multiplier.
;     Iterations are used to recalculate the mean and standard deviation from the
;     remaining pixels.
;-
;
;+
; Output options:
; ---------------
;
;     Background: Limit the maximum range.
;     
;     Foreground: Limit the minimum range.
;     
;     Middle: Limit both the minimum and maximum range.
;
;     Invert: The output mask can be inverted.
;     
;     Plot: A plot of the histogram and calculated threshold.
;     
;     Segment Binary Mask: The mask can then be segmented into contiguous regions, where each 
;     region has a unique label.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;-
;
;+ 
; Parameters:
; -----------
; 
;     Min : input::
;   
;         The minumum value to be included in the histogram.
;     
;     Max : input::
;   
;         The maximum value to be included in the histogram.
;     
;     Iterations : input, default=2::
;   
;         The number of iterations to be used in deriving a threshold.
;     
;     Kappa : input, default=0.5::
;   
;         The standard deviation multiplier.
;     
;-
;
;+
; :Author:
;     Josh Sixsmith; joshua.sixsmith@ga.gov.au
;-
;
;+
; Sources:
; --------
; 
;     Lehmann G., 2006, 'Kappa Sigma Clipping', http://hdl.handle.net/1926/367
;     
;     http://deepskystacker.free.fr/english/technical.htm
;-
;
;+
; :History:
; 
;     2013/06/22: Created
;-
;
;+
; :Copyright:
; 
;     Copyright (c) 2013, Josh Sixsmith
;     All rights reserved.
;
;     Redistribution and use in source and binary forms, with or without
;     modification, are permitted provided that the following conditions are met:
;
;     1. Redistributions of source code must retain the above copyright notice, this
;        list of conditions and the following disclaimer. 
;     2. Redistributions in binary form must reproduce the above copyright notice,
;        this list of conditions and the following disclaimer in the documentation
;        and/or other materials provided with the distribution. 
;
;     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
;     ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
;     ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;     (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
;     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
;     ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;     (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;     SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;     The views and conclusions contained in the software and documentation are those
;     of the authors and should not be interpreted as representing official policies, 
;     either expressed or implied, of the FreeBSD Project.
;-
;

;Adding an extra button to the ENVI Menu bar
PRO kappa_sigma_threshold_mask_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Kappa Sigma', $
   EVENT_PRO = 'kappa_sigma_threshold_mask', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

PRO ks_button_help, ev
;+
; :Hidden:
;-
    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'kappa_sigma_threshold_mask.html' 
    ONLINE_HELP, book=book
    
END

PRO kappa_sigma_threshold_mask, event
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

    base = WIDGET_AUTO_BASE(title='Kappa Sigma Parameters')
    row_base1 = WIDGET_BASE(base, /ROW)
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p1', xsize=10, default=data_mn)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p2', xsize=10, default=data_mx)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, default=2, $  
      prompt='Iterations', uvalue='p3', xsize=10)
    p4 = WIDGET_PARAM(row_base1, auto_manage=0, default=0.5, $  
      prompt='Kappa', uvalue='p4', xsize=10)
    
    t_list = ['Background', 'Foreground', 'Middle']
    p_list = ['Plot threshold?']
    i_list = ['Invert Mask?']
    s_list = ['Segment Binary Mask?']
    
    wpm = WIDGET_PMENU(base, list=t_list, default=0, prompt='Select a Threshold Method', $
        uvalue='method', auto_manage=0)
    wm  = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm2 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wm3 = WIDGET_MENU(base, list=s_list, uvalue='segment', rows=1, auto_manage=0)
    wo  = WIDGET_OUTFM(base, uvalue='outfm', prompt='Mask Output', /AUTO)
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Mask Segmentation Output', auto_manage=0)
    wb  = WIDGET_BUTTON(base, value='Help', event_pro='ks_button_help', /ALIGN_CENTER, /HELP)
    
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
     
    IF ((result.outfm.in_memory) EQ 1) THEN BEGIN
        PRINT, 'Output to memory selected'
        
        ; Set up the image tiling routine
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])
        
        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        
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
            ENDFOR
            
            ENVI_REPORT_INIT, base=rbase, /FINISH
            
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
            PRINT, 'mn_: ', mn_
            PRINT, 'mx_: ', mx_            
        ENDFOR
            
        samples = (dims[2] - dims[1]) + 1
        lines = (dims[4] - dims[3]) + 1
        mask = BYTARR(samples, lines)
        xe = dims[2] - dims[1]

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1), $
               'Output to Memory']
        ENVI_REPORT_INIT, rstr, title="Applying threshold", base=rbase
        
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
        ENVI_REPORT_INIT, base=rbase, /FINISH
        
        ENVI_ENTER_DATA, mask, descrip='Kappa Sigma Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info, r_fid=mfid, $
            bnames=['Kappa Sigma Threshold Result: Band 1']
        
        ; Loop over the tiles and calculte the mean and standard deviation
    ENDIF ELSE BEGIN
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
            ENDFOR
            
            ENVI_REPORT_INIT, base=rbase, /FINISH
            
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
        
        OPENW, lun, outfname, /GET_LUN
        
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
        ENVI_REPORT_INIT, base=rbase, /FINISH
        
        ; Close the file
        FREE_LUN, lun
        
        ;Create the header file
        ENVI_SETUP_HEAD, fname=outfname, ns=samples, nl=lines, nb=1, $
            bnames=['Kappa Sigma Threshold Result: Band 1'], data_type=1, $
            offset=0, interleave=0, map_info=map_info, r_fid=mfid, $
            descrip='Kappa Sigma Threshold Result', r_fid=mfid, /WRITE, /OPEN

    ENDELSE

    ;if the plot box is ticked produce an envi plot
    IF (result.plot EQ 1) THEN BEGIN

        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        ; Defaulting to 256 bins
        nbins = 256.
        mx_start = CONVERT_TO_TYPE(mx_start, dtype)
        mn_start = CONVERT_TO_TYPE(mn_start, dtype)
        
        ; Using 'Ceil' should conform with ENVI
        binsz = CONVERT_TO_TYPE((mx_start - mn_start) / (nbins - 1), dtype, /CEIL)
        PRINT, 'mn_start: ', mn_start
        PRINT, 'binsz: ', binsz
        PRINT, 'mx_ change: ', nbins * binsz + mn_start

        ; get the histogram of the first tile
        data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
        h = HISTOGRAM(data, min=mn_start, max=mx_start, binsize=binsz)

        rstr = ['Input File: ' + fname, 'Band Number: ' + STRING(pos + 1)]
        ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

        ;now loop over tiles
        FOR i=1, num_tiles-1 DO BEGIN
            ENVI_REPORT_STAT, rbase, i, num_tiles
            data = FLOAT(ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye))
            h = HISTOGRAM(data, input=h, min=mn_start, max=mx_start, binsize=binsz)
        ENDFOR
        
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /FINISH
    
        ENVI_PLOT_DATA, DINDGEN(N_ELEMENTS(h)), h, plot_title='Kappa Sigma Threshold', $
            title='Kappa Sigma Threshold', base=plot_base
        
        ; An undocumented routine, sp_import
        ;http://www.exelisvis.com/Learn/VideoDetail/TabId/323/ArtMID/1318/ArticleID/3974/3974.aspx
        plot_dtype = SIZE(h, /TYPE)
        mn_ = CONVERT_TO_TYPE((mn_ / binsz + mn_start), plot_dtype)
        mx_ = CONVERT_TO_TYPE((mx_ / binsz + mn_start), plot_dtype)
        PRINT, 'mn_ thresh: ', mn_
        PRINT, 'mx_ thresh: ', mx_
        sp_import, plot_base, [mn_,mn_], !Y.CRange, plot_color=[0,255,0]
        sp_import, plot_base, [mx_,mx_], !Y.CRange, plot_color=[0,0,255]
     
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