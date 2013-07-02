PRO EXAMPLE_TMCAL_DOIT

COMPILE_OPT IDL2

 

; First restore all the base save files.

envi, /restore_base_save_files

 

; Initialize ENVI and send all errors

; and warnings to the file batch.txt

envi_batch_init, log_file='batch.txt'

 

; Create a variable to store the file location.

; File systems may vary locations, this is an example.

file_name = 'boulder.tif’

 

; Open the input file

envi_select, fid=fid, pos=pos

if (fid eq -1) then begin

   envi_batch_exit

   return

endif

fids = envi_get_file_ids() 

;Output the result to disk.

envi_file_query, fid, dims=dims, nb=nb, bnames=bname

 

; Set the POS keyword to process all

; spectral data.

pos = lindgen(nb)

 

; Set bands_present based on an array position.

; ----------------------------------------------

; Sensor MSS:

; Bands | 4 | 5 | 6 | 7 | MSS 1-3

; Bands | 1 | 2 | 3 | 4 | MSS 4-5

; Array | 0 | 1 | 2 | 3 |

; Sensor TM:

; Bands | 1 | 2 | 3 | 4 | 5 | 6 | 7 |

; Array | 0 | 1 | 2 | 3 | 4 | 5 | 6 |

; Sensor ETM:

; Bands | 1 | 2 | 3 | 4 | 5 | 61 | 62 | 7 | 8 |

; Array | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |

; bands_present = [ARRAY_POSITION]

; ----------------------------------------------

 

; Single Band example for

; satellite ETM+ band 1

;bands present does affect the result
;bands_present = [0,1,2,3,4,6]
bands_present = [5]
;bands_present = [5,6]
 

; Assign lmin/lmax values

; if gain/bias is unknown.

;lmin = -6.2 ; ETM+ High radiance value.

;lmax = 191.6 ; ETM+ High radiance value.

lmin = 1.238 ; testing the thermal band
lmax = 15.303 ; testing the thermal band

B61min = 0
B61max = 17.040
B62min = 3.2
B62max = 12.650

B61gain = (B61max - B61min) / 255
B62gain = (B62max - B62min) /255

B61bias = B61min
B62bias = B62min

    LMAX_BAND1 = 193.000
    LMIN_BAND1 = -1.520
    LMAX_BAND2 = 365.000
    LMIN_BAND2 = -2.840
    LMAX_BAND3 = 264.000
    LMIN_BAND3 = -1.170
    LMAX_BAND4 = 221.000
    LMIN_BAND4 = -1.510
    LMAX_BAND5 = 30.200
    LMIN_BAND5 = -0.370
    LMAX_BAND6 = 15.303
    LMIN_BAND6 = 1.238
    LMAX_BAND7 = 16.500
    LMIN_BAND7 = -0.150

;testing to see if the keyword "float" has an affect on the calculation; doesn't seem to, same for "double".
    
B1_gain = double((LMAX_BAND1 - LMIN_BAND1) / 255)
B1_bias = double(LMIN_BAND1)
B2_gain = double((LMAX_BAND2 - LMIN_BAND2) / 255)
B2_bias = double(LMIN_BAND2)
B3_gain = double((LMAX_BAND3 - LMIN_BAND3) / 255)
B3_bias = double(LMIN_BAND3)
B4_gain = double((LMAX_BAND4 - LMIN_BAND4) / 255)
B4_bias = double(LMIN_BAND4)
B5_gain = double((LMAX_BAND5 - LMIN_BAND5) / 255)
B5_bias = double(LMIN_BAND5)
B6_gain = double((LMAX_BAND6 - LMIN_BAND6) / 255)
B6_bias = double(LMIN_BAND6)
B7_gain = double((LMAX_BAND7 - LMIN_BAND7) / 255)
B7_bias = double(LMIN_BAND7)

