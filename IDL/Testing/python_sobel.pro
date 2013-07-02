function python_sobel, img, Help=help

    if keyword_set(help) then begin
        print, 'function PYTHON_SOBEL img, Help=help'
        print, 'an equivalent version of pythons (sciypy ndimage package), '
        print, 'sobel filter, with mode=reflect.'
        return, -1
    endif 

    if n_elements(size(img, /dimensions)) ne 2 then message, 'Only 2D images are supported'
    xf = [[-1,0,1],[-2,0,2],[-1,0,1]]
    yf = [[1,2,1],[0,0,0],[-1,-2,-1]]

    cxf = convol(img, xf, /edge_truncate)
    cyf = convol(img, yf, /edge_truncate)

    sob = abs(complex(cxf,cyf))

    return, sob

end
