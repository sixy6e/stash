PRO Savgol_example 
 
n = 401 ; number of points  
np = 4  ; number of peaks  
 
; Form the baseline:  
y = REPLICATE(0.5, n) 
 
; Sampling interval: 
dt = 0.1  
 
; Index the array:  
x = dt*FINDGEN(n) 
 
; Add each Gaussian peak:  
FOR i=0, np-1 DO BEGIN 
   c = dt*(i + 0.5) * FLOAT(n)/np; Center of peak  
   peak = 3 * (x-c) / (dt*(75. / 1.5 ^ i)) 
   ; Add Gaussian. Cutoff of -50 avoids underflow errors for  
   ; tiny exponentials:  
   y = y + EXP((-peak^2)>(-50))  
ENDFOR 
 
; Add noise:  
y1 = y + 0.10 * RANDOMN(-121147, n)  
 
; Display first plot 
iPlot, x, y1, NAME='Signal+Noise', VIEW_GRID=[1,2] 
 
; Get an object reference to the iTool and insert legend. 
void = ITGETCURRENT(TOOL=oTool) 
void = oTool->DoAction('Operations/Insert/Legend') 
 
iPlot, x, SMOOTH(y1, 33, /EDGE_TRUNCATE), /OVERPLOT, $ 
   COLOR=[255, 0, 0], $ 
   NAME='Smooth (width 33)' 
void = oTool->DoAction('Operations/Insert/LegendItem') 
 
; Savitzky-Golay with 33, 4th degree polynomial:  
savgolFilter = SAVGOL(16, 16, 0, 4) 
iPlot, x, CONVOL(y1, savgolFilter, /EDGE_TRUNCATE), /OVERPLOT, $ 
   COLOR=[0, 0, 255], THICK=2, $ 
   NAME='Savitzky-Golay (width 33, 4th degree)' 
void = oTool->DoAction('Operations/Insert/LegendItem') 
 
iPlot, x, DERIV(x, DERIV(x, y)), YRANGE=[-4, 2], /VIEW_NEXT, $ 
   NAME='Second derivative' 
 
void = oTool->DoAction('Operations/Insert/Legend') 
 
order = 2 
; Don't forget to normalize the coefficients. 
savgolFilter = SAVGOL(16, 16, order, 4)*(FACTORIAL(order)/ $ 
   (dt^order)) 
iPlot, x, CONVOL(y1, savgolFilter, /EDGE_TRUNCATE), /OVERPLOT, $ 
   COLOR=[0, 0, 255], THICK=2, $ 
   NAME='Savitzky-Golay(width 33, 4th degree, order 2)' 
void = oTool->DoAction('Operations/Insert/LegendItem') 
 
END 