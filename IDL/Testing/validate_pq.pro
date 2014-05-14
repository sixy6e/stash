PRO validate_pq_define_buttons, buttonInfo
;+
; :Hidden:
;-
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'PQ', $
   EVENT_PRO = 'validate_pq', $
   REF_VALUE = 'Validation', POSITION = 'last', UVALUE = ''

END

PRO valPQ_button_help, ev
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    e_pth   = ENVI_GET_PATH()
    pth_sep = PATH_SEP()

    book = e_pth + pth_sep + 'save_add' + pth_sep + 'html' + pth_sep + 'validate_pq.html'
    ONLINE_HELP, book=book

END

PRO validate_pq, event
;+
; :Hidden:
;-
    COMPILE_OPT STRICTARR
    COMPILE_OPT IDL2

    CATCH, error
    IF (error NE 0) THEN BEGIN
        ok = DIALOG_MESSAGE(!error_state.msg, /CANCEL)
        IF (STRUPCASE(ok) EQ 'CANCEL') THEN RETURN
    ENDIF

END
