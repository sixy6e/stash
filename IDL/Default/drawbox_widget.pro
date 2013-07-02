PRO Drawbox_Widget_Events, event

   ; This is the event handler for the draw widget graphics window.

      ; Deal only with DOWN, UP, and MOTION events.

   IF event.type GT 2 THEN RETURN

      ; Get the info structure.

   Widget_Control, event.top, Get_UValue=info, /No_Copy

      ; What kind of event is this?

   eventTypes = ['DOWN', 'UP', 'MOTION']
   thisEvent = eventTypes[event.type]

   CASE thisEvent OF

      'DOWN': BEGIN

            ; Turn motion events on for the draw widget.

         Widget_Control, info.drawID, Draw_Motion_Events=1

            ; Create a pixmap. Store its ID. Copy window contents into it.

         Window, /Free, /Pixmap, XSize=info.xsize, YSize=info.ysize
         info.pixID = !D.Window
         Device, Copy=[0, 0, info.xsize, info.ysize, 0, 0, info.wid]

            ; Get and store the static corner of the box.

         info.sx = event.x
         info.sy = event.y

         ENDCASE

      'UP': BEGIN

            ; Erase the last box drawn. Destroy the pixmap.

         WSet, info.wid
         Device, Copy=[0, 0, info.xsize, info.ysize, 0, 0, info.pixID]
         WDelete, info.pixID

            ; Turn draw motion events off. Clear any events queued for widget.

         Widget_Control, info.drawID, Draw_Motion_Events=0, Clear_Events=1

            ; Order the box coordinates.

         sx = Min([info.sx, event.x], Max=dx)
         sy = Min([info.sy, event.y], Max=dy)

            ; Here is where you do something useful with the box.
            ; For example purposes, I'll compute the average pixel
            ; value of the pixels enclosed by the box and print it.

         Print, 'Average Pixel Value of Pixels Enclosed by Box: ',$
            Total(info.image[sx:dx, sy:dy]) / N_Elements(info.image[sx:dx, sy:dy])

         ENDCASE

      'MOTION': BEGIN

            ; Here is where the actual box is drawn and erased.
            ; First, erase the last box.

         WSet, info.wid
         Device, Copy=[0, 0, info.xsize, info.ysize, 0, 0, info.pixID]

            ; Get the coodinates of the new box and draw it.

         sx = info.sx
         sy = info.sy
         dx = event.x
         dy = event.y
         PlotS, [sx, sx, dx, dx, sx], [sy, dy, dy, sy, sy], /Device, $
            Color=info.boxColor

         ENDCASE

   ENDCASE

      ; Store the info structure.

   Widget_Control, event.top, Set_UValue=info, /No_Copy
   END
   ;------------------------------------------------------------------



   PRO Drawbox_Widget

   ; This is the widget definition module for the program.

      ; Open an image data set.

   file = Filepath(SubDirectory=['examples','data'], 'ctscan.dat')
   OpenR, lun, file, /Get_Lun
   image = BytArr(256, 256)
   ReadU, lun, image
   Free_Lun, lun

   xsize = (Size(image))[1]
   ysize = (Size(image))[2]

      ; Create the TLB.

   tlb = Widget_Base(Title='Rubberband Box in a Widget Program')

      ; Create the draw widget graphics window. Turn button events ON.

   drawID = Widget_Draw(tlb, XSize=xsize, YSize=ysize, Button_Events=1)

      ; Realize widgets and make draw widget the current window.

   Widget_Control, tlb, /Realize
   Widget_Control, drawID, Get_Value=wid
   WSet, wid

      ; Load drawing color and display the image.

   boxColor = !D.N_Colors-1
   TVLCT, 255, 255, 0, boxColor
   TV, BytScl(Image, Top=boxColor-1)

      ; Create an "info" structure with information to run the program.

   info = { image:image, $      ; The image data.
            wid:wid, $          ; The window index number.
            drawID:drawID, $    ; The draw widget identifier.
            pixID:-1, $         ; The pixmap identifier (undetermined now).
            xsize:xsize, $      ; The X size of the graphics window.
            ysize:ysize, $      ; The Y size of the graphics window.
            sx:-1, $            ; The X value of the static corner of the box.
            sy:-1, $            ; The Y value of the static corner of the box.
            boxColor:boxColor } ; The rubberband box color.

      ; Store the info structure.

   Widget_Control, tlb, Set_UValue=info, /No_Copy

      ; Start the program going.

   XManager, 'drawbox_widget', tlb, /No_Block, $
      Event_Handler='DrawBox_Widget_Events'
   END