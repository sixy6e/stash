function test_change_interleave, image, interleave=interleave, BIP=bip, BIL=bil, BSQ=bsq

    on_error, 2

    if n_elements(size(image, /dimensions)) ne 3 then message, 'Image Must Be 3 Dimensional.'
    if n_elements(interleave) ne 1 then message, 'Interleave is not set.'
    if ((interleave lt 0) or (interleave gt 2)) then message, 'Interleave Must Be 0,1 Or 2.'
    msg = 'Output Interleave Same As Input'

    ; Convert the image to bip interleaving
    if (keyword_set(bip)) then begin
        if (keyword_set(bil)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif
        if (keyword_set(bsq)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif

        case interleave of
            0: begin
               message, /informational, msg
               return, image
               break
               end
            1: return, transpose(image, [1,0,2])
            2: return, transpose(image, [2,0,1])
        endcase

    endif

    ; Convert the image to bil interleaving
    if (keyword_set(bil)) then begin
        if (keyword_set(bsq)) then begin
            message, 'Can Only Change To One Interleave Format, Not Two.'
        endif

        case interleave of
            0: return, transpose(image, [1,0,2])
            1: begin
               message, /informational, msg
               return, image
               break
               end
            2: return, transpose(image, [0,2,1])
        endcase

    endif

    ; Convert the image to bsq interleaving
    if (keyword_set(bsq)) then begin
        case interleave of
            0: return, transpose(image, [1,2,0])
            1: return, transpose(image, [0,2,1])
            2: begin
               message, /informational, msg
               return, image
               break
               end
        endcase

    endif

end