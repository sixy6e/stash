function data_from_roi

;******************************************************************************
;
; Returns a one dimensional array of the data within an array specified by an
; roi. Will iterate through the number of image files, and their associated
; bands.  I haven't put in checks for whether the images and roi's have the
; same dimensions. The user just has to be certain that they're the same.

; The file type is a flat binary file (same as the envi format).

;
; Use: array = data_from_roi()

;******************************************************************************

; Get the current working directory
cd, current = c

; Create the filename
fname = c + '\data_file'

; Get the file id's of the images (assuming that the only ones you are dealing
; with are the only ones opened in the envi session
fids = envi_get_file_ids()
; Same for the region of interest. This also assumes that there is only one roi
roi_id = envi_get_roi_ids()

; Get the number of elements of the roi. Will be used for opening the file
; later on, as no file description (header file) will be created.
roi_size = n_elements(envi_get_roi(roi_id))

; Create a count.  This will be used to determine how many times the file has
; has been written to. Will be used for determining how big to create the array
; when reading in the file.  Datatype is assumed to be floating point.
count = 0

openw, lun, fname, /get_lun

for i = 0, n_elements(fids)-1 do begin
    envi_file_query, fids[i], nb=nbands
    pos = lindgen(nbands)
    count = count + n_elements(pos)
    if (n_elements(pos) gt 1) then begin
        for j = 0, n_elements(pos)-1 do begin
            writeu, lun, envi_get_roi_data(roi_id[0], fid=fids[i], pos=[j])
        endfor
    endif else begin
        writeu, lun, envi_get_roi_data(roi_id[0], fid=fids[i], pos=[0])
    endelse
endfor

; Free the allocation unit
free_lun, lun

; Read the file.
openr, lun, fname, /get_lun
array = fltarr(count*roi_size)
readu, lun, array

; Free the allocation unit
free_lun, lun

return, array

end



