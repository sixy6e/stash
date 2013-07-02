pro pixel_temporal_stats_test, event

envi_batch_init, log_file='batch.txt'

ENVI_SELECT, title='choose a file', fid=fid, pos=pos
   IF (fid eq -1) THEN return
ENVI_FILE_QUERY, fid, dims=dims, nb=nb, ns=ns, nl=nl
print, pos
print, 'size'
print, SIZE(pos)
pos  = lindgen(nb)
out_dt = 4

base = widget_auto_base(title='Select which stats to compute')
list = ['Sum', 'Sum Squared', 'Mean', 'Standard Deviation',$
     'Variance', 'Skewness', 'Kurtosis', 'Mean Absolute Deviation']
wm = widget_menu(base, list=list, uvalue='stats',rows=3, /auto)
wo = widget_outf(base, uvalue='outf', /auto)
result = auto_wid_mng(base)
   if (result.accept eq 0) then return
   print, 'Sum', result.stats[0]
   print, 'Sum Squared', result.stats[1]
   print, 'Mean', result.stats[2]
   print, 'StDev', result.stats[3]
   print, 'Var', result.stats[4]
   print, 'skew', result.stats[5]
   print, 'kur', result.stats[6]
   print, 'mad', result.stats[7]
compute_flag =[result.stats[0], result.stats[1], result.stats[2], $
      result.stats[3], result.stats[4], result.stats[5], result.stats[6], $
      result.stats[7]]
print, compute_flag
print, SIZE(pos)
print, SIZE(pos, /N_ELEMENTS)
print, SIZE(pos, /N_DIMENSIONS)
print, SIZE(pos, /DIMENSIONS)
print, SIZE(pos, /FILE_LUN)

bnames=['Sum', 'Sum Squared', 'Mean', 'Standard Deviation', 'Variance', $
    'Skewness', 'Kurtosis', 'Mean Absolute Deviation']

envi_doit, 'envi_sum_data_doit', $  
    fid=fid, pos=pos, dims=dims, $
    out_bname=bnames, $  
    out_name=result.outf, out_dt=out_dt, $  
    compute_flag=compute_flag

end