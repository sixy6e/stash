;+
; Name:
; -----
;     
;-
;
;+
; Description:
; ------------
;     Flattens an array, i.e. reshapes the array so that it is 1 dimensional.
;-
;
;+ 
; Parameters:
; -----------
; 
;     array : input::
;
;           An array of any size and datatype.
;-
;
;+
; Returns:
; --------
;     A 1 dimensional array
;-
;
;+
; Example:
; --------
;     arr = randomu(sd, 100,100,10)
;     flat_arr = flatten(arr)
;-
;
;+
; :History:
; 
;     2013/11/05: Created
;-

FUNCTION flatten, array

    flat_arr = REFORM(array, N_ELEMENTS(array))
    RETURN, flat_arr

END
