pro test_iedge_ps

    ; get current display device
    mydevice = !D.NAME

    ; set the post script display
    set_plot, 'ps'

    cd, 'C:\WINNT\Profiles\u08087\My Documents\Imagery\Temp\wierd_values_at_edges'
    f = file_search('*[1]_z*.bmp', count=fcount)
    fscl = file_search('*scaled*.bmp', count=sclcount)


    ;page size in cm
    xsz = 21.0
    ysz = 29.7

    ;starting co-ordinates (normalised) of 1st image and side text
    txtxstart = 0.02
    xstart = 0.005
    ystart = 0.76
    txtystart = 0.93

    ;step size (normalised units) for image placement
    xstep = 0.25
    ystep = 0.21

    ;ending co-ordinates (normalised
    xend = 0.83
    yend = 0.01

    ;image size (normalised units)
    ximg = 0.24
    yimg = 0.2

    ;new x and y co-ordinates, for the fisrt image they equal xstart/ystart
    xnew = xstart
    ynew = ystart


    fout = 'scene_edge_anomolies.ps'

    device, filename=fout, /color, xsize=xsz, ysize=ysz, xoffset=0.0, yoffset=0.0
    xyouts, xnew + 0.12, ynew + 0.22, 'Scene (Bands 1,2,3)', alignment=0.5, /normal, charsize=1
    xyouts, xnew + xstep + 0.12, ynew + 0.22, 'Flagged Pixels', alignment=0.5, /normal, charsize=1
    xyouts, xnew + (2*xstep) + 0.12, ynew + 0.22, 'Scene (Bands 1,2,3)', alignment=0.5, /normal, charsize=1
    xyouts, xnew + (3*xstep) + 0.12, ynew + 0.22, 'Flagged Pixels', alignment=0.5, /normal, charsize=1

    for i =0, fcount-1 do begin
        image = read_bmp(f[i])
        tvscl, reverse(image, 1), true=1, xnew, ynew, xsize=ximg, ysize=yimg, /normal

        xnew = xnew + xstep

        image = read_bmp(fscl[i])
        tvscl, reverse(image, 1), true=1, xnew, ynew, xsize=ximg, ysize=yimg, /normal
        if xnew + xstep lt xend then begin
            xnew = xnew + xstep
        endif else begin
            xnew = xstart
            ynew = ynew - ystep
        endelse
    endfor
    device, /close
    set_plot, mydevice
end