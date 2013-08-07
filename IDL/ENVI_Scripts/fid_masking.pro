;+
; Name:
; -----
;     FID_MASKING
;-
;
;+
; Description:
; ------------
;     Rasterizes an ENVI vector using the FID attribute to populate
;     the pixels, eg FID of 112 populated pixels with the value 112.
;     A fill value of -999 is used.
;     The output raster will be a 16bit signed integer.
;-
;
;+
; Output options:
; ---------------
;
;     Outputs the resulting image to disk.
;-
;
;+
; Requires:
; ---------
;     This function is written for use only with an interactive ENVI session.
;     The input vector file must be an ENVI format, ie *.evf.
;     The EVF file must have the same projection/reference frame as the base image.
;     
;-
;
;+ 
; Parameters:
; -----------
; 
;     Base : input::
;     
;          The base image to be used for setting up the FID image.
;          
;     EVF : input::
;     
;          The ENVI vector file that is to be converted to raster.
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
;     2011/11/15: Created
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


;Create a mask from a shapefile using the FID attribute to fill
;the pixels, eg FID of 112 has the value 112 instead of 1
;which is normally the case.  Also, can't use a fill value of zero as FID 0
;is considered valid.  The fill value instead will be -999 (Might use 255 to keep
;the image as a smallish size of type byte).
;The shapefiles will need to be the same projection as the image, and in an 'evf'
;(ENVI vector file) format.
;This will be set up to work as a GUI.

;Adding an extra button to the ENVI Menu bar
PRO fid_masking_define_buttons, buttonInfo
;+
; :Hidden:
;-

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Vector to Raster Pop. by FID', $
   EVENT_PRO = 'fid_masking', $
   REF_VALUE = 'General Tools', POSITION = 'last', UVALUE = ''

END

PRO fid_masking_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'fid_masking.html'
    ONLINE_HELP, book=book
    
END

;The actual code for creating mask
PRO fid_masking, event
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

    ; Select the image to be used as a base for setting up
    ; the shapefile FID mask
    ENVI_SELECT, fid=fid, pos=pos, title='Select Base Image'
    IF (fid EQ -1) THEN RETURN

    ; Select the evf file to be used for rasterising
    evf = ENVI_PICKFILE(title='Pick an evf file', filter='*.evf')
    IF (evf EQ '') THEN RETURN

    ; Specify the output name
    base = WIDGET_AUTO_BASE(title='Choose Ouput File Name')

    wo = WIDGET_OUTF(base, uvalue='outf', /AUTO)
    wb  = WIDGET_BUTTON(base, value='Help', event_pro='fid_masking_button_help', /ALIGN_CENTER, /HELP)

    result = AUTO_WID_MNG(base)
    mask_out_name = result.outf

    IF (result.accept EQ 0) THEN RETURN
    IF (result.accept EQ 1) THEN BEGIN

        ; Retrieve image info
        ENVI_FILE_QUERY, fid, dims=dims, fname=fname, ns=ns, nl=nl, nb=nb
        map_info = ENVI_GET_MAP_INFO(fid=fid)

        ; Open the evf file
        Mask_evf_id = ENVI_EVF_OPEN(evf)

        ; get info of the evf that will be used as a mask
        ENVI_EVF_INFO, Mask_evf_id, num_recs=Mask_num_recs, $
            data_type=Mask_data_type, projection=Mask_projection, $
            layer_name=Mask_layer_name

        ; Display the Percent Complete Window
        ostr = 'Output File: ' + mask_out_name
        rstr = ['Base Image File: ' + fname, ostr]
        rstrvec = ['Input Vector File: ' + mask_layer_name, rstr]
        ENVI_REPORT_INIT, rstrvec, title="Pop. FID, Vector To Raster", base=base, $
	          /INTERRUPT

        ; Create the array to hold the mask
        ; At this point in time, the array is only going to be of type byte
        ; with a fill value of 255. This limits the number of records in a
        ; vector file to 255. This can be changed later.
        mask = MAKE_ARRAY(ns, nl, /INTEGER, value = -999)

        ; Percent increments
        ENVI_REPORT_INC, base, Mask_num_recs

        ; Extract the number of vertices from a record into a variable.
        FOR i=0L,Mask_num_recs-1 DO BEGIN
            ENVI_REPORT_STAT, base, i, Mask_num_recs
            Mask_record = ENVI_EVF_READ_RECORD(Mask_evf_id, i)

            ; convert the map coordinates to image coordinates
            ENVI_CONVERT_FILE_COORDINATES, fid, Mask_xf, Mask_yf, $
            Mask_record[0,*], Mask_record[1,*]

            ; create the base roi from the image dimensions
            Mask_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
                color=4, name='Mask_evfs', /NO_UPDATE)

            ; change the array dimensions of the co-ordinates
            Mask_xpts = REFORM(Mask_xf)
            Mask_ypts = REFORM(Mask_yf)

            ; create the roi, these won't be saved
            ENVI_DEFINE_ROI, Mask_roi_id, /POLYGON, xpts=Mask_xpts, ypts=Mask_ypts

            ;Mask_roi_ids = envi_get_roi_ids(fid=fid)

            ; create the mask, i.e. populate the array
            addr = ENVI_GET_ROI(Mask_roi_id[0])
           
            ; Populate the mask with the value of fid (shapefile).  Essentially the fid
            ; (shapefile) starts at zero so no need to select the attribute
            mask[addr] = i

            ENVI_DELETE_ROIS, Mask_roi_id

        ENDFOR

        ; Close the evf file
        ENVI_EVF_CLOSE, Mask_evf_id

        ; write the mask to file
        ENVI_WRITE_ENVI_FILE, mask, BNAMES='mask', DATA_TYPE=2, MAP_INFO=map_info, $
            R_FID=r_fid, OUT_NAME=mask_out_name

        ; Close the  Percent Complete window
        ENVI_REPORT_INIT, base=base, /FINISH

    ENDIF
END
