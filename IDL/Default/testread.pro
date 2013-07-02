pro testread

;OPENR, lun, 'D:\Data\Imagery\Testing\LT50920842009015ASA00\L5092084_08420090115_MTL.txt', /GET_LUN
OPENR, lun, 'D:\Data\TESTING\Flux\TOA5_2436.flux_2010_11_29_0000.dat', /GET_LUN
;Read one line at a time, saving the result into array
array = ''
line = ''
    WHILE NOT EOF(lun) DO BEGIN 
      READF, lun, line 
      array = [array, line]  
    ENDWHILE

; Close the file and free the file unit
FREE_LUN, lun

end