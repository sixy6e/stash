;+
; Name:
; -----
;     ULA_PQ_EXTRACT
;-
;
;+
; Description:
; ------------
;     Pixel quality information contained within a Geoscience Australia 
;     pixel quality product are extracted into seperate bands.
;     Quality features that can be extracted are Saturation, Spectral Contiguity, 
;     Land/Sea, Cloud, Cloud Shadow.
;-
;
;+
; Output options:
; ---------------
;
;     The output file can be compressed.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;     
;-
;
;+ 
; Parameters:
; -----------
; 
;     PQ : input::
;     
;          The pixel quality product generated by Geoscience Australia.
;          
;     Band 1 Saturation : select, optional::
;     
;          Extract the band 1 saturation mask.
;          
;     Band 2 Saturation : select, optional::
;     
;          Extract the band 2 saturation mask.
;          
;     Band 3 Saturation : select, optional::
;     
;          Extract the band 3 saturation mask.
;     
;     Band 4 Saturation : select, optional::
;     
;          Extract the band 4 saturation mask.
;          
;     Band 5 Saturation : select, optional::
;     
;          Extract the band 5 saturation mask.
;          
;     Band 61 Saturation : select, optional::
;     
;          Extract the band 61 saturation mask.
;          
;     Band 62 Saturation : select, optional::
;     
;          Extract the band 62 saturation mask.
;          For Landsat 5 TM, this is a duplicated result for band 6.
;          
;     Band 7 Saturation : select, optional::
;     
;          Extract the band 7 saturation mask.
;          
;     Land/Sea : select, optional::
;     
;          Extract the land/sea discrimination mask.
;          
;     ACCA : select, optional::
;     
;          Extract the cloud mask determined by the ACCA algorithm.
;          
;     Fmask : select, optional::
;     
;          Extract the cloud mask determined by the Fmask algorithm.
;          
;     ACCA Cloud Shadow : select, optional::
;     
;          Extract the cloud shadow mask generated from the cloud detected by the ACCA algorithm.
;          
;     Fmask Cloud Shadow : select, optional::
;     
;          Extract the cloud shadow mask generated from the cloud detected by the Fmask algorithm.
;          
;     File Compression : select, optional::
;     
;          Specifes whether the output file should be compressed.
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
;     2012/06/01: Created
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

PRO ula_pq_extract_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Extract PQ Bit Masks', $
   EVENT_PRO = 'ula_pq_extract', $
   REF_VALUE = 'General Tools', POSITION = 'last', UVALUE = ''
END

PRO ula_pq_extract_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'ula_pq_extract.html'
    ONLINE_HELP, book=book
    
END

PRO ula_pq_extract, event
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
    

    ENVI_SELECT, title='Choose a PQ file', fid=fid, pos=pos
    IF (fid EQ -1) THEN RETURN
    ENVI_FILE_QUERY, fid, dims=dims, ns=ns, nl=nl, interleave=interleave, fname=fname
    map_info = ENVI_GET_MAP_INFO(fid=fid)

    base = WIDGET_AUTO_BASE(title='Select which quality measures to extract')

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
            'Fmask Cloud Shadow' $
            ]

     bits = [1,2,4,8,16,32,64,128, $
             256,512,1024,2048,4096, $
             8192 $
            ]

    ; Output as compressed or not
    c_list = ['File Compression']

    wm = WIDGET_MENU(base, list=list, uvalue='menu',rows=4, /AUTO)
    wo = WIDGET_OUTF(base, uvalue='outf', /auto)
    wc = WIDGET_MENU(base, uvalue='compressed', list=c_list, /AUTO)
    wb  = WIDGET_BUTTON(base, value='Help', event_pro='ula_pq_extract_button_help', /ALIGN_CENTER, /HELP)
    result = AUTO_WID_MNG(base)

    IF (result.accept EQ 0) THEN RETURN

    ;selected = result.menu
    selected = WHERE(result.menu EQ 1)

    nb = N_ELEMENTS(selected)
    bnames = list[selected]
    description = 'ULA pixel quality bit mask extraction'

    outfname = result.outf

    ;Display the Percent Complete Window
    ostr = 'Output File: ' + outfname
    rstr = ["Input File :" + fname, ostr]

    IF (result.compressed EQ 0) THEN BEGIN
        OPENW, lun, outfname, /GET_LUN
    ENDIF ELSE BEGIN
        OPENW, lun, outfname, /GET_LUN, /COMPRESS
        compression = 1
    ENDELSE

    FOR i=0, N_ELEMENTS(selected)-1 DO BEGIN

        ENVI_REPORT_INIT, rstr, title="Processing Bit Extraction", base=base

        tile_id = ENVI_INIT_TILE(fid, pos, num_tiles=num_tiles, $
                  interleave=0, xs=dims[1], xe=dims[2], $
                  ys=dims[3], ye=dims[4])
        FOR t=0L, num_tiles-1 DO BEGIN
            ENVI_REPORT_STAT, base, t, num_tiles
            data = ENVI_GET_TILE(tile_id, t)
            ext  = (data AND bits[selected[i]]) EQ bits[selected[i]]
            WRITEU, lun, ext
        ENDFOR

        ;Close the tiling procedure and the Percent Complete window
        ENVI_TILE_DONE, tile_id
        ENVI_REPORT_INIT, base=base, /FINISH

    ENDFOR

    FREE_LUN, lun

    ;Create the header file
    ENVI_SETUP_HEAD, fname=outfname, ns=ns, nl=nl, nb=nb, bnames=bnames, $
                   data_type=1, offset=0, interleave=interleave, map_info=map_info, $
                   descrip=description, r_fid=h_fid, /WRITE, /OPEN

    IF (result.compressed EQ 1) THEN BEGIN
        ENVI_ASSIGN_HEADER_VALUE, fid=h_fid, keyword='file compression', $
                                  value=compression
        values = ENVI_GET_HEADER_VALUE(h_fid, 'file compression', /BYTE)
        ENVI_WRITE_FILE_HEADER, h_fid
        ENVI_FILE_MNG, id=h_fid, /REMOVE
        ENVI_OPEN_FILE, outfname, r_fid=fid
    ENDIF


END



