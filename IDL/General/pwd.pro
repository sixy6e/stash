PRO pwd, Help=help
if keyword_set(help) then begin
    print, 'procedure PWD, Help=help'
    print, 'prints the current working directory'
    
endif else begin
    CD, Current=c
    Print, c
endelse
END
