PRO ls, Help=help
IF keyword_set(help) THEN BEGIN
    print, 'Procedure LS, Help=help'
    print, 'Lists the current working directory'
    
ENDIF ELSE BEGIN
    SPAWN, 'ls'
ENDELSE
END

