PRO maximum_entropy_threshold_mask_testing_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Maximum_Entropy', $
   EVENT_PRO = 'maximum_entropy_threshold_mask_testing', $
   REF_VALUE = 'Thresholding', POSITION = 'last', UVALUE = ''

END

PRO maximum_entropy_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()
    
    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'maximum_entropy_threshold_mask.html' 
    ONLINE_HELP, book=book
    
END

PRO maximum_entropy_threshold_mask_testing, event
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

END