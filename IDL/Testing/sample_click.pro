PRO SAMPLE_CLICK,Q
;+
;SAMPLE_CLICK,Q uses the mouse cursor to show values of an array Q that
;has been displayed in a window. Left click in the image to print the
;coordinates and the value. Right-click to end the procedure. It is assumed
;that the window is sized to fit the array image.
;-
dims = SIZE(q, /DIMENSIONS)
elements = N_ELEMENTS(dims)
!mouse.button=1
WHILE(!MOUSE.BUTTON NE 4) DO BEGIN
	CURSOR, X, Y, /DEVICE, /DOWN
	IF !MOUSE.BUTTON EQ 1 THEN $
            IF elements EQ 2 THEN BEGIN
            PRINT, FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)', $
                  X,dims[1]-Y, Q[X,dims[1]-Y] 
            ENDIF ELSE IF dims[0] EQ 3 THEN BEGIN
                ; BIP: [bands,samples,lines]
                PRINT, FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)', $ 
                  X,dims[2]-Y, Q[*,X,dims[2]-Y]
               ; print, X, Y, Q[*,X,Y]
            ENDIF ELSE IF dims[1] EQ 3 THEN BEGIN
                ; BIL: [samples,bands,lines]
                PRINT, FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)', $
                  X,dims[2]-Y, Q[X,*,dims[2]-Y]
               ; print, X, Y, Q[X,*,Y]
            ENDIF ELSE BEGIN 
                ; BSQ: [samples,lines,bands]
                PRINT, FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)', $
                  X,dims[1]-Y, Q[X,dims[1]-Y,*]
               ; print, X, Y, Q[X,Y,*]
            ;endif ELSE begin
                ; Single band image
             ;   PRINT, FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)',+ $
             ;     X,dims[1]-Y, Q[X,dims[1]-Y]
                ;print, X, Y, Q[X,Y]
            ENDELSE
        ;PRINT,FORMAT='("POSITION=[",I3,",",I3,"], VALUE=",I3)', X, Y, Q[X,Y]
        ;print, X, Y, Q[X,Y,*]
        ;print, X, Y
ENDWHILE
END

