function testreadF, filename, skip

;OPENR, lun, 'D:\Data\Imagery\Testing\LT50920842009015ASA00\L5092084_08420090115_MTL.txt', /GET_LUN
;OPENR, lun, 'D:\Data\TESTING\Flux\TOA5_2436.flux_2010_11_29_0000.dat', /GET_LUN

openr, lun, filename, /get_lun

array = ''
line = ''

;skip the header info
if keyword_set(skip) then begin
skip_lun, lun, skip, /lines
    WHILE NOT EOF(lun) DO BEGIN 
      READF, lun, line 
      array = [array, line]  
    ENDWHILE
    return, array
endif else begin
;Read one line at a time, saving the result into array
;array = ''
;line = ''
    WHILE NOT EOF(lun) DO BEGIN 
      READF, lun, line 
      array = [array, line]  
    ENDWHILE
;might need to add something here to remove the fist line of the new array
;which is just a blank string. could use a = array[1:*], which removes array[0]
;or return array[1:*]
; Close the file and free the file unit
FREE_LUN, lun
return, array
endelse
end