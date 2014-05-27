PRO validate_pq_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'PQ', $
   EVENT_PRO = 'validate_pq', $
   REF_VALUE = 'Validation', POSITION = 'last', UVALUE = ''

END

PRO valPQ_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()

    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'validate_pq.html'
    ONLINE_HELP, book=book

END

PRO validate_pq, event
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    CATCH, error
    IF (error NE 0) THEN BEGIN
	msg = [!error_state.msg, 'Click Ok to retry or Cancel to exit.']
        ok = DIALOG_MESSAGE(msg, /CANCEL)
        IF (STRUPCASE(ok) EQ 'CANCEL') THEN RETURN
    ENDIF

    ; Retrieve the temporary directory. Used for file output
    tmp_dir = GETENV('IDL_TMPDIR')

    ; Create the base menu
    base_menu = WIDGET_AUTO_BASE(title='PQ Validation Parameters')
    row_base1 = WIDGET_BASE(base_menu, /ROW)

    ; The tolerance threshold
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, prompt='Tolerance Threshold', $
	    uvalue='tolerance', xsize=10, default=3)

    ; Do we keep the intermediate files
    k_list = ['Keep Intermediate Files?']
    wm     = WIDGET_MENU(base_menu, list=k_list, uvalue='keep', rows=1, auto_manage=0)

    ; Specify the output directory
    wo = WIDGET_OUTF(base_menu, uvalue='outd', prompt='Working Directory', $
             auto_manage=0, /DIRECTORY, default=tmp_dir)

    ; Reference to the html help file
    wb = WIDGET_BUTTON(base_menu, value='Help', event_pro='valPQ_button_help', $
             /ALIGN_CENTER, /HELP)

    ; Gather the user parameters
    result = AUTO_WID_MNG(base_menu)

    ; Exit if chosen
    IF (result.accept EQ 0) THEN RETURN

    ; Get the parameters
    tolerance = result.tolerance
    keep      = result.keep
    out_dir   = result.outd + PATH_SEP()

    ; Check for suitable tolerance
    IF (tolerance LT 0) OR (tolerance GT 100) THEN $
        MESSAGE, 'Tolerance must be in range [0,100]!'

    ; Open the original (reference) PQ file
    ENVI_SELECT, title='Select Reference PQ file', fid=fid_ref, pos=pos_ref, $
                 /BAND_ONLY, /NO_DIMS, /NO_SPEC
    IF (fid_ref EQ -1) THEN RETURN

    ; Get image info
    ENVI_FILE_QUERY, fid_ref, dims=dims_ref, ns=ns_ref, nl=nl_ref, $
                     interleave=interleave_ref, fname=fname_ref

    ; Get image projection info
    map_info_ref = ENVI_GET_MAP_INFO(fid=fid_ref)

    ; Open the new (test) PQ file
    ENVI_SELECT, title='Select Test PQ file', fid=fid_test, pos=pos_test, $
	         /BAND_ONLY, /NO_DIMS, /NO_SPEC
    IF (fid_test EQ -1) THEN RETURN

    ; Get image info
    ENVI_FILE_QUERY, fid_test, dims=dims_test, ns=ns_test, nl=nl_test, $
                     interleave=interleave_test, fname=fname_test

    ; Get image projection info
    map_info_test = ENVI_GET_MAP_INFO(fid=fid_test)

    ; Check that both images have the same dimensions
    IF (TOTAL(dims_ref NE dims_test) NE 0) THEN BEGIN
        MESSAGE, 'Both Images Must Have The Same X & Y Dimensions!'
    ENDIF

    ; Check that both images have the same co-ordinate reference system
    map_str_ref  = map_info_ref.proj.pe_coord_sys_str
    map_str_test = map_info_test.proj.pe_coord_sys_str
    IF (map_str_ref NE map_str_test) THEN BEGIN
        str1 = 'The reference PQ and the test PQ have different co-ordinate reference systems.'
	str2 = 'Reference Dataset'
	str3 = 'Test Dataset'
	str4 = 'Co-ordinate Reference System Test Failed!'
	str5 = 'PQ Validation Test Failed!'
	str6 = 'Check for correct input PQ reference and test datasets.'

	err_str  = [str1, '', str2, fname_ref, map_str_ref, '', $
		    str3, fname_test, map_str_test, '', str4, $
		    str5, str6]

        ENVI_INFO_WID, err_str, title='PQ Validation Report'
	RETURN
    ENDIF

    ; First step is band math
    str_exp = 'abs(long(b1) - b2)'
    fid     = [fid_ref, fid_test]
    pos     = [pos_ref, pos_test]

    bmath_fname = out_dir + 'bmath_result_PQ_diff'

    ENVI_DOIT, 'math_doit', fid=fid, pos=pos, dims=dims_ref, exp=str_exp, $
               out_name=bmath_fname, r_fid=diff_fid

    ENVI_FILE_QUERY, diff_fid, dims=dims, ns=ns, nl=nl, interleave=interleave, $
	       data_type=dtype

    ; Now to calculate the min and max. We need this for the histogram
    ENVI_DOIT, 'envi_stats_doit', fid=diff_fid, pos=pos, $ 
               dims=dims, comp_flag=1, dmin=dmin, dmax=dmax
    
    data_mx = MAX(dmax)
    data_mn = MIN(dmin)

    ; The datatype should be LONG as defined by str_exp
    ; but just in case...
    ; See IDL Histogram help as to why we do the datatype conversion
    mx = CONVERT_TO_TYPE(data_mx, dtype)
    mn = CONVERT_TO_TYPE(0, dtype)

    ; In order to keep the memory consumption to a minimum, we tile the array
    tile_id = ENVI_INIT_TILE(diff_fid, pos, num_tiles=num_tiles)

    ; Calculate the histogram of the first tile
    data = ENVI_GET_TILE(tile_id, 0)
    h = HISTOGRAM(data, min=mn, max=mx)

    ; Initialise the Percent Complete Window
    rstr = ['Input File: ' + bmath_fname]
    ENVI_REPORT_INIT, rstr, title="Calculating Histogram", base=rbase

    ; Now loop over the remaining tiles
    FOR i=1L, num_tiles-1 DO BEGIN
        ENVI_REPORT_STAT, rbase, i, num_tiles
	data = ENVI_GET_TILE(tile_id, i)
	h = HISTOGRAM(data, input=h, min=mn, max=mx)
    ENDFOR

    ; Close the Percent Complete Window
    ENVI_REPORT_INIT, base=rbase, /FINISH

    ; Now to calculate some stats on the histgoram
    array_sz = nl * ns
    cumu_h   = TOTAL(h, /CUMULATIVE, /DOUBLE)
    pdf      = cumu_h / array_sz

    ; Initialise the output string
    out_str1 = 'Reference Dataset'
    out_str2 = 'Test Dataset'
    out_str  = [out_str1, fname_ref, out_str2, fname_test, '']

    ; Report the percentage of no difference pixels
    diff     = pdf[0]
    diff_str = STRING(format = '("Percent No Difference:", F10.2, "%")', diff)

    ; Initialise the main report widget
    out_str = [out_str, diff_str, '']

    ; Check that the difference is < 3% (This could be a user variable)
    IF (diff GT (100 - tolerance)) THEN BEGIN
        str1 = 'Difference Threshold is Acceptable'
	str2 = STRING(format = '(F10.2, "    >=", F10.2)', diff, (100 - tolerance))

	out_str = [out_str, str1, str2]
    ENDIF ELSE BEGIN
	str1 = 'Difference Threshold Failed!'
	str2 = STRING(format = '(F10.2, "    <", F10.2)', diff, (100 - tolerance))
	str3 = 'Requires Further Investigation.'

	out_str = [out_str, str1, str2, str3, '']
    ENDELSE

    ; Now to compare the reference and test datasets for every PQ test
    out_nb = N_ELEMENTS(bits)

    ; Define the description fiels for the PQ extraction
    description = 'ULA pixel quality bit mask extraction'

    ; Define the bit positions for PQ extraction
    bits = [1,2,4,8,16,32,64,128, $
            256,512,1024,2048,4096, $
            8192 $
           ]

    ; Define the band names for PQ extraction
    bnames = ['Band 1 Saturation', $
              'Band 2 Saturation', $
              'Band 3 Saturation', $
              'Band 4 Saturation', $
              'Band 5 Saturation', $
              'Band 61 Saturation', $
              'Band 62 Saturation', $
              'Band 7 Saturation', $
              'Band Contiguity', $
              'Land/Sea', $
              'ACCA', $
              'Fmask', $
              'ACCA Cloud Shadow', $
              'Fmask Cloud Shadow' $
             ]

    ; Define the output filenames
    ref_PQextract_fname  = out_dir + 'ref_PQextract'
    test_PQextract_fname = out_dir + 'test_PQextract'

    ; Open the files for writing to disk
    OPENW, lun1, ref_PQextract_fname, /GET_LUN
    OPENW, lun2, test_PQextract_fname, /GET_LUN

    ; Initialise the Percent Complete Window
    rstr = ['Input File: ' + ref_PQextract_fname]

    ; Extract the reference dataset
    FOR i=0, out_nb-1 DO BEGIN
        ENVI_REPORT_INIT, rstr, title="Processing Bit Extraction", base=base

	tile_id = ENVI_INIT_TILE(fid_ref, pos_ref, num_tiles=num_tiles, interleave=0)

	FOR t=0L, num_tiles-1 DO BEGIN
	    ENVI_REPORT_STAT, base, t, num_tiles
            data = ENVI_GET_TILE(tile_id, t)
	    ext  = (data AND bits[i]) EQ bits[i]
	    WRITEU, lun1, ext
	ENDFOR

        ;Close the tiling procedure and the Percent Complete window
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=base, /FINISH
    ENDFOR

    ; Initialise the Percent Complete Window
    rstr = ['Input File: ' + test_PQextract_fname]

    ; Extract the test dataset
    FOR i=0, out_nb-1 DO BEGIN
        ENVI_REPORT_INIT, rstr, title="Processing Bit Extraction", base=base

	tile_id = ENVI_INIT_TILE(fid_test, pos_test, num_tiles=num_tiles, interleave=0)

	FOR t=0L, num_tiles-1 DO BEGIN
	    ENVI_REPORT_STAT, base, t, num_tiles
            data = ENVI_GET_TILE(tile_id, t)
	    ext  = (data AND bits[i]) EQ bits[i]
	    WRITEU, lun2, ext
	ENDFOR

        ;Close the tiling procedure and the Percent Complete window
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=base, /FINISH
    ENDFOR

    ; Close the files
    FREE_LUN, lun1
    FREE_LUN, lun2

    ; Create the header files for the extracted reference and test datasets
    ENVI_SETUP_HEAD, fname=ref_PQextract_fname, ns=ns_ref, nl=nl_ref, $
            nb=out_nb, data_type=1, offset=0, interleave=0, $
	    map_info=map_info_ref, descrip=description, $
	    r_fid=extract_ref_fid, /WRITE, /OPEN

    ENVI_SETUP_HEAD, fname=test_PQextract_fname, ns=ns_test, nl=nl_test, $
            nb=out_nb, data_type=1, offset=0, interleave=0, $
	    map_info=map_info_test, descrip=description, $
	    r_fid=extract_test_fid, /WRITE, /OPEN

    ; The extracted PQ datasets are written now for bandwise comparison
    ; Multiple calls to MATH_DOIT would be simple enough...
    ; we would then be creating more files to manage though.
    ; Processing by spectral tile would allow a single file to be generated.

    ; Define the band positions
    pos = LINDGEN(out_nb)

    ; Define the output filename
    out_fname = out_dir + 'Diff_per_PQ_test'

    ; Open the file for writing to disk
    OPENW, lun, out_fname, /GET_LUN

    ; Initialise the tiling sequence
    ref_tile_id  = ENVI_INIT_TILE(extract_ref_fid, pos, interleave=2, $
	           num_tiles=num_tiles)
    test_tile_id = ENVI_INIT_TILE(extract_test_fid, pos, interleave=2, $
	           match_id=ref_tile_id)

    ; Initialise the Percent Complete Window
    rstr = ['Reference PQ Dataset: ' + ref_PQextract_fname]
    rstr = [rstr, 'Test PQ Dataset: ' + test_PQextract_fname]
    ENVI_REPORT_INIT, rstr, title="Calculating Difference per PQ Test", base=base

    ; Loop through the tiles
    FOR t=0L, num_tiles-1 DO BEGIN
	ENVI_REPORT_STAT, base, t, num_tiles
        ref_data  = FIX(ENVI_GET_TILE(ref_tile_id, t))
	test_data = ENVI_GET_TILE(test_tile_id, t)

	result = ref_data - test_data
	WRITEU, lun, result
    ENDFOR

    ;Close the tiling procedure and the Percent Complete window
    ENVI_TILE_DONE, ref_tile_id
    ENVI_TILE_DONE, test_tile_id
    ENVI_REPORT_INIT, base=base, /FINISH

    ; Close the file
    FREE_LUN, lun

    ; Define the description fiels for the PQ difference test
    description = 'Difference per PQ test.'

    ; Create the header files for the reference and test datasets
    ENVI_SETUP_HEAD, fname=out_fname, ns=ns_ref, nl=nl_ref, $
            nb=out_nb, data_type=2, offset=0, interleave=2, $
	    map_info=map_info_ref, descrip=description, $
	    r_fid=diff_per_test_fid, /WRITE, /OPEN

    ; Query the image to get the correct info
    ENVI_FILE_QUERY, diff_per_test_fid, dims=dims, nl=nl, nb=nb, ns=ns

    ; Now to generate some stats on the differences
    ; It might be simple enough to use the envi_stats_doit routine
    ENVI_DOIT, 'envi_stats_doit', fid=diff_per_test_fid, pos=pos, $
               dims=dims, comp_flag=3, dmin=dmin, dmax=dmax, $
	       hist=hist, report_flag=3, /TO_SCREEN

    ; Purge intermediate files?
    IF (keep EQ 0) THEN BEGIN
        ENVI_FILE_MNG, id=diff_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=extract_ref_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=ectract_test_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=diff_per_test_fid, /REMOVE, /DELETE
    ENDIF

    ; Now to output the main report widget
    out_str = [out_str, 'PQ Validation Has Completed!']
    ENVI_INFO_WID, out_str, title='PQ Validation Report'

END
