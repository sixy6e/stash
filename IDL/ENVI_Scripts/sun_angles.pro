;Adding an extra button to the ENVI Menu bar
PRO sun_angles_define_buttons, buttonInfo

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Sun Angle Calculator', $
   EVENT_PRO = 'sun_angles', $
   REF_VALUE = 'GA Tools', POSITION = 'last', UVALUE = ''

END


PRO sun_angles, event

;calculates the sun elevation and sun azimuth

COMPILE_OPT STRICTARR
compile_opt IDL2

TLB = WIDGET_AUTO_BASE(title='Compute Sun Angles', /XBIG)

;day, a value of 1 through 31
p1 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Day: 1 through 31', uvalue='p1', xsize=35)

;month, a value of 1 through 12
p2 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Month: 1 through 12', uvalue='p2', xsize=35)

;year, in yyyy format
p3 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Year (eg 2013)', uvalue='p3', xsize=35)

;Greenwich Mean Time, a value 0 through 2400, eg 14:30 is 1430
p4 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='GMT Time (0 through 2400, eg 14:30 is 1430)', uvalue='p4', xsize=35)

;Lattitude, Enter in Decimal Degrees
p5 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='Lattitude (DD, eg -33.56378)', uvalue='p5', xsize=35)

;Longitude, Enter in Decimal Degrees
p6 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='Longitude (DD, eg 154.73746)', uvalue='p6', xsize=35)

result=AUTO_WID_MNG(TLB)

IF (result.accept eq 0) THEN return

IF (result.accept eq 1) THEN $

   angles = envi_compute_sun_angles(result.p1, result.p2, result.p3, $
              result.p4, result.p5, result.p6)
              
   elevation = strtrim(angles[0], 1)
   azimuth = strtrim(angles[1], 1)  
   str = ['Sun Elevation= ' + elevation, 'Sun Azimuth= ' + azimuth]         
   envi_info_wid, str, Title = 'Sun Angles'

  
END
