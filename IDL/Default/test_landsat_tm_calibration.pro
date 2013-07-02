pro test_landsat_tm_calibration
  compile_opt idl2
  
  
;This script should convert the tiff files to at sensor reflectance values
;At the moment the values don't appear to be the same as when doing
;the procedure using envi's gui.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cd, 'N:\'
;cd, 'D:\Data\Imagery'

envi_batch_init, log_file='batch.txt'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;the search method for finding files, only searching 
;Landsat 5TM files
files=FILE_SEARCH('Storage01','L5*mtl.txt',COUNT=numfiles)
;files=FILE_SEARCH('Testing','L5*mtl.txt',COUNT=numfiles)

counter = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;What satellite ? 0 = Landsat 7 ETM+, 1 = Landsat 5 TM
sat = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Calibration type ? 0 = Radiance, 1 = Reflectance
;The thermal band requires radiance in order 
;to convert to kelvin
rfl_cal_type = 1
therm_cal_type = 0

While(counter LT numfiles) DO BEGIN
  ENVI_OPEN_FILE, files[counter], r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

;as the mtl text file brings in two separate images (therm and rfl)
;get all the fid's and call fid at position 0 and position 2 for
;the thermal and reflectance files
fids = envi_get_file_ids()

ENVI_FILE_QUERY, fids[0], dims=Therm_dims, fname=Therm_fname, ns=Therm_ns, nl=Therm_nl, nb=Therm_nb
Therm_map_info = envi_get_map_info(fid=fids[0])

ENVI_FILE_QUERY, fids[2], dims=rfl_dims, fname=rfl_fname, ns=rfl_ns, nl=rfl_nl, nb=rfl_nb
rfl_map_info = envi_get_map_info(fid=fids[2])

;Therm_pos = lindgen(Therm_nb); works as a pos set up as well
Therm_pos = [0]
rfl_pos = lindgen(rfl_nb)

;Read the mtl text file, in order to retreive the sun elevation, capture date, path/row
OPENR, lun, files[counter], /GET_LUN

;Read one line at a time, saving the result into array
array = ''
line = ''
    WHILE NOT EOF(lun) DO BEGIN 
      READF, lun, line 
      array = [array, line]  
    ENDWHILE

; Close the file and free the file unit
FREE_LUN, lun

;Retreiving data from the mtl text file.  The script will be adapted 
;at a later date so that it will find the line, rather than specifying
;the line. (COMPLETED)
;Acquisition Date
;The following line of code finds the line and extracts the text
Trim_AcqDate = strtrim(array[where(strpos(array, "ACQUISITION_DATE")ne-1)], 2)
;Remove the blank spaces at the start and end
;Trim1 = strtrim(array[21], 2)
;Find the position of the equals sign
;Find1 = strpos(Trim1, '=', /REVERSE_SEARCH)
Find_AcqDate = strpos(Trim_AcqDate, '=', /REVERSE_SEARCH)
;Extract the date
;Acquisition_Date = strmid(Trim1, Find1 + 2)
Acquisition_Date = strmid(Trim_AcqDate, Find_AcqDate + 2)
;Change the dashes to an underscore
strput, Acquisition_Date, '_', 4 & strput, Acquisition_Date, '_',7

;Path
;The following line of code finds the line and extracts the text
Trim_Path = strtrim(array[where(strpos(array, "WRS_PATH")ne-1)], 2)
;Remove the blank spaces at the start and end
;Trim2 = strtrim(array[23], 2)
;Find the position of the equals sign
;Find2 = strpos(Trim2, '=', /REVERSE_SEARCH)
Find_Path = strpos(Trim_Path, '=', /REVERSE_SEARCH)
;Extract the Path
;Path = strmid(Trim2, Find2 + 2)
Path = strmid(Trim_Path, Find_Path + 2)

;Row
;The following line of code finds the line and extracts the text
Trim_Row = strtrim(array[where(strpos(array, "STARTING_ROW")ne-1)], 2)
;Remove the blank spaces at the start and end
;Trim3 = strtrim(array[24], 2)
;Find the position of the equals sign
;Find3 = strpos(Trim3, '=', /REVERSE_SEARCH)
Find_Row = strpos(Trim_Row, '=', /REVERSE_SEARCH)
;Extract the Path
;Row = strmid(Trim3, Find3 + 2)
Row = strmid(Trim_Row, Find_Row + 2)

;Combine the path and row with an underscore at the start
PathRow = '_' + Path + Row

;The directory name
dir_name = file_dirname(files[counter], /mark_directory)

;Combine the dir name,  Acquisition date and path row to give the file name
rfl_file_out_name = dir_name + Acquisition_Date + PathRow + '_rfl'
Therm_file_out_name = dir_name + Acquisition_Date + PathRow + '_Therm_rad'

