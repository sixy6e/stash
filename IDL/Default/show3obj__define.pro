FUNCTION SHOW3OBJ::Init, data
self.data = ptr_new(data)
if !d.n_colors gt 256 then device, decomposed=0
loadct, 0, /silent
return, 1
END

PRO SHOW3OBJ::Cleanup
ptr_free, self.data
print, 'SHOW3OBJ object successfully destroyed.'
END

PRO SHOW3OBJ::Display
if ptr_valid(self.data) then show3, *self.data
END

PRO SHOW3OBJ::Loadcolor, index
loadct, index
self -> display
END

PRO SHOW3OBJ__define
namedStructure = {SHOW3OBJ, data:ptr_new()}
END