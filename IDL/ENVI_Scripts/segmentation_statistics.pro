;+
; Name:
; -----
;     SEGMENTATION_STATISTICS
;-
;
;+
; Description:
; ------------
;     Statistics will be calculated per segmented/classified region.
;     Output statistics are Count, Min, Max, Mean, Variance and Standard Deviation.
;     A Class/Value of zero is considered to be background and not included.
;-
;
;+
; Output options:
; ---------------
;
;     None. An ENVI report text widget will output the results.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;     Both a base and segmented image must be selected.
;     The segmented image must be integer based.
;-
;
;+ 
; Parameters:
; -----------
; 
;     Base : input::
;     
;          The base image from which statistics will be calculated.
;          
;     Mask/Segmented : input::
;     
;          The segmented image whose classes define the regions of which statistics will be calculated for.
;-
;
;+
; :Author:
;     Josh Sixsmith; joshua.sixsmith@ga.gov.au
;-
;
;+
; :History:
; 
;     2013/08/07: Created
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

PRO segmentation_statistics_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Region Statistics', $
   EVENT_PRO = 'segmentation_statistics', $
   REF_VALUE = 'Segmentation', POSITION = 'last', UVALUE = ''

END

PRO segmentation_statistics_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'segmentation_statistics.html'
    ONLINE_HELP, book=book
    
END