;Year
Year = strmid(Acquisition_Date, 0, 4)

;Month
Month = strmid(strmid(Acquisition_Date, 4, /REVERSE_OFFSET), 0, 2)

;Day
Day = strmid(Acquisition_Date, 1, /REVERSE_OFFSET)

;Setting up the variable 'Date' that will be used in the TMCAL_DOIT procedure
;The format needs to be in [mm, dd, yyyy]
Date = fix([Month, Day, Year])

;Sun elevation angle
;The following line of code finds the line and extracts the text
Trim_elev = strtrim(array[where(strpos(array, "SUN_ELEVATION")ne-1)], 2)
;Remove the blank spaces at the start and end
;Trim4 = strtrim(array[100], 2)
;Find the position of the equals sign
;Find4 = strpos(Trim4, '=', /REVERSE_SEARCH)
Find_elev = strpos(Trim_elev, '=', /REVERSE_SEARCH)
;Extract the Sun Angle
;Sun_Angle = strmid(Trim4, Find4 + 2)
SunAngle = double(strmid(Trim_elev, Find_elev + 2))
;Convert the SunAngle array to an element variable
SunAngle = temporary(SunAngle[0])

;Finding the Lmax, Lmin, QCALMAX, and QCALMIN for each band
;Band 1
Trim_LmxB1 = strtrim(array[where(strpos(array, " LMAX_BAND1")ne-1)], 2)
Trim_LmnB1 = strtrim(array[where(strpos(array, " LMIN_BAND1")ne-1)], 2)
Find_LmxB1 = strpos(Trim_LmxB1, '=', /REVERSE_SEARCH)
Find_LmnB1 = strpos(Trim_LmnB1, '=', /REVERSE_SEARCH)
LMAX_Band1 = double(strmid(Trim_LmxB1, Find_LmxB1 + 2))
LMIN_Band1 = double(strmid(Trim_LmnB1, Find_LmnB1 + 2))

Trim_QmxB1 = strtrim(array[where(strpos(array, " QCALMAX_BAND1")ne-1)], 2)
Trim_QmnB1 = strtrim(array[where(strpos(array, " QCALMIN_BAND1")ne-1)], 2)
Find_QmxB1 = strpos(Trim_QmxB1, '=', /REVERSE_SEARCH)
Find_QmnB1 = strpos(Trim_QmnB1, '=', /REVERSE_SEARCH)
QCALMAX_Band1 = double(strmid(Trim_QmxB1, Find_QmxB1 + 2))
QCALMIN_Band1 = double(strmid(Trim_QmnB1, Find_QmnB1 + 2))

;Band 2
Trim_LmxB2 = strtrim(array[where(strpos(array, " LMAX_BAND2")ne-1)], 2)
Trim_LmnB2 = strtrim(array[where(strpos(array, " LMIN_BAND2")ne-1)], 2)
Find_LmxB2 = strpos(Trim_LmxB2, '=', /REVERSE_SEARCH)
Find_LmnB2 = strpos(Trim_LmnB2, '=', /REVERSE_SEARCH)
LMAX_Band2 = double(strmid(Trim_LmxB2, Find_LmxB2 + 2))
LMIN_Band2 = double(strmid(Trim_LmnB2, Find_LmnB2 + 2))

Trim_QmxB2 = strtrim(array[where(strpos(array, " QCALMAX_BAND2")ne-1)], 2)
Trim_QmnB2 = strtrim(array[where(strpos(array, " QCALMIN_BAND2")ne-1)], 2)
Find_QmxB2 = strpos(Trim_QmxB2, '=', /REVERSE_SEARCH)
Find_QmnB2 = strpos(Trim_QmnB2, '=', /REVERSE_SEARCH)
QCALMAX_Band2 = double(strmid(Trim_QmxB2, Find_QmxB2 + 2))
QCALMIN_Band2 = double(strmid(Trim_QmnB2, Find_QmnB2 + 2))

;Band 3
Trim_LmxB3 = strtrim(array[where(strpos(array, " LMAX_BAND3")ne-1)], 2)
Trim_LmnB3 = strtrim(array[where(strpos(array, " LMIN_BAND3")ne-1)], 2)
Find_LmxB3 = strpos(Trim_LmxB3, '=', /REVERSE_SEARCH)
Find_LmnB3 = strpos(Trim_LmnB3, '=', /REVERSE_SEARCH)
LMAX_Band3 = double(strmid(Trim_LmxB3, Find_LmxB3 + 2))
LMIN_Band3 = double(strmid(Trim_LmnB3, Find_LmnB3 + 2))

