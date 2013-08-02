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
    IF (fid EQ -1) THEN RETURN
        
    ;Select the segmented image to be used for finding regions on which to
    ;base the statistics on.
    ENVI_SELECT, title='Select Mask/Segmented Image ', fid=sfid, pos=spos, /BAND_ONLY, dims=sdims
    IF (fid EQ -1) THEN RETURN
    
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

    ;Probably need to calculate the global stats of the segmented image first.
    ;This will allow us to determine the number of classes.
    ;ENVI_DOIT, 'envi_stats_doit', fid=sfid, pos=spos, $ 
    ;    dims=sdims, comp_flag=1, dmin=smin, dmax=smax
    
    ;sdata_mx = MAX(smax)
    ;sdata_mn = MIN(smin)
    
    ;In order to determine the number of classes, first generate a histogram
    ;Therefore two passes are needed for this function. 
    ;Pass 1: Get the Class ID's
    ;Pass 2: Calculate the stats


    ;Allocate the array that will hold the stats
    
    ;Initialise the tiling for both images (base and segmented).
    ;Process each tile as a BSQ, regardless of image interleave.
    btile_id = ENVI_INIT_TILE(bfid, bpos, num_tiles=bnum_tiles, $
        interleave=0, xs=bdims[1], xe=bdims[2], $
        ys=bdims[3], ye=bdims[4])

    stile_id = ENVI_INIT_TILE(sfid, spos, num_tiles=snum_tiles, $
        interleave=0, xs=sdims[1], xe=sdims[2], $
        ys=sdims[3], ye=sdims[4])
    
    sdata = ENVI_GET_TILE(stile_id, 0, ys=ys, ye=ye)
    htotal = HISTOGRAM(sdata, input=htotal, min=1, omin=omin)
    
    rstr = ['Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
    ENVI_REPORT_INIT, rstr, title="Determining Number Of Classes", base=rbase
        
    ;Loop over the remaining tiles.
    FOR i=1, snum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, snum_tiles
        ;bdata = ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye)
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        ;h = HISTOGRAM(sdata, min=1, omin=omin, omax=omax, reverse_indices=ri)
        htotal = HISTOGRAM(sdata, input=htotal, min=1, omin=omin)
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
    class_stats = (dbl EQ 0) ? FLTARR(4,count) : DBLARR(4,count)
    class_stats[0,*] = class_ids
    
    rstr = ['Base File: ' + bfname, 'Band Number: ' + STRING(bpos + 1), $
           'Segmentation File: ' + sfname, 'Band Number: ' + STRING(spos + 1)]
    ENVI_REPORT_INIT, rstr, title="Calculating Class Statistics", base=rbase
    
    FOR i=0, bnum_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, bnum_tiles
        bdata = ENVI_GET_TILE(btile_id, i, ys=ys, ye=ye)
        sdata = ENVI_GET_TILE(stile_id, i, ys=ys, ye=ye)
        h = HISTOGRAM(sdata, min=1, reverse_indices=ri)
        num_bins = N_ELEMENTS(h)
        FOR b=0, num_bins-1 DO BEGIN
            IF h[b] EQ 0 THEN CONTINUE
            class_stats[1,b] = MEAN(bdata[ri[ri[b]:ri[b+1]-1]])
            class_stats[2,b] = VARIANCE(bdata[ri[ri[b]:ri[b+1]-1]])
        ENDFOR
    ENDFOR
    
    ENVI_REPORT_INIT, base=rbase, /FINISH
    
    class_stats[3,*] = SQRT(class_stats[2,*])
    ;if we use a string array
    ;class_stats[3,*] = SQRT(FLOAT(class_stats[2,*]))
    
    ;str_class_stats = STRARR(4, count+1)
    ;str_class_stats[*,0] = ['Class', 'Mean', 'Variance', 'Standard Deviation']
    
    ;The string argument to envi_info_wid creates a new line for every element
    ;So need to join the columns
    str_class_stats = STRARR(count+1)
    str_class_stats[0] = ['Class          Mean          Variance           Standard Deviation']
    ENVI_INFO_WID, str_class_stats
    
END
