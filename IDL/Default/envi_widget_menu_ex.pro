PRO ENVI_WIDGET_MENU_EX

compile_opt IDL2

base = widget_auto_base(title='Menu test')

list = ['Button 1', 'Button 2', 'Button 3', 'Button 4']

wm = widget_menu(base, list=list, uvalue='menu', /excl, /auto)

result = auto_wid_mng(base)

if (result.accept eq 0) then return

print, 'Menu Selected', result.menu

END

