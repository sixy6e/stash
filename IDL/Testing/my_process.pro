PRO my_process_define_buttons, buttonInfo
;
;   Basic Tools ->
;   My Menu ->
;      Option 1
;      Option 2
;      --------
;      Option 3
;   Classification ->
;

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'My Menu', $  
   /MENU, REF_VALUE = 'Basic Tools', /SIBLING, POSITION = 'after'  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 1', $  
   UVALUE = 'option 1', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'My Menu', POSITION = 'last'  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 2', $  
   UVALUE = 'option 2', EVENT_PRO = 'my_process_event', $   
   REF_VALUE = 'My Menu', POSITION = 'last'  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 3', $  
   UVALUE = 'option 3', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'My Menu', POSITION = 'last', /SEPARATOR

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'New Tools', $  
   /MENU, REF_VALUE = 'Preprocessing', REF_INDEX = 0, $  
   POSITION = 'last'  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Tool 1', $  
   UVALUE = 'tool 1', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'New Tools', POSITION = -1  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Tool 2', $  
   UVALUE = 'tool 2', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'New Tools', POSITION = -1  
;  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'New Tools', $  
   /MENU, REF_VALUE = 'Preprocessing', REF_INDEX = 1, $  
   POSITION = 'last'  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Tool 1', $  
   UVALUE = 'tool 1', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'New Tools', REF_INDEX = 1, POSITION = -1  
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Tool 2', $  
   UVALUE = 'tool 2', EVENT_PRO = 'my_process_event', $  
   REF_VALUE = 'New Tools', REF_INDEX = 1, POSITION = -1  

ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'My Menu', $
   REF_VALUE = 'Vector', /menu 
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 1', $
   UVALUE = 'option 1', EVENT_PRO = 'my_process_event', $
   REF_VALUE = 'My Menu', POSITION = 'last', REF_INDEX = 1
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 2', $
   UVALUE = 'option 2', EVENT_PRO = 'my_process_event', $
   REF_VALUE = 'My Menu', POSITION = 'last', REF_INDEX = 1
ENVI_DEFINE_MENU_BUTTON, buttonInfo, VALUE = 'Option 3', $
   UVALUE = 'option 3', EVENT_PRO = 'my_process_event', $
   REF_VALUE = 'My Menu', POSITION = 'last', /SEPARATOR, REF_INDEX = 1


END

pro my_process

end