function num_samples, header

    compile_opt hidden
    
    fns = strtrim(header[where(strpos(header, "samples")ne-1)], 2)
    fns1 = strpos(fns, '=')
    ns = strmid(fns, fns1 + 2)
    
    return, ns
    
end

;-----------------------------------------------------------------------

function num_lines, header
    
    compile_opt hidden
    
    fnl = strtrim(header[where(strpos(header, "lines")ne-1)], 2)
    fnl1 = strpos(fnl, '=')
    nl = strmid(fnl, fnl1 + 2)
    
    return, nl
    
end

;-----------------------------------------------------------------------

function num_bands, header

    compile_opt hidden
    
    fnb = strtrim(header[where(strpos(header, "bands")ne-1)], 2)
    fnb1 = strpos(fnb, '=')
    nb = strmid(fnb, fnb1 + 2)
    
    return, nb
    
end

;-----------------------------------------------------------------------

pro ps_multiple_test2

 compile_opt idl2

;Have to open the available bands list at the start
;as once in PS mode windows can't be generated.
 
;file = 'C:\Program Files\ITT\IDL\IDL80\examples\data\muscle.jpg'
;result = query_jpeg(file, info)
;if result eq 0 then return
;read_jpeg, file, image

;image = fltarr(400, 400, 46, /nozero)
;openr, lun, 'D:\Data\Imagery\MODIS_Imagery\NDVI\Movie\2008_2009_Cubby', /get_lun
;readu, lun, image
;close, lun
;free_lun, lun

;redesign the search, by removing the extension
;this may not work for all cases
;but will then not have to open the file in envi
;and pass the fid to idl. can just work from idl
;At this stage, working from just idl will not work
;as the image variable needs to be defined
;which is retrieved via the envi query, eg ns, nl, nb
;So have to open the available bands list at the start
;as once in PS mode windows such as "Available Bands List", can't be generated.
;HAVE A SOLUTION, this now works in IDL alone
;It has to read in the hdr files and from there extract
;out the ns, nl, nb

dir = 'N:\'
;dir = 'W:\Corporate Data\Storage02\Remote_Sensing\Processed_Images'
cd, dir
files=FILE_SEARCH('Storage01','*_rfl_mSubs.hdr',COUNT=numfiles)
;files1=FILE_SEARCH('Landsat5','*[0-9]_rfl*m.hdr',COUNT=numfiles1)
;files2=FILE_SEARCH('Landsat5','*[0-9]_rfl*mSubs.hdr',COUNT=numfiles2)
;
;no hdr extension
;files1=FILE_SEARCH('Landsat5','*[0-9]_rfl*m',COUNT=numfiles1)
;files2=FILE_SEARCH('Landsat5','*[0-9]_rfl*mSubs',COUNT=numfiles2)
;
;for multiple searches, when files don't have the same
;naming convention
;files = [files1,files2]
;numfiles = numfiles1 + numfiles2

;counter = 0

;set the plot output device
mydevice = !D.NAME
set_plot, 'ps'

;page size in cm
xsz = 21.0
ysz = 29.7

;starting co-ordinates (normalised) of 1st image
xstart = 0.02
ystart = 0.88

;step size (normalised units) for image placement
xstep = 0.16
ystep = 0.12

;ending co-ordinates (normalised
xend = 0.83
yend = 0.02

;image size (normalised units)
ximg = 0.15
yimg = 0.1

;new x and y co-ordinates, for the fisrt image they equal xstart/ystart
xnew = xstart
ynew = ystart

;text positions
;x = x + 0.075
;y = y - 0.01

;post-script file numbers
psfnum = 1

;post-script file names
outdir = 'D:\Data\Imagery\Landsat\Landsat_5\Thumbs\'
;basename = outdir + 'L5TM_test_thumbs_'
basename = outdir + 'Storage01_L5TM_thumbs_'

;want L5TM_thumbs_ + psfnum 
outpsname = basename + strtrim(string(psfnum, format = '(%"%06d")'), 2) + '.ps'

;get the colour table names
;loadct, get_names = name

;juldate = [2008001, 2008017, 2008033, 2008049, 2008065, 2008081, 2008097, 2008113, 2008129, 2008145, 2008161, $
 ;           2008177, 2008193, 2008209, 2008225, 2008241, 2008257, 2008273, 2008289, 2008305, 2008321, 2008337, $
  ;          2008353, 2009001, 2009017, 2009033, 2009049, 2009065, 2009081, 2009097, 2009113, 2009129, 2009145, $
   ;         2009161, 2009177, 2009193, 2009209, 2009225, 2009241, 2009257, 2009273, 2009289, 2009305, 2009321, $
    ;        2009337, 2009353]

;value array
;num = sindgen(41)


;setting decomposed = 0 makes the text display as different colours
;device, decomposed=1, filename='muscle_colours_final.ps', /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0
device, decomposed=1, filename=outpsname, /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0

  for i =0L, numfiles-1 do begin
    ;loadct, i
    
    ;ENVI_OPEN_FILE, files[counter], r_fid=fid
    ;if (fid eq -1) then return
    ;envi_file_query, fid, fname=fname, ns=ns, nl=nl, nb=nb

    header = js_read_ascii(files[i])
    ns = num_samples(header)
    nl = num_lines(header)
    nb = num_bands(header)

    image = fltarr(ns, nl, nb, /nozero)
    fname = file_dirname(files[i]) + '\' + file_basename(files[i], '.hdr')
    
    openr, lun, fname, /get_lun
    readu, lun, image
    free_lun, lun
   
    ;ENVI_FILE_MNG, id=fid, /REMOVE
    
    ;counter = counter + 1
;resize the image so the overall ps file size is reduced
;and select bands 3,4,5
    image = temporary(congrid(image[*,*,2:4], 400, 400, 3))
;re-order 3,4,5 to 5,4,3 to display as red, green, blue 
    image = temporary(reverse(image, 3))
    
    imgname = strmid(file_basename(fname), 0, 15)
    
    tvscl, image, true=3, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order, /nan
    ;tvscl, image[*,*,3], channel=1, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
    ;tvscl, image[*,*,2], channel=2, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
    ;tvscl, image[*,*,1], channel=3, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
    ;xyouts, xnew + 0.055, ynew - 0.01, num[i] + ': ' + name[i], alignment = 0.5, /normal, charsize=0.5
    xyouts, xnew + 0.075, ynew - 0.01, imgname, alignment = 0.5, /normal, charsize=0.75
  
    if xnew + xstep lt xend then begin
       xnew = xnew + xstep
    endif else begin
      xnew = xstart
      ynew = ynew - ystep
      
;when the page is full need to close the file
;and open a new one        
        if ynew lt yend then begin
          device, /close
          
          psfnum = psfnum + 1
          outpsname = basename + strtrim(string(psfnum, format = '(%"%06d")'), 2) + '.ps'
          device, decomposed=1, filename=outpsname, /color, xsize=xsz, ysize=ysz, $
            xoffset=0.0, yoffset=0.0
;reset to ystart          
          ynew = ystart 
        endif  
      endelse
  endfor

;Title
;xyouts, 0.5, 0.075, 'Predefined Colour Tables', alignment = 0.5, /normal, charsize=2
;xyouts, xnew + xstep, 0.12, 'Cubby Station', alignment = 0.5, /normal, charsize=2
;xyouts, xnew + xstep, 0.095, 'Jan 2008', alignment = 0.5, /normal, charsize=2
;xyouts, xnew + xstep, 0.07, 'to', alignment = 0.5, /normal, charsize=2
;xyouts, xnew + xstep, 0.045, 'Dec 2009', alignment = 0.5, /normal, charsize=2
  
device, /close

;return to original plot output device
set_plot, mydevice

end