PRO segmentation_statistics, event
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

    ; Select the base image to be used for calculating statistics.
    ENVI_SELECT, title='Select Base Image', fid=bfid, pos=bpos, /BAND_ONLY, dims=bdims, $
        /NO_DIMS, /NO_SPEC
    IF (bfid EQ -1) THEN RETURN
        
    ; Select the segmented image to be used for finding regions on which to
    ; base the statistics on.
    ENVI_SELECT, title='Select Mask/Segmented Image ', fid=sfid, pos=spos, /BAND_ONLY, $
        dims=sdims, /NO_DIMS, /NO_SPEC
    IF (sfid EQ -1) THEN RETURN
    
    ; Query both images
    ENVI_FILE_QUERY, bfid, ns=bns, nl=bnl, interleave=binterleave, fname=bfname, nb=bnb, $
        data_type=bdtype
    
    ENVI_FILE_QUERY, sfid, ns=sns, nl=snl, interleave=sinterleave, fname=sfname, nb=snb, $
        data_type=sdtype
        
    ; Check that the datatype of the segmented image is an integer, signed/unsigned 
    ; (8-bit, 16-bit, 32-bit, 64-bit)
    accept_dtypes = [1,2,3,12,13,14,15]
    wh = WHERE(accept_dtypes EQ sdtype, count)
    IF (count EQ 0) THEN BEGIN
        MESSAGE, 'Only Integer Based Images are Supported!'
    ENDIF
    
    ; Check that both images have the same dimensions
    IF (TOTAL(bdims NE sdims) NE 0) THEN BEGIN
        MESSAGE, 'Both Images Must Have The Same Dimensions!'
    ENDIF

    ; Calculate Float or Double
    dbl_types = [5,9,14,15]
    wh  = WHERE(dbl_types EQ bdtype, count)
    dbl = (count EQ 0) ? 0 : 1
    NaN = (dbl EQ 0) ? !VALUES.F_NAN : !VALUES.D_NAN

    ; Need to calculate the global stats of the segmented image first.
    ; This will allow us to determine the number of classes and
    ; specify the upper bound of the histogram.
    ENVI_DOIT, 'envi_stats_doit', fid=sfid, pos=spos, $ 
        dims=sdims, comp_flag=1, dmin=smin, dmax=smax
    
    sdata_mx = MAX(smax, MIN=sdata_mn)
    
    ; In order to determine the number of classes, first generate a histogram
    ; Therefore two passes are needed for this function. 
    ; Pass 1: Get the Class ID's
    ; Pass 2: Calculate the stats
    
    ; Initialise the tiling for both images (base and segmented).
    ; Process each tile as a BSQ, regardless of image interleave.
    ; The number of tiles for each image must be the same.
    ; Use the segmented image as the definition for the number of tiles.
    ; Most of the time it will be of a higher order data type. So in order to
    ; minimise memory use, the segmented image file will need more tiles.
    ; As such the base image will be set to match the tiles from the segmented image.
    stile_id = ENVI_INIT_TILE(sfid, spos, num_tiles=snum_tiles, $
        interleave=0)
        
    btile_id = ENVI_INIT_TILE(bfid, bpos, num_tiles=bnum_tiles, $
        interleave=0, match_id=stile_id)
    
    ; Get the first tile, and initialise the histogram
    sdata = ENVI_GET_TILE(stile_id, 0, ys=ys, ye=ye)
    htotal = HISTOGRAM(sdata, min=1, max=sdata_mx, omin=omin)
    
    rstr = ['Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
    
    ENVI_REPORT_INIT, rstr, title="Determining Number Of Classes", base=rbase
        
    ; Loop over the remaining tiles.
    FOR i=1L, snum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, snum_tiles
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        htotal = HISTOGRAM(sdata, input=htotal, min=1, max=sdata_mx, omin=omin)
    ENDFOR
    
    ENVI_REPORT_INIT, base=rbase, /FINISH
    
    ; Get the class id's
    wh = WHERE(htotal NE 0, count)
    class_ids = wh + omin
    
    ; Allocate the array that will hold the stats
    class_stats = (dbl EQ 0) ? FLTARR(7,count) : DBLARR(7,count)
    
    ; Assign the Class Id's
    class_stats[0,*] = class_ids
    
    ; Initialise Max/Min to NaN
    class_stats[2:3,*] = NaN
    
    rstr = ['Base File: ' + bfname, 'Band Number: ' + STRING(bpos + 1), $
           'Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
           
    ENVI_REPORT_INIT, rstr, title="Calculating Class Statistics", base=rbase
    
    ; Generate a histogram per tile, and loop through each class 
    FOR i=0L, bnum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, bnum_tiles
        ; Assigning the array to either float or double will ensure calculations are
        ; done in that data type.
        bdata = (dbl EQ 0) ? FLOAT(ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye)) : $
                DOUBLE(ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye))
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        ; Need to specify the whole range of the histogram to avoid instances of where it is completely
        ; background data, i.e. values of zero.
        h = HISTOGRAM(sdata, min=1, max=sdata_mx, reverse_indices=ri)
        num_bins = N_ELEMENTS(h)
        print, class_stats[2:3,1]
        FOR c=0L, num_bins-1 DO BEGIN
            IF h[c] EQ 0 THEN CONTINUE
            cdata = bdata[ri[ri[c]:ri[c+1]-1]]
            ; Count
            class_stats[1,c] += h[c]
            min_ = MIN(cdata, MAX=max_)
            ; Class min
            class_stats[2,c] = (FINITE(class_stats[2,c])) ? (class_stats[2,c] < min_) : min_
            ; Class max
            class_stats[3,c] = (FINITE(class_stats[3,c])) ? (class_stats[3,c] > max_) : max_
            ; Sum
            class_stats[4,c] += TOTAL(cdata)
            ; Sum of Squares
            class_stats[5,c] += TOTAL(cdata^2)
        ENDFOR
    ENDFOR
    
    ENVI_REPORT_INIT, base=rbase, /FINISH

    ; Mean
    class_stats[4,*] /= class_stats[1,*]
    
    ; Variance (Recursive formulae)
    class_stats[5,*] = (class_stats[5,*] - (class_stats[1,*] * class_stats[4,*]^2)) / (class_stats[1,*] - 1)
    
    ; Std Dev
    class_stats[6,*] = SQRT(class_stats[5,*])
    
    ; The string argument to envi_info_wid creates a new line for every element
    ; Therefore each column needs to be joined into a single string
    str_class_stats = STRARR(count+4)
    str = ['Class', 'Count', 'Min', 'Max', 'Mean', 'Variance', 'Std. Dev.']
    str_class_stats[0] = 'Base Image: ' + bfname
    str_class_stats[1] = 'Segmented Image: ' + sfname
    str_class_stats[2] = ''
    str_class_stats[3] = STRING(str, format='(7(A20))')
    
    FOR s=0L, count-1 DO BEGIN
        str_class_stats[s+4] = STRING(class_stats[*,s], format='(2(I20), 5(F20.6))')
    ENDFOR
    
    ENVI_INFO_WID, str_class_stats, title='Segmented Regions Statistics Report'
    
END
