'''
Created on 09/11/2011

@author: u08087
'''
def linesearch(array, string = ''):
    for i in range(len(array)):
        if string in array[i]:
            return array[i]

