'''
Created on 28/10/2011

@author: u08087
'''
#def pstring(string = ""):
#    print string

#a = [0,1,2,3]
#for i in a:
 #   if i == 2:
  #      print 'number two'
   # print i, a[i]
   
"""
pr ='PROJCS["UTM Zone 55, Southern Hemisphere",\n\
       GEOGCS["WGS 84",DATUM["WGS_1984",\n\
       SPHEROID["WGS 84",6378137,298.257223563,\n\
       AUTHORITY["EPSG","7030"]],\n\
       TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6326"]],\n\
       PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],\n\
       UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9108"]],\n\
       AUTHORITY["EPSG","4326"]],PROJECTION["Transverse_Mercator"],\n\
       PARAMETER["latitude_of_origin",0],\n\
       PARAMETER["central_meridian",147],\n\
       PARAMETER["scale_factor",0.9996],\n\
       PARAMETER["false_easting",500000],\n\
       PARAMETER["false_northing",10000000],\n\
       UNIT["Meter",1]]'
print pr
"""



def one():
    global logfile
    logfile.write('Function One\n\n')
    print 'one'

def two():
    global logfile
    logfile.write('Function Two\n')
    print 'two'

def three():
    global logfile
    value = ('Number', 666)
    logfile.write(str(value) + '\n')
    
def four():
    global logfile
    value = ('Number', 666)
    s = str(value)
    logfile.write(s + '\n')
    
def five():
    global logfile
    value = 666.666
    logfile.write('Number: %d\n' %value)

def six():
    global logfile
    value = 666.6666666666666666
    logfile.write('Number: %f\n' %value)

def seven():
    global logfile
    value = 666.6666666666666666
    #logfile.write('Number: %tile %f\n' %value)
    logfile.write('Number: percentile %f\n' %value)


def Main():  
    
    global logfile  
    logfile = open(r'H:\globals_test.txt', 'w')
    logfile.write('Start\n')

    one()
    two()
    three()
    four()
    five()
    six()
    seven()

    logfile.write('End\n')
    logfile.close()
    
    return "called"

if __name__ == "__main__":

    Main()

