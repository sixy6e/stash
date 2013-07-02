pro test_case, x

CASE x OF
   '400': PRINT, 'one'
   'BSQ': PRINT, 'two'
   3: begin
      PRINT, 'three'
      print, x * 2
      break
      end
   'bsq': PRINT, 'four'
ENDCASE
end