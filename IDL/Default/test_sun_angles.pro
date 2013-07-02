PRO test_sun_angles, event

compile_opt IDL2

TLB = WIDGET_AUTO_BASE(title='Compute Sun Angles')

p1 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Day', uvalue='p1')

p2 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Month', uvalue='p2')

p3 = WIDGET_PARAM(tlb, /auto_manage, dt=2, $

   prompt='Year', uvalue='p3')

p4 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='GMT Time', uvalue='p4')

p5 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='Lattitude (DD)', uvalue='p5')

p6 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=9, $

   prompt='Longitude (DD)', uvalue='p6')

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