;B1_gain2 = double((LMAX_BAND1 - LMIN_BAND1) / 254)
;B1_bias2 = double(LMIN_BAND1) - B1_gain2
;B2_gain2 = double((LMAX_BAND2 - LMIN_BAND2) / 254)
;B2_bias2 = double(LMIN_BAND2) - B2_gain2
;B3_gain2 = double((LMAX_BAND3 - LMIN_BAND3) / 254)
;B3_bias2 = double(LMIN_BAND3) - B3_gain2
;B4_gain2 = double((LMAX_BAND4 - LMIN_BAND4) / 254)
;B4_bias2 = double(LMIN_BAND4) - B4_gain2
;B5_gain2 = double((LMAX_BAND5 - LMIN_BAND5) / 254)
;B5_bias2 = double(LMIN_BAND5) - B5_gain2
;B6_gain2 = double((LMAX_BAND6 - LMIN_BAND6) / 254)
;B6_bias2 = double(LMIN_BAND6) - B6_gain2
;B7_gain2 = double((LMAX_BAND7 - LMIN_BAND7) / 254)
;B7_bias2 = double(LMIN_BAND7) - B7_gain2

B1_gain2 = ((double(LMAX_BAND1) - LMIN_BAND1) / 254)
B1_bias2 = double(LMIN_BAND1) - B1_gain2
B2_gain2 = ((double(LMAX_BAND2) - LMIN_BAND2) / 254)
B2_bias2 = double(LMIN_BAND2) - B2_gain2
B3_gain2 = ((double(LMAX_BAND3) - LMIN_BAND3) / 254)
B3_bias2 = double(LMIN_BAND3) - B3_gain2
B4_gain2 = ((double(LMAX_BAND4) - LMIN_BAND4) / 254)
B4_bias2 = double(LMIN_BAND4) - B4_gain2
B5_gain2 = ((double(LMAX_BAND5) - LMIN_BAND5) / 254)
B5_bias2 = double(LMIN_BAND5) - B5_gain2
B6_gain2 = ((double(LMAX_BAND6) - LMIN_BAND6) / 254)
B6_bias2 = double(LMIN_BAND6) - B6_gain2
B7_gain2 = ((double(LMAX_BAND7) - LMIN_BAND7) / 254)
B7_bias2 = double(LMIN_BAND7) - B7_gain2
 

; Calculate the gain and bias from lmin/lmax.

;gain = (double(lmax) - lmin) / 254

;bias = lmin - gain

gain = (double(lmax) - lmin) / 255

bias = lmin

;gain = (LMAX_BAND4 - LMIN_BAND4) / 255

;bias = LMIN_BAND4

;gain = [B61gain,B62gain]
;bias = [B61bias,B62bias]

;gain = [B1_gain,B2_gain,B3_gain,B4_gain,B5_gain,B7_gain]
;bias = [B1_bias,B2_bias,B3_bias,B4_bias,B5_bias,B7_bias]

;gain = [B1_gain2,B2_gain2,B3_gain2,B4_gain2,B5_gain2,B7_gain2]
;bias = [B1_bias2,B2_bias2,B3_bias2,B4_bias2,B5_bias2,B7_bias2]

;gain = [B6_gain]
;bias = [B6_bias]
 

; Assign the acquisition date to the variable data.

;date = [11,17,2000]
date = [12,14,2008]
;date = 2
;out_name = 'all_rfl'
out_name = '2008_12_14_therm_rad'
;test to see if specifying a sub folder
;in the current directory will put the file there...it does
;out_name = 'rfl\2008_12_14_rfl_tmcal_vartest'
;SunAngle = double(57.2680115)
;the inbulit envi procedure rounds the sun angle figure to 2 d.p.
SunAngle = double(57.27)
;SunAngle = 57.2680115
;SunAngle = double(29.26)

;band names
;rfl_bname = ['Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Band 7']
;Therm_bname = ['Band 6'] 

; ------------------------------------------------------------------

; Determine Satellite by array position

; Satellite | ETM+7 | TM5 | TM4 | MSS5 | MSS4 | MSS3 | MSS2 | MSS1 |

; Array | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |

; ------------------------------------------------------------------

; Use Case:

sat = 1 ; if 0, This will use calibration values of ETM+7

 

; Perform the TM Calibration

envi_doit, 'tmcal_doit', $

   fid=fid, pos=pos, dims=dims, $

   bands_present=bands_present, $

   sat=sat, cal_type=0, date=date, $

   sun_angle=SunAngle, out_name=out_name, $

   r_fid=r_fid, gain=gain, bias=bias
   ;, $
   ;out_bname=Therm_bname

 

; Exit ENVI

;envi_batch_exit

END
