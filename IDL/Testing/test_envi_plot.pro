pro test_envi_plot

x = findgen(100)

y = reform([x, sin(x)], 100, 2) 

plot_names = ['XY Line', 'SIN(X)'] 

envi_plot_data, x, y, plot_names=plot_names, base=base
sp_import, base, [35,35], !Y.CRange, plot_color=[0,255,0]

end