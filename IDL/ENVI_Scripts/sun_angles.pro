;+
; Name:
; -----
;     SUN_ANGLES
;-
;
;+
; Description:
; ------------
;     The solar position for a given date/time/location is calculated.
;     Solar angles reported are the Elevation and Azimuth.
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
;     
;-
;
;+ 
; Parameters:
; -----------
; 
;     Day : input::
;     
;          The calendar day. Acceptable values are 1 through 31.
;          
;     Month : input::
;     
;          The calendar month. Acceptable values are 1 through 12.
;          
;     Year : input::
;     
;          The calendar year. Year input is given as YYYY, eg 2009.
;          
;     Time (GMT) : input::
;     
;          Greenwich Mean Time. Acceptable values are 0 through 2400, eg 14:30 is 1430.
;     
;     Lattitude : input::
;     
;          Lattitude in decimal degrees, eg -33.56378.
;          
;     Longitude : input::
;     
;          Longitude in decimal degrees, eg 154.73746.
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
;     2009/04/10: Created
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

PRO sun_angles_define_buttons, buttonInfo
;+
; :Hidden:
;-

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Sun Angle Calculator', $
   EVENT_PRO = 'sun_angles', $
   REF_VALUE = 'General Tools', POSITION = 'last', UVALUE = ''

END

PRO sun_angles_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'sun_angles.html'
    ONLINE_HELP, book=book
    
END

PRO sun_angles, event
;+
; :Hidden:
;-

    ; calculates the sun elevation and sun azimuth

    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    TLB = WIDGET_AUTO_BASE(title='Compute Sun Angles', /XBIG)

    ; day, a value of 1 through 31
    p1 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=2, $
        prompt='Day: 1 through 31', uvalue='p1', xsize=35)

    ; month, a value of 1 through 12
    p2 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=2, $
        prompt='Month: 1 through 12', uvalue='p2', xsize=35)

    ; year, in yyyy format
    p3 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=2, $
        prompt='Year (eg 2013)', uvalue='p3', xsize=35)

    ; Greenwich Mean Time, a value 0 through 2400, eg 14:30 is 1430
    p4 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=4, field=9, $
        prompt='GMT Time (0 through 2400, eg 14:30 is 1430)', uvalue='p4', xsize=35)

    ; Lattitude, Enter in Decimal Degrees
    p5 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=4, field=9, $
        prompt='Lattitude (DD, eg -33.56378)', uvalue='p5', xsize=35)

    ; Longitude, Enter in Decimal Degrees
    p6 = WIDGET_PARAM(tlb, /AUTO_MANAGE, dt=4, field=9, $
        prompt='Longitude (DD, eg 154.73746)', uvalue='p6', xsize=35)
   
    wb  = WIDGET_BUTTON(tlb, value='Help', event_pro='sun_angles_button_help', /ALIGN_CENTER, /HELP)

    result = AUTO_WID_MNG(TLB)

    IF (result.accept EQ 0) THEN RETURN

    IF (result.accept EQ 1) THEN BEGIN

        angles = ENVI_COMPUTE_SUN_ANGLES(result.p1, result.p2, result.p3, $
            result.p4, result.p5, result.p6)
              
        elevation = STRTRIM(angles[0], 1)
        azimuth = STRTRIM(angles[1], 1)  
        str = ['Sun Elevation= ' + elevation, 'Sun Azimuth= ' + azimuth]         
        ENVI_INFO_WID, str, Title = 'Sun Angles'
        sun_angles,
    ENDIF

END