Trim_QmxB3 = strtrim(array[where(strpos(array, " QCALMAX_BAND3")ne-1)], 2)
Trim_QmnB3 = strtrim(array[where(strpos(array, " QCALMIN_BAND3")ne-1)], 2)
Find_QmxB3 = strpos(Trim_QmxB3, '=', /REVERSE_SEARCH)
Find_QmnB3 = strpos(Trim_QmnB3, '=', /REVERSE_SEARCH)
QCALMAX_Band3 = double(strmid(Trim_QmxB3, Find_QmxB3 + 2))
QCALMIN_Band3 = double(strmid(Trim_QmnB3, Find_QmnB3 + 2))

;Band 4
Trim_LmxB4 = strtrim(array[where(strpos(array, " LMAX_BAND4")ne-1)], 2)
Trim_LmnB4 = strtrim(array[where(strpos(array, " LMIN_BAND4")ne-1)], 2)
Find_LmxB4 = strpos(Trim_LmxB4, '=', /REVERSE_SEARCH)
Find_LmnB4 = strpos(Trim_LmnB4, '=', /REVERSE_SEARCH)
LMAX_Band4 = double(strmid(Trim_LmxB4, Find_LmxB4 + 2))
LMIN_Band4 = double(strmid(Trim_LmnB4, Find_LmnB4 + 2))

Trim_QmxB4 = strtrim(array[where(strpos(array, " QCALMAX_BAND4")ne-1)], 2)
Trim_QmnB4 = strtrim(array[where(strpos(array, " QCALMIN_BAND4")ne-1)], 2)
Find_QmxB4 = strpos(Trim_QmxB4, '=', /REVERSE_SEARCH)
Find_QmnB4 = strpos(Trim_QmnB4, '=', /REVERSE_SEARCH)
QCALMAX_Band4 = double(strmid(Trim_QmxB4, Find_QmxB4 + 2))
QCALMIN_Band4 = double(strmid(Trim_QmnB4, Find_QmnB4 + 2))

;Band 5
Trim_LmxB5 = strtrim(array[where(strpos(array, " LMAX_BAND5")ne-1)], 2)
Trim_LmnB5 = strtrim(array[where(strpos(array, " LMIN_BAND5")ne-1)], 2)
Find_LmxB5 = strpos(Trim_LmxB5, '=', /REVERSE_SEARCH)
Find_LmnB5 = strpos(Trim_LmnB5, '=', /REVERSE_SEARCH)
LMAX_Band5 = double(strmid(Trim_LmxB5, Find_LmxB5 + 2))
LMIN_Band5 = double(strmid(Trim_LmnB5, Find_LmnB5 + 2))

Trim_QmxB5 = strtrim(array[where(strpos(array, " QCALMAX_BAND5")ne-1)], 2)
Trim_QmnB5 = strtrim(array[where(strpos(array, " QCALMIN_BAND5")ne-1)], 2)
Find_QmxB5 = strpos(Trim_QmxB5, '=', /REVERSE_SEARCH)
Find_QmnB5 = strpos(Trim_QmnB5, '=', /REVERSE_SEARCH)
QCALMAX_Band5 = double(strmid(Trim_QmxB5, Find_QmxB5 + 2))
QCALMIN_Band5 = double(strmid(Trim_QmnB5, Find_QmnB5 + 2))

;Band 6
Trim_LmxB6 = strtrim(array[where(strpos(array, " LMAX_BAND6")ne-1)], 2)
Trim_LmnB6 = strtrim(array[where(strpos(array, " LMIN_BAND6")ne-1)], 2)
Find_LmxB6 = strpos(Trim_LmxB6, '=', /REVERSE_SEARCH)
Find_LmnB6 = strpos(Trim_LmnB6, '=', /REVERSE_SEARCH)
LMAX_Band6 = double(strmid(Trim_LmxB6, Find_LmxB6 + 2))
LMIN_Band6 = double(strmid(Trim_LmnB6, Find_LmnB6 + 2))

Trim_QmxB6 = strtrim(array[where(strpos(array, " QCALMAX_BAND6")ne-1)], 2)
Trim_QmnB6 = strtrim(array[where(strpos(array, " QCALMIN_BAND6")ne-1)], 2)
Find_QmxB6 = strpos(Trim_QmxB6, '=', /REVERSE_SEARCH)
Find_QmnB6 = strpos(Trim_QmnB6, '=', /REVERSE_SEARCH)
QCALMAX_Band6 = double(strmid(Trim_QmxB6, Find_QmxB6 + 2))
QCALMIN_Band6 = double(strmid(Trim_QmnB6, Find_QmnB6 + 2))

