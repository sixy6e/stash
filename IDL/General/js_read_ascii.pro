function JS_Read_Ascii, filename, skip, Help=help

;This function will read an ascii file line by line and store each line on a separate row.
;Will produce a column vector (1 column by n rows)
;The skip keyword is if you want to skip header info, just specify the number of
;lines that you want to skip.  If not entered it will just read every line.
;Author: Josh Sixsmith

if keyword_set(help) then begin
    print, 'function JS_READ_ASCII filename, skip, Help=help'
    print, 'variable SKIP is how many lines in the file to skip'
    return, -1
endif

;Open the file for reading, and get a LUN
openr, lun, filename, /get_lun

;Define the properties of the variables (both set as strings)
array = ''
line = ''

;Skipping the header info
  if keyword_set(skip) then begin
  skip_lun, lun, skip, /lines
      WHILE NOT EOF(lun) DO BEGIN 
        READF, lun, line 
        array = [array, line]  
      ENDWHILE
      return, array[1:*]
  endif else begin

;Or read the whole file, line by line.
    WHILE NOT EOF(lun) DO BEGIN 
      READF, lun, line 
      array = [array, line]  
    ENDWHILE

; Close the file and free the file unit
  FREE_LUN, lun
;Only array[1:*] is returned as array[0] is an empty string as defined by
;the setup of array = ''. 
  return, array[1:*]
  endelse
end
