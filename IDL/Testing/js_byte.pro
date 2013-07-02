function js_byte, img, MIN=min, MAX=max

m = 255./(max-min)
b = m*(-min)

scl = m*img + b

wh = where(scl gt 255)
scl[wh] = 255
wh = where(scl lt 0)
scl[wh] = 0

return, floor(scl)
end
