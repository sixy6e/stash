;+
; Name:
; -----
;     VALIDATE_PQ
;-
;
;+
; Description:
; ------------
;     Performs a validation for a Geoscience Australia National Earth and 
;     Marine Observation pixel quality (PQ) product.
;     The basis is to compare a new PQ product with a previous version to
;     ensure that the result is behaving as expected.
;     Uses a reference image and the image under investigation (test image.
;-
;
;+
; Output options:
; ---------------
;     None. The procedure will output files automatically which are then
;     removed at the end (unless the user opts to keep the intermediate
;     files.  Two reports are generated at the end which can be saved to
;     ascii text files.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;-
; Parameters:
; -----------
;
;     Global Tolerance Threshold : input, default=3::
;
;         The global tolerance threshold is used for determining acceptable levels
;         of difference and is applied to the raw datasets.
;         Eg, a value of 3 (default) indicates that if more than 3% of the image
;         differs, then flag it as a potential issue.
;
;     Per Test Tolerance Threshold : input::
;
;         The per test tolerance threshold is used for determining acceptable levels
;         of difference and is applied for each PQ test, ACCA, Fmask, Saturation etc.
;         Eg, a value of 2 (default) indicates that if more than 2% of the image
;         differs, then flag it as a potential issue.
;
;     Keep Intermediate Files : input, default=Unchecked::
;
;         If unchecked (default), then all intermediate files will be deleted
;         at the end of the workflow.
;
;     Working Directory : input, default=IDL environment variable IDL_TMPDIR::
;
;         Specify the working directory for intermediate files to be written
;         to disk.  The default is to use IDL's environment variable IDL_TMPDIR.
;
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
;     2014/05/26: Created
;-
;
;
; :Copyright:
;
;     Copyright (c) 2014, Josh Sixsmith
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

PRO validate_pq_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Compare PQ Versions', $
   EVENT_PRO = 'validate_pq', $
   REF_VALUE = 'General Tools', POSITION = 'last', UVALUE = ''

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
    row_base2 = WIDGET_BASE(base_menu, /ROW)

    ; The global tolerance threshold
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, prompt='Global Tolerance Threshold', $
             uvalue='g_tolerance', xsize=10, default=3)

    ; The global tolerance threshold
    p2 = WIDGET_PARAM(row_base2, auto_manage=0, dt=4, prompt='Per Test Tolerance Threshold', $
             uvalue='pt_tolerance', xsize=10, default=2)

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
    g_tol   = result.g_tolerance
    pt_tol  = result.pt_tolerance
    keep    = result.keep
    out_dir = result.outd + PATH_SEP()

    ; Check for suitable global tolerance
    IF (g_tol LT 0) OR (g_tol GT 100) THEN $
        MESSAGE, 'Tolerance must be in range [0,100]!'

    ; Check for suitable per test tolerance
    IF (pt_tol LT 0) OR (pt_tol GT 100) THEN $
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
        data_type=dtype, nb=nb

    ; Reset pos
    pos = LINDGEN(nb)

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
    array_sz = ULONG64(nl) * ns
    cumu_h   = TOTAL(h, /CUMULATIVE, /DOUBLE)
    pdf      = (cumu_h / array_sz) * 100

    ; Initialise the output string
    out_str1 = 'Reference Dataset'
    out_str2 = 'Test Dataset'
    out_str  = [out_str1, fname_ref, out_str2, fname_test, '']

    ; Report the percentage of no difference pixels
    diff     = pdf[0]
    diff_str = STRING(format = '("Percent No Difference:", F10.4, "%")', diff)

    ; Initialise the main report widget
    out_str = [out_str, diff_str, '']

    ; Check that the difference is < 3% (This could be a user variable)
    IF (diff GT (100 - g_tol)) THEN BEGIN
        str1 = 'Difference Threshold is Acceptable'
        str2 = STRING(format = '(F10.4, "    >=", F10.4)', diff, (100 - g_tol))

        out_str = [out_str, str1, str2, '']
    ENDIF ELSE BEGIN
        str1 = 'Difference Threshold Failed!'
        str2 = STRING(format = '(F10.4, "    <", F10.4)', diff, (100 - g_tol))
        str3 = 'Requires Further Investigation.'

        out_str = [out_str, str1, str2, str3, '']
    ENDELSE

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

    ; Now to compare the reference and test datasets for every PQ test
    out_nb = N_ELEMENTS(bits)

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

    ; Normalise the histogram and convert to percent
    hist = (hist * 100.0D) / array_sz

    ; Report the percent no differences on a per test level
    idxs = LONARR(out_nb)
    FOR i=0, out_nb-1 DO BEGIN
        CASE dmin[i] OF
            -1 : BEGIN
                     idxs[i] = 1
                     IF (hist[1,i] GT (100 - pt_tol)) THEN BEGIN
                         str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                         str2 = 'Difference Threshold is Acceptable'
                         str3 = STRING(format = '(F10.4, "    >=", F10.4)', $
                                hist[1,i], (100 - pt_tol))

                         out_str = [out_str, str1, str2, str3, '']
                     ENDIF ELSE BEGIN
                         str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                         str2 = 'Difference Threshold Failed!'
                         str3 = STRING(format = '(F10.4, "    <", F10.4)', $
                                hist[1,i], (100 - pt_tol))
                         str4 = 'Requires Further Investigation.'

                         out_str = [out_str, str1, str2, str3, str4, '']
                     ENDELSE
                 END
             0 : BEGIN
                     idxs[i] = 0
                     IF (hist[0,i] GT (100 - pt_tol)) THEN BEGIN
                         str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                         str2 = 'Difference Threshold is Acceptable'
                         str3 = STRING(format = '(F10.4, "    >=", F10.4)', $
                                hist[0,i], (100 - pt_tol))

                         out_str = [out_str, str1, str2, str3, '']
                     ENDIF ELSE BEGIN
                         str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                         str2 = 'Difference Threshold Failed!'
                         str3 = STRING(format = '(F10.4, "    <", F10.4)', $
                                hist[0,i], (100 - pt_tol))
                         str4 = 'Requires Further Investigation.'

                         out_str = [out_str, str1, str2, str3, str4, '']
                     ENDELSE
                 END
             1 : BEGIN
                     str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                     str2 = STRING(format = '(%"%s Test Has Not Identified Any Pixels As Compared To The Reference Dataset!")', bnames[i])
                     str3 = 'Requires Further Investigation.'

                     out_str = [out_str, str1, str2, str3, '']
                 END
             ELSE : BEGIN
                        str1 = STRING(format = '(%"PQ Test: %s")', bnames[i])
                        str2 = STRING(format = '(%"Unexpected Minimum Value %f")', dmin[i])
                        str3 = 'Expected Values in range [-1,1]'
                        str4 = 'Requires Further Investigation.'

                        out_str = [out_str, str1, str2, str3, str4, '']
                    END
        ENDCASE
    ENDFOR

    ; Purge intermediate files?
    IF (keep EQ 0) THEN BEGIN
        ENVI_FILE_MNG, id=diff_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=extract_ref_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=extract_test_fid, /REMOVE, /DELETE
        ENVI_FILE_MNG, id=diff_per_test_fid, /REMOVE, /DELETE
    ENDIF

    ; Now to output the main report widget
    out_str = [out_str, 'PQ Validation Has Completed!']
    ENVI_INFO_WID, out_str, title='PQ Validation Report'

END
