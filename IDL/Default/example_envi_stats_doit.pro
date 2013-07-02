PRO EXAMPLE_ENVI_STATS_DOIT

compile_opt IDL2 

; 

; First restore all the base save files. 

; 

envi, /restore_base_save_files 

; 

; Initialize ENVI and send all errors 

; and warnings to the file batch.txt 

; 

envi_batch_init, log_file='batch.txt' 

; 

; Open the input file 

; 

ENVI_SELECT, title='Choose a file', fid=fid, pos=pos
    IF (fid EQ -1) THEN return 

; 

; Get the dimensions and # bands 

; for the input file. 

; 

envi_file_query, fid, dims=dims, nb=nb 

; 

; Set the POS keyword to calculate 

; statistics for all data (spectrally) in the file. 

; 

pos = lindgen(nb) 

; 

; Calculate the basic statistics and the 

; histogram for the input data file. Print 

; out the calculated information. 

; 

envi_doit, 'envi_stats_doit', fid=fid, pos=pos, $ 

   dims=dims, comp_flag=1, dmin=dmin, dmax=dmax, $ 

   mean=mean, stdv=stdv 

; 

print, 'Minimum ', dmin 

print, 'Maximum ', dmax 

print, 'Mean ', mean 

print, 'Standard Deviation ', stdv 

; 

;for i=0,nb-1 do begin 

;   print, 'Histogram Band ', i+1 

;   print, hist[*,i] 

;endfor 

; 

; Exit ENVI 

; 

envi_batch_exit 

END
