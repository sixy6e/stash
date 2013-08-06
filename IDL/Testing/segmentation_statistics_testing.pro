PRO segmentation_statistics_testing_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Seg_Stats', $
   EVENT_PRO = 'segmentation_statistics_testing', $
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

PRO segmentation_statistics_testing, event
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

    ;Select the base image to be used for calculating statistics.
    ENVI_SELECT, title='Select Base Image', fid=bfid, pos=bpos, /BAND_ONLY, dims=bdims
    IF (bfid EQ -1) THEN RETURN
        
    ;Select the segmented image to be used for finding regions on which to
    ;base the statistics on.
    ENVI_SELECT, title='Select Mask/Segmented Image ', fid=sfid, pos=spos, /BAND_ONLY, dims=sdims
    IF (sfid EQ -1) THEN RETURN
    
    ;Query both images
    ENVI_FILE_QUERY, bfid, ns=bns, nl=bnl, interleave=binterleave, fname=bfname, nb=bnb, $
        data_type=bdtype
    
    ENVI_FILE_QUERY, sfid, ns=sns, nl=snl, interleave=sinterleave, fname=sfname, nb=snb, $
        data_type=sdtype
        
    ;Check that the datatype of the segmented image is an integer, signed/unsigned 
    ;(8-bit, 16-bit, 32-bit, 64-bit)
    accept_dtypes = [1,2,3,12,13,14,15]
    wh = WHERE(sdtype EQ accept_dtypes, count)
    IF (count EQ 0) THEN BEGIN
        MESSAGE, 'Only Integer Based Images are Supported!'
    ENDIF
    
    ;Check that both images have the same dimensions
    IF (TOTAL(bdims NE sdims) NE 0) THEN BEGIN
        MESSAGE, 'Both Images Must Have The Same Dimensions!'
    ENDIF

    ;Calculate Float or Double
    dbl_types = [5,9,14,15]
    wh = WHERE(bdtype EQ dbl_types, count)
    dbl = (count EQ 0) ? 0 : 1
    NaN = (dbl EQ 0) ? !VALUES.F_NAN : !VALUES.D_NAN

    ;Probably need to calculate the global stats of the segmented image first.
    ;This will allow us to determine the number of classes.
    ENVI_DOIT, 'envi_stats_doit', fid=sfid, pos=spos, $ 
        dims=sdims, comp_flag=1, dmin=smin, dmax=smax
    
    sdata_mx = MAX(smax, MIN=sdata_mn)
    ;sdata_mn = MIN(smin)
    
    ;In order to determine the number of classes, first generate a histogram
    ;Therefore two passes are needed for this function. 
    ;Pass 1: Get the Class ID's
    ;Pass 2: Calculate the stats


    ;Allocate the array that will hold the stats
    
    ;Initialise the tiling for both images (base and segmented).
    ;Process each tile as a BSQ, regardless of image interleave.
    ;The number of tiles for each image must be the same
    btile_id = ENVI_INIT_TILE(bfid, bpos, num_tiles=bnum_tiles, $
        interleave=0, xs=bdims[1], xe=bdims[2], $
        ys=bdims[3], ye=bdims[4])

    ;stile_id = ENVI_INIT_TILE(sfid, spos, num_tiles=snum_tiles, $
    ;    interleave=0, xs=sdims[1], xe=sdims[2], $
    ;    ys=sdims[3], ye=sdims[4])
    stile_id = ENVI_INIT_TILE(sfid, spos, num_tiles=snum_tiles, $
        interleave=0, match_id=btile_id)
    
    sdata = ENVI_GET_TILE(stile_id, 0, ys=ys, ye=ye)
    htotal = HISTOGRAM(sdata, min=1, max=sdata_mx, omin=omin)
    
    rstr = ['Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
    
    ENVI_REPORT_INIT, rstr, title="Determining Number Of Classes", base=rbase
        
    ;Loop over the remaining tiles.
    FOR i=1, snum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, snum_tiles
        ;bdata = ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye)
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        ;h = HISTOGRAM(sdata, min=1, omin=omin, omax=omax, reverse_indices=ri)
        htotal = HISTOGRAM(sdata, input=htotal, min=1, max=sdata_mx, omin=omin)
    ENDFOR
    
    ENVI_REPORT_INIT, base=rbase, /FINISH
    
    ;Get the class id's
    wh = WHERE(htotal NE 0, count)
    class_ids = wh + omin
    
    ;Allocate the array that will hold the stats
    ;It might be better to generate the string array from the start
    ;rather than convert at the end. Might even use less memory.
    ;class_stats = STRARR(4,count+1)
    ;class_stats[*,0] = ['Class', 'Mean', 'Variance', 'Standard Deviation']
    ;If one method is faster, go with that.
    ;The string method may not work as well as first thought. As we need to calculate
    ;stats using recursive formulae, converting to and from strings everytime may
    ;degrade performance.
    class_stats = (dbl EQ 0) ? FLTARR(7,count) : DBLARR(7,count)
    class_stats[0,*] = class_ids
    class_stats[2:3,*] = NaN
    ;Initialise the min column to be the max
    ;Initialise the max column to be the min
    ;class_stats[2] = sdata_mx
    ;class_stats[3] = sdata_mn
    print, class_stats[2:3,1]
    
    rstr = ['Base File: ' + bfname, 'Band Number: ' + STRING(bpos + 1), $
           'Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
           
    ENVI_REPORT_INIT, rstr, title="Calculating Class Statistics", base=rbase
    
    ;Generate a histogram per tile, and loop through each class 
    FOR i=0, bnum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, bnum_tiles
        bdata = (dbl EQ 0) ? FLOAT(ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye)) : $
                DOUBLE(ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye))
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        h = HISTOGRAM(sdata, min=1, reverse_indices=ri)
        num_bins = N_ELEMENTS(h)
        print, class_stats[2:3,1]
        FOR c=0, num_bins-1 DO BEGIN
            IF h[c] EQ 0 THEN CONTINUE
            cdata = bdata[ri[ri[c]:ri[c+1]-1]]
            ;class_stats[2,c] = MEAN(bdata[ri[ri[c]:ri[c+1]-1]])
            ;class_stats[3,c] = VARIANCE(bdata[ri[ri[c]:ri[c+1]-1]])
            ;How to determine the min/max? can't use the initial state as it
            ;will be zero or something very small (when using /nozero).
            ;But i need to compare it against a previous result in case a class
            ;crosses a tile boundary and min/max needs updating.
            ;Maybe set to NaN, and do finite check
            ;or if not finite set to min
            ;eg (FINITE(A)) ? ( A > B ) : B
            
            class_stats[1,c] += h[c] ;Count
            
            min_ = MIN(cdata, MAX=max_)
            
            ;class min
            class_stats[2,c] = (FINITE(class_stats[2,c])) ? (class_stats[2,c] < min_) : min_
            ;class max
            class_stats[3,c] = (FINITE(class_stats[3,c])) ? (class_stats[3,c] > max_) : max_
            ;class_stats[2,c] = class_stats[2,c] < min_
            ;class_stats[3,c] = class_stats[3,c] > max_
            class_stats[4,c] += TOTAL(cdata) ;Sum
            class_stats[5,c] += TOTAL(cdata^2) ;Sum of Squares
        ENDFOR
    ENDFOR
    
    ENVI_REPORT_INIT, base=rbase, /FINISH
    
    ;class_stats[3,*] = SQRT(class_stats[2,*])
    ;if we use a string array
    ;class_stats[3,*] = SQRT(FLOAT(class_stats[2,*]))

    ;Variance (alternate method)
    ;class_stats[5,*] = (class_stats[5,*] - (class_stats[4,*]^2 / class_stats[1,*])) / (class_stats[1,*] - 1)

    ;Mean
    class_stats[4,*] /= class_stats[1,*]
    
    ; This is a way of calculating the standard deviation in a tiling mechanism
    ;sigma_  = SQRT((sq_sum - cnt * mu_^2)/(cnt - 1))
    ;Variance
    class_stats[5,*] = (class_stats[5,*] - (class_stats[1,*] * class_stats[4,*]^2)) / (class_stats[1,*] - 1)
    
    ;Std Dev
    class_stats[6,*] = SQRT(class_stats[5,*])
    
    ;str_class_stats = STRARR(4, count+1)
    ;str_class_stats[*,0] = ['Class', 'Mean', 'Variance', 'Standard Deviation']
    
    ;The string argument to envi_info_wid creates a new line for every element
    ;So need to join the columns
    str_class_stats = STRARR(count+4)
    str = ['Class', 'Count', 'Min', 'Max', 'Mean', 'Variance', 'Std. Dev.']
    str_class_stats[0] = 'Base Image: ' + bfname
    str_class_stats[1] = 'Segmented Image: ' + sfname
    str_class_stats[2] = ''
    str_class_stats[3] = STRING(str, format='(7(A20))')
    
    FOR s=0, count-1 DO BEGIN
        str_class_stats[s+4] = STRING(class_stats[*,s], format='(2(I20), 5(F20.6))')
    ENDFOR
    
    ENVI_INFO_WID, str_class_stats
    
END
