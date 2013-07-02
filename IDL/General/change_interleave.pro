; This function changes an images interleave.
; Specify the image, current interleave (0,1, or 2) and the desired interleave.
; Keywords:
;         BIP: Change to bip
;         BIL: Change to bil
;         BSQ: Chnage to bsq
; eg a 3 by 4 image with 5 bands (bsq interleaved)
; img = fltarr(3,4,5)
; bip = change_interleave(img, interleave=2, /bip) OLD!!!!!!!!!
; bil = change_interleave(img, interleave=2, /bil) OLD!!!!!!!!!
;
; Probably need to change interleave codes to match ENVI. FIXED!!!!!!
; Previous interleave codes were 0, 1, 2 = BIP, BIL, BSQ
; ENVI uses 0, 1, 2 = BSQ, BIL, BIP
; NEW!!!
; bip change_interleave(img, interleave=0, /bip)
; bil = change_interleave(img, interleave=0, /bil) 

function change_interleave, image, interleave=interleave, BIP=bip, BIL=bil, BSQ=bsq, Help=help

    on_error, 2

    if keyword_set(help) then begin
        print, 'function CHANGE_INTERLEAVE, image, interleave=interleave'
        print, 'BIP=bip, BIL=bil, BSQ=bsq, Help=help'
        return, -1
    endif 

    if n_elements(size(image, /dimensions)) ne 3 then message, 'Image Must Be 3 Dimensional.'
    if n_elements(interleave) ne 1 then message, 'Interleave is not set.'
    if ((interleave lt 0) or (interleave gt 2)) then message, 'Interleave Must Be 0,1 Or 2.'
    msg = 'Output Interleave Same As Input'

    ; Convert the image to bsq interleaving
    if (keyword_set(bsq)) then begin
        if (keyword_set(bil)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif
        if (keyword_set(bip)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif

        case interleave of
            0: begin
               message, /informational, msg
               return, image
               break
               end
            1: return, transpose(image, [0,2,1])
            2: return, transpose(image, [1,2,0])
        endcase

    endif

    ; Convert the image to bil interleaving
    if (keyword_set(bil)) then begin
        if (keyword_set(bip)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif

        case interleave of
            0: return, transpose(image, [0,2,1])
            1: begin
               message, /informational, msg
               return, image
               break
               end
            2: return, transpose(image, [1,0,2])
        endcase

    endif

    ; Convert the image to bip interleaving
    if (keyword_set(bip)) then begin
        case interleave of
            0: return, transpose(image, [2,0,1])
            1: return, transpose(image, [1,0,2])
            2: begin
               message, /informational, msg
               return, image
               break
               end
        endcase

    endif

end
