pro dispw3

    imgxsize = 400
    imgysize = 400
    scrlxsize = 256
    scrlysize = 256
    zmxsize = 200
    zmysize = 200

    window, xsize=imgxsize, ysize=imgysize, title='Image', /free, xpos=0, ypos=0
    window, xsize=scrlxsize, ysize=scrlysize, title='Scroll', /free, xpos=0, ypos=imgysize+33
    window, xsize=zmxsize, ysize=zmysize, title='Zoom', /free, xpos=scrlxsize+8, ypos=imgysize+33
end