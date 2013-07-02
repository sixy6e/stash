function tile_stddev, a

dims = size(a, /dimensions)
cnt = n_elements(a)
cnt2 = cnt -1
sum = 0.
sum2 = 0.
;m = mean(a)

for i=0, dims[1]-1 do begin
    sum += total(a[*,i])
    sum2 += total(a[*,i]^2)
endfor

m = sum/cnt
print, m
;std = sqrt(sum2/cnt2-(m)^2)
std = sqrt((sum2 - cnt * m^2)/cnt2)

;for i=0, dims[1]-1 do begin
;    diff = (a[*,i] - m)^2
;    sum += total(diff)
;endfor

;std = sqrt(sum/cnt)

return, std
end
