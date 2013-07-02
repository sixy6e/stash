PRO _ga_tools_define_buttons, buttonInfo

    ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'GA Tools', $
        /MENU, REF_VALUE = 'Help', /SIBLING, POSITION = 'after'
    ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE= 'Thresholding', $
        /MENU, REF_VALUE = 'GA Tools', POSITION = 'last'
        
END

PRO _ga_tools

    COMPILE_OPT IDL2
    COMPILE_OPT STRICTARR

END
