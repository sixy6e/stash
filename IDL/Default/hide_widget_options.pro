pro button_help, ev
online_help, book='C:\Users\u08087\Links\html2\index.html'
end

pro hide_widget_options, ev

    base = WIDGET_AUTO_BASE(title='Histogram Parameters')
    row_base1 = WIDGET_BASE(base, /row)
    p1 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Min', uvalue='p1', xsize=10, default=data_mn)
    p2 = WIDGET_PARAM(row_base1, auto_manage=0, dt=4, $  
      prompt='Max', uvalue='p2', xsize=10, default=data_mx)
    p3 = WIDGET_PARAM(row_base1, auto_manage=0, default=1, $  
      prompt='Binsize', uvalue='p3', xsize=10)
    p4 = WIDGET_PARAM(row_base1, auto_manage=0, default=256, $  
      prompt='Nbins', uvalue='p4', xsize=10, dt=12)
      
    p5 = widget_menu(base, list=['Binsize', 'Nbins'], uvalue='bnsz_nbin', /exclusive, /auto)
    
    p_list = ['Plot Threshold?']
    i_list = ['Invert Mask?']
    s_list = ['Segment Binary Mask?']
    
    wm = WIDGET_MENU(base, list=p_list, uvalue='plot', rows=1, auto_manage=0)
    wm2 = WIDGET_MENU(base, list=i_list, uvalue='invert', rows=1, auto_manage=0)
    wm3 = WIDGET_MENU(base, list=s_list, uvalue='segment', rows=1, auto_manage=0)
    wo = WIDGET_OUTFM(base, uvalue='outfm', prompt='Mask Output', /auto)
    wo2 = WIDGET_OUTF(base, uvalue='outf', prompt='Mask Segmentation Output', auto_manage=0)
    wb = WIDGET_BUTTON(base, value='Help', event_pro='button_help', /align_center, /help)
    
    result = AUTO_WID_MNG(base)
    
    IF (result.accept EQ 0) THEN RETURN
    
    help, result, /structure
    print, result.bnsz_nbin
    
    Str = strarr(7)
    Str[0] = string(format='(%"Min = %0.2f")', result.p1)
    Str[1] = string(format='(%"Max = %0.2f")', result.p2)
    bnsz = result.p3
    nbin = result.p4
    nbin_str = STRING(format='(%"Nbins = %i")', nbin)
    bnsz_str = STRING(format='(%"Binsize = %f")', bnsz)
    bnsz_nbin = (result.bnsz_nbin eq 0) ? bnsz_str : nbin_str
    Str[2] = bnsz_nbin
    Str[3] = string(format='(%"Plot? %i")', result.plot)
    Str[4] = string(format='(%"Invert? %i")', result.invert)
    Str[5] = string(format='(%"Segment? %i")', result.segment)
    Str[6] = string(format='(%"Memory? %i")', result.outfm.in_memory)
    
    ENVI_INFO_WID, Str, TITLE='Parameters Chosen'
    


end