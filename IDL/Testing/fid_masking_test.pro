;Creates masks from a series of shapefiles.  Each mask is to be populated with
;the value of the shapefile fid, eg FID of 112 has the value 112 instead of 1
;which is normally the case.  Also, can't use a fill value of zero as FID 0
;is considered valid.  The fill value instead will be -999 (Might use 255 to keep
;the image as a smallish size of type byte).
;The shapefiles will need to be the same projection as the image.
;Steps: (1) Create the mask of the shapefile location.
;       (2) Change the value of the true, i.e. 1, to the FID value,
;           however the FID value has to be FID + 1, as initially we need
;           a fill value of zero when the FIDvalueMasks are combined.
;           band math: (b1 eq 1) * (FIDnum + 1)
;       (3) Combine the FIDvalueMasks, essentially just b1 + b2 + b3 etc
;       (4) Convert the zero fill to -999 and subtract 1 from the rest to
;           change the FID fill values back to their original value
;

pro fid_masking_test

;The directory for finding the evf files.  In this example the evf files are
;located within a folder called Block, which is a subfolder to Testing
cd, 'C:\WINNT\Profiles\u08087\My Documents\Testing'

;The search method for finding files.  As this will be run on a machine
;with limited resources, i.e. hard drive space, and RAM, we'll have to limit
;the vector files allowed to 4.  So manually copying only 4 into the directory
;will suffice at this stage.
files=FILE_SEARCH('Block','*.evf',COUNT=numfiles, /FULLY_QUALIFY_PATH)

counter = 0

;The output folder for the masks
cd, 'C:\WINNT\Profiles\u08087\My Documents\Testing\Masks'

;the image to be used as a basis for mask dimensions and co-ordinate system
img = 'C:\WINNT\Profiles\u08087\My Documents\Testing\image'

;Need to open the image in order to get projection and pixel co-ordinates
ENVI_OPEN_FILE, img, r_fid=fid
  if(fid eq -1) then begin
    ENVI_BATCH_EXIT
    return
  endif

;Retrieve image info
ENVI_FILE_QUERY, fid, dims=dims, fname=fname, ns=ns, nl=nl, nb=nb
map_info = envi_get_map_info(fid=fid)

WHILE counter LT numfiles DO BEGIN

    Mask_evf_id = envi_evf_open(files[counter])

    ;get info of the evf that will be used as a mask
    envi_evf_info, Mask_evf_id, num_recs=Mask_num_recs, $
       data_type=Mask_data_type, projection=Mask_projection, $
       layer_name=Mask_layer_name

    ;extract the number of vertices from a record into a variable.
    ;Will only work for 1 record otherwise the variable will be overwritten
    ;by the last record
    for i=0,Mask_num_recs-1 do begin
       Mask_record = envi_evf_read_record(Mask_evf_id, i, type=5)
    endfor

    ;retrieve the FID value from the shapefile name, for this test
    ;it is the last 2 characters before the '.shp'
    Mask_rmvSHP = FILE_BASENAME(Mask_layer_name, '.shp')
    FID_Fill = FIX(STRMID(Mask_rmvSHP, 1, /reverse_offset))

    ;remove the 'Layer: ' from the front of the file name
    mask_out_name = STRMID(Mask_rmvSHP, 7)

    ;convert the map coordinates to image coordinates
    envi_convert_file_coordinates, fid, Mask_xf, Mask_yf, $
       Mask_record[0,*], Mask_record[1,*]

    ;create the base roi from the image dimensions
    Mask_roi_id = ENVI_CREATE_ROI(ns=ns, nl=nl, $
       color=4, name='Mask_evfs')

    ;change the array dimensions of the co-ordinates
    Mask_xpts=reform(Mask_xf)
    Mask_ypts=reform(Mask_yf)

    ;create the roi, these won't be saved
    ENVI_DEFINE_ROI, Mask_roi_id, /polygon, xpts=Mask_xpts, ypts=Mask_ypts

    ;Mask_roi_ids = envi_get_roi_ids(fid=fid)

    ;create the array to hold the mask
    ;using intarr should skip one of the band math steps
    ;mask = INTARR([ns,nl]), NO, as byte holds 0-255 which is enough for this test
    mask= BYTARR([ns,nl])

    ;create the mask
    addr = ENVI_GET_ROI(Mask_roi_id[0])
    ;could set the value to equal the FID value + 1 (catering for the case of FID = 0)
    ;Specifying the value will eliminate one of the band math steps
    mask[addr] = FID_fill + 1
    ;mask[addr]=1

    ;write the mask to file, so it can be used later
    ENVI_WRITE_ENVI_FILE, mask, BNAMES='mask', DATA_TYPE=1, MAP_INFO=map_info, $
        r_fid=m_fid, OUT_NAME=mask_out_name

    ;the counter list will work in blocks of 6?
    counter = counter + 1
    ENDWHILE

;could implement a band math routine here to combine the masks into one file then
;delete the 1st stage masks and keep the single final one


end
