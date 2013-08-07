;+
; Name:
; -----
;     TRIANGLE_THRESHOLD_MASK
;-
;
;+
; Description:
; ------------
;     Creates a binary mask from an image using the Triangle threshold method.
;     The threshold is calculated as the point of maximum perpendicular distance
;     of a line between the histogram peak and the farthest non-zero histogram edge
;     to the histogram.
;-
;
;+
; Output options:
; ---------------
;     The output mask can be inverted.
;     A plot of the histogram and calculated threshold.
;     The mask can then be segmented into contiguous regions, where each 
;     region has a unique label.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;     Either the Binsize or the the number of bins (Nbins) must be selected.
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
;     Binsize : input, optional::
;   
;         The binsize to use in calculating the histogram.
;     
;     Nbins : input, optional::
;   
;         The number of bins to use in calculating the histogram.
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
;     G.W. Zack, W.E. Rogers, and S.A. Latt. Automatic measurement of sister 
;         chromatid exchange frequency. Journal of Histochemistry & Cytochemistry, 
;         25(7):741, 1977. 1, 2.1
;-
;
;+
; :History:
; 
;     2013/06/08: Created
;     
;     2013/06/15: Added Binsize input argument
;                 Now use 'sp_import' rather than oplot and plots
;                 in order to maintain visual aspects when resizing the plot.
;-
;
;
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
;
;

;Adding an extra button to the ENVI Menu bar
PRO triangle_threshold_mask_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Triangle', $
   EVENT_PRO = 'triangle_threshold_mask', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

PRO tri_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'triangle_threshold_mask.html' 
    ONLINE_HELP, book=book
    
END

FUNCTION calculate_triangle_threshold, histogram=h, xone=x1, ytwo=y2
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

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
               h = HISTOGRAM(data, min=mn_, max=mx_, binsize=binsz)

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
               h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_)

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

        ;calculate threshold
        thresh = CALCULATE_TRIANGLE_THRESHOLD(histogram=h, xone=x1, ytwo=y2)
        thresh_convert = thresh * binsz + mn_

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
                FOR i=0L, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data GE thresh_convert) AND (data LE mx_)
                ENDFOR
               END
            1: BEGIN
                FOR i=0L, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask[0:xe,ys:ye] = (data LT thresh_convert) AND (data GE mn_)
                ENDFOR
               END
        ENDCASE

        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=rbase, /FINISH

        ENVI_ENTER_DATA, mask, descrip='Triangle Threshold Result', xstart=dims[1], $
            ystart=dims[3], map_info=map_info, r_fid=mfid, $
            bnames=['Triangle Threshold Result: Band 1']
        
    ENDIF ELSE BEGIN
        outfname = result.outfm.name
        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
            interleave=0, xs=dims[1], xe=dims[2], $
            ys=dims[3], ye=dims[4])

        CASE bnsz_nbin OF
            0: BEGIN
               ; get the histogram of the first tile
               data = ENVI_GET_TILE(tile_id, 0, ye=ye, ys=ys)
               h = HISTOGRAM(data, min=mn_, max=mx_, binsize=binsz)

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
               h = HISTOGRAM(data, min=mn_, max=mx_, nbins=nbins_)

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

        ;calculate threshold
        thresh = CALCULATE_TRIANGLE_THRESHOLD(histogram=h, xone=x1, ytwo=y2)
        thresh_convert = thresh * binsz + mn_

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
                FOR i=0L, num_tiles-1 DO BEGIN 
                    ENVI_REPORT_STAT, rbase, i, num_tiles
                    data = ENVI_GET_TILE(tile_id, i, ys=ys, ye=ye)
                    mask = (data LT thresh_convert) AND (data GE mn_)
                    WRITEU, lun, mask
                ENDFOR
               END
            1: BEGIN
                FOR i=0L, num_tiles-1 DO BEGIN 
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
            bnames=['Triangle Threshold Result: Band 1'], data_type=1, $
            offset=0, interleave=0, map_info=map_info, $
            descrip='Triangle Threshold Result', r_fid=mfid, /WRITE, /OPEN

    ENDELSE

    ;if the plot box is ticked produce an envi plot
    IF (result.plot EQ 1) THEN BEGIN
        ENVI_PLOT_DATA, DINDGEN(N_ELEMENTS(h)), h, plot_title='Triangle Threshold', $
            title='Triangle Threshold', base=plot_base
                
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
 
