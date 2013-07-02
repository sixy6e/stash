PRO test_widgets2, event

compile_opt IDL2

TLB = WIDGET_AUTO_BASE(title='widget test')

p1 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=2, $

   prompt='enter the first parameter', uvalue='p1')

p2 = WIDGET_PARAM(tlb, /auto_manage, dt=4, field=2, $

   prompt='enter the second parameter', uvalue='p2')

operation = WIDGET_TOGGLE(tlb, /auto_manage, default=0, $

   list=['add', 'multiply'], prompt='operation', $

   uvalue='operation')

result=AUTO_WID_MNG(TLB)

IF (result.accept eq 0) THEN return

IF (result.operation eq 0) THEN $

   ENVI_INFO_WID, STRTRIM(result.p1 + result.p2) ELSE $

   ENVI_INFO_WID, STRTRIM(result.p1 * result.p2)

   ;test_widgets2, event

END
