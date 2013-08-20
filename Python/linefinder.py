'''
Created on 28/10/2011

@author: u08087
'''
def linefinder(array, string = ""):
    for line in array:
        if string in str(line):
            return line




