;Adding an extra button to the ENVI Menu bar
PRO ula_pq_extract_test_define_buttons, buttonInfo

;ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'GA Tools', $
;   /MENU, REF_VALUE = 'Help', /SIBLING, POSITION = 'after'
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Extract PQ Bit Masks', $
   EVENT_PRO = 'ula_pq_extract', $
   REF_VALUE = 'GA Tools', POSITION = 'last', UVALUE = ''

END

PRO ula_pq_extract_test, event

    COMPILE_OPT STRICTARR

    ENVI_SELECT, title='Choose a file', fid=fid, pos=pos
    IF (fid EQ -1) THEN return
    ENVI_FILE_QUERY, fid, dims=dims, ns=ns, nl=nl, interleave=interleave, fname=fname
    map_info = envi_get_map_info(fid=fid)

    base = widget_auto_base(title='Select which quality measures to extract')

    list = ['Band 1 Saturation', $
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
            'Fmask Cloud Shadow', $
            'Topographic Shadow', $
            'Extra' $
            ]

     bits = [1,2,4,8,16,32,64,128, $
             256,512,1024,2048,4096, $
             8192,16384,32768 $
            ]

    ; Output as compressed or not
    ;c_list = ['File Compression: No', 'File Compression: Yes']
    c_list = ['File Compression']

    wm = widget_menu(base, list=list, uvalue='menu',rows=4, /auto)
    ;wc = widget_menu(base, uvalue='compressed', list=c_list, /auto)
    wo = widget_outf(base, uvalue='outf', /auto)
    wc = widget_menu(base, uvalue='compressed', list=c_list, /auto)
    result = auto_wid_mng(base)

    IF (result.accept EQ 0) THEN return

    ;selected = result.menu
    selected = where(result.menu EQ 1)

    nb = n_elements(selected)
    bnames = list[selected]
    description = 'ULA pixel quality bit mask extraction'

    outfname = result.outf

    ;Display the Percent Complete Window
    ostr = 'Output File: ' + outfname
    rstr = ["Input File :" + fname, ostr]
    envi_report_init, rstr, title="Processing Bit Extraction", base=base

    IF (result.compressed EQ 0) THEN BEGIN
        openw, lun, outfname, /get_lun
    ENDIF ELSE BEGIN
        openw, lun, outfname, /get_lun, /compress
        compression = 1
    ENDELSE

    ;openw, lun, outfname, /get_lun

    FOR i=0, n_elements(selected)-1 DO BEGIN

        tile_id = envi_init_tile(fid, pos, num_tiles=num_tiles, $
                  interleave=0, xs=dims[1], xe=dims[2], $
                  ys=dims[3], ye=dims[4])
        FOR t=0L, num_tiles-1 DO BEGIN
            envi_report_stat, base, t, num_tiles
            data = envi_get_tile(tile_id, t)
            ext  = (data AND bits[selected[i]]) EQ bits[selected[i]]
            writeu, lun, ext
        ENDFOR

        ;Close the tiling procedure and the Percent Complete window
        envi_tile_done, tile_id
        envi_report_init, base=base, /finish

    ENDFOR

    free_lun, lun

    ;Create the header file
    envi_setup_head, fname=outfname, ns=ns, nl=nl, nb=nb, bnames=bnames, $
                   data_type=1, offset=0, interleave=interleave, map_info=map_info, $
                   descrip=description, r_fid=h_fid, /write, /open

    IF (result.compressed EQ 1) THEN BEGIN
        envi_assign_header_value, fid=h_fid, keyword='file compression', $
                                  value=compression
        values = envi_get_header_value(h_fid, 'file compression', /byte)
        envi_write_file_header, h_fid
        envi_file_mng, id=h_fid, /remove
        envi_open_file, outfname, r_fid=fid
    ENDIF

END