;Band 7
Trim_LmxB7 = strtrim(array[where(strpos(array, " LMAX_BAND7")ne-1)], 2)
Trim_LmnB7 = strtrim(array[where(strpos(array, " LMIN_BAND7")ne-1)], 2)
Find_LmxB7 = strpos(Trim_LmxB7, '=', /REVERSE_SEARCH)
Find_LmnB7 = strpos(Trim_LmnB7, '=', /REVERSE_SEARCH)
LMAX_Band7 = double(strmid(Trim_LmxB7, Find_LmxB7 + 2))
LMIN_Band7 = double(strmid(Trim_LmnB7, Find_LmnB7 + 2))

Trim_QmxB7 = strtrim(array[where(strpos(array, " QCALMAX_BAND7")ne-1)], 2)
Trim_QmnB7 = strtrim(array[where(strpos(array, " QCALMIN_BAND7")ne-1)], 2)
Find_QmxB7 = strpos(Trim_QmxB7, '=', /REVERSE_SEARCH)
Find_QmnB7 = strpos(Trim_QmnB7, '=', /REVERSE_SEARCH)
QCALMAX_Band7 = double(strmid(Trim_QmxB7, Find_QmxB7 + 2))
QCALMIN_Band7 = double(strmid(Trim_QmnB7, Find_QmnB7 + 2))

;Calculate the gain and bias from the LMIN's/LMAX's.
B1_gain = (LMAX_BAND1 - LMIN_BAND1) / (QCALMAX_Band1 - QCALMIN_Band1)
B1_bias = LMIN_BAND1 - (B1_gain * QCALMIN_Band1)
B2_gain = (LMAX_BAND2 - LMIN_BAND2) / (QCALMAX_Band2 - QCALMIN_Band2)
B2_bias = LMIN_BAND2 - (B2_gain * QCALMIN_Band2)
B3_gain = (LMAX_BAND3 - LMIN_BAND3) / (QCALMAX_Band3 - QCALMIN_Band3)
B3_bias = LMIN_BAND3 - (B3_gain * QCALMIN_Band3)
B4_gain = (LMAX_BAND4 - LMIN_BAND4) / (QCALMAX_Band4 - QCALMIN_Band4)
B4_bias = LMIN_BAND4 - (B4_gain * QCALMIN_Band4)
B5_gain = (LMAX_BAND5 - LMIN_BAND5) / (QCALMAX_Band5 - QCALMIN_Band5)
B5_bias = LMIN_BAND5 - (B5_gain * QCALMIN_Band5)
B6_gain = (LMAX_BAND6 - LMIN_BAND6) / (QCALMAX_Band6 - QCALMIN_Band6)
B6_bias = LMIN_BAND6 - (B6_gain * QCALMIN_Band6)
B7_gain = (LMAX_BAND7 - LMIN_BAND7) / (QCALMAX_Band7 - QCALMIN_Band7)
B7_bias = LMIN_BAND7 - (B7_gain * QCALMIN_Band7)

rfl_gain = [B1_gain, B2_gain, B3_gain, B4_gain, B5_gain, B7_gain]
rfl_bias = [B1_bias, B2_bias, B3_bias, B4_bias, B5_bias, B7_bias]

;band names
rfl_bname = ['Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Band 7']
Therm_bname = ['Band 6']

;The tmcal_doit procedure needs to run twice; once for the thermal band
;and once for the reflectance bands
;Also, the thermal band needs to be converted to radiance, and then 
;a band math operation to convert to kelvin.
;This was supposed to be done within the tmcal procedure, but doesn't seem to be working

;Thermal Band
ENVI_DOIT, 'TMCAL_DOIT', fid=fids[0], bands_present=[5], $
     dims=Therm_dims, sat=sat, cal_type=therm_cal_type, date=date, out_name=Therm_file_out_name, $
     sun_angle=SunAngle, r_fid=r_fid, pos=Therm_pos, gain=B6_gain, bias=B6_bias, $
     out_bname=Therm_bname
     
;Reflectance Bands
ENVI_DOIT, 'TMCAL_DOIT', fid=fids[2], bands_present=[0,1,2,3,4,6], $
     dims=rfl_dims, sat=sat, cal_type=rfl_cal_type, date=date, out_name=rfl_file_out_name, $
     sun_angle=SunAngle, r_fid=r_fid, pos=rfl_pos, gain=rfl_gain, bias=rfl_bias, $
     out_bname=rfl_bname  

;Re-find the fid's, and remove them from envi
;that way the same 'fids' positions can be used
fids = envi_get_file_ids()
FOR i = 0, n_elements(fids) -1 DO BEGIN
  envi_file_mng, id = fids[i], /Remove
ENDFOR


Counter=counter +1
ENDWHILE

;envi_batch_exit 

end