pro test_ps_fmask

    ; get current display device
    mydevice = !D.NAME

    ; set the post script display
    set_plot, 'ps'

    cd, 'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\scene_testing'

    ; find the files. seperate searches for different groups
    bandfiles = file_search('*B[0-9]*.tif',count=bndcount)
    acafiles = file_search('*ACCA*.tif', count=acacount)
    ;fmpfiles = file_search('*_[0-9][0-9]_percent*', count=fmpcount)
    ;acafmpfiles = file_search('*.*percent*', count=acafmpcount)
    fmpfiles = file_search('*_[0-9][0-9]_percent_v2*', count=fmpcount)
    acafmpfiles = file_search('*.*percent_v2*', count=acafmpcount)

    ;page size in cm
    xsz = 21.0
    ysz = 29.7

    ;starting co-ordinates (normalised) of 1st image and side text
    txtxstart = 0.02
    xstart = 0.12
    ystart = 0.885
    txtystart = 0.93

    ;step size (normalised units) for image placement
    xstep = 0.16
    ystep = 0.11

    ;ending co-ordinates (normalised
    xend = 0.83
    yend = 0.01

    ;image size (normalised units)
    ximg = 0.15
    yimg = 0.1

    ;new x and y co-ordinates, for the fisrt image they equal xstart/ystart
    xnew = xstart
    ynew = ystart

    fout = 'Fmask_percent_comparisons_v2.ps'

    device, filename=fout, /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0

    ; output the side text
    xyouts, txtxstart, txtystart, 'False Colour', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-ystep, 'ACCA', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-2*ystep, '0%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-3*ystep, '5%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-4*ystep, '10%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-5*ystep, '15%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-6*ystep, '20%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-7*ystep, '25%', /normal, charsize=0.75
    xyouts, txtxstart, txtystart-8*ystep, 'ACCA Input', /normal, charsize=0.75

    ;xyouts, 0.0, 0.0, 'LL', /normal, charsize=0.75

    ; output the images and scene headings
    for i =0, bndcount-1 do begin
        image = bytarr(400,400,3)
        gr = read_tiff(bandfiles[i])
        image[*,*,2] = congrid(gr, 400,400)
        ;delvar, gr
        rd = read_tiff(bandfiles[i+1])
        image[*,*,1] = congrid(rd, 400,400)
        ;delvar, rd
        nr = read_tiff(bandfiles[i+2])
        image[*,*,0] = congrid(nr, 400,400)
        ;delvar, nr
        hname = strmid(file_basename(bandfiles[i]), 0, 20)
        i = i + 2

        xyouts, xnew + 0.075, 0.99, hname, alignment = 0.5, /normal, charsize=0.65
        tvscl, image, true=3, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
        xnew = xnew + xstep
    endfor

    xnew = xstart
    ; read the acca files
    for j=0, 3 do begin
        acimg = read_tiff(acafiles[j])
        acimg = temporary(congrid(acimg, 400, 400))
        flip = (acimg eq 0)*1 + (acimg eq 1)*0
        ;tv, acimg, xnew, ynew-ystep, xsize=ximg, ysize=yimg, /normal, /order
        tvscl, flip, xnew, ynew-ystep, xsize=ximg, ysize=yimg, /normal, /order
        xnew = xnew + xstep
    endfor

    ynew = ystart-2*ystep
    xnew = xstart
    ; read the fmask percent files
    for k=0, fmpcount-1 do begin
        fmimg = read_tiff(fmpfiles[k])
        fmimg = temporary(congrid(fmimg, 400, 400))
        flip = (fmimg eq 0)*1 + (acimg eq 1)*0
        ;tvscl, fmimg, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
        tvscl, flip, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
        ;ynew = ynew-ystep

        if ynew -ystep lt yend then begin
            ynew = ystart-2*ystep
            xnew = xnew + xstep
            if xnew gt xend then xnew = xstart
        endif else begin
            ynew = ynew-ystep
        endelse
    endfor

    xnew = xstart
    ynew = ystart - 8*ystep
    ; read the acca input percent fmask files
    for z=0, 3 do begin
        acifimg = read_tiff(acafmpfiles[z])
        acifimg = temporary(congrid(acifimg, 400, 400))
        flip = (acifimg eq 0)*1 + (acifimg eq 1)*0
        ;tvscl, acifimg, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
        tvscl, flip, xnew, ynew, xsize=ximg, ysize=yimg, /normal, /order
        xnew = xnew + xstep
    endfor

    device, /close

    set_plot, mydevice

end
