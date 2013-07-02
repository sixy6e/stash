PRO ENVI_WIDGET_PARAM_EX

compile_opt IDL2

base = widget_auto_base(title='Parameter test')

we = widget_param(base, dt=4, field=3, floor=0., $

default=10., uvalue='param', /auto, xsize=20)

result = auto_wid_mng(base)

if (result.accept eq 0) then return

print, 'Parameter value = ', float(result.param)

END

