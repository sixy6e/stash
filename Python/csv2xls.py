#! /usr/bin/env python

"""
Converts csv files to excel (xls). Designed specifically for the DLCD project.
Looks for csv files in the specified directory.
Creates a single xls file with multiple tabs. Each tab named from a certain 
string found in the filename.

3rd party dependencies:
xlwt; http://pypi.python.org/pypi/xlwt/0.7.4

Created on 13/08/2012

@author: Josh Sixsmith, joshua.sixsmith@ga.gov.au
"""

import sys
import os
import fnmatch
import csv
import xlwt
import re

# Insert path
path = r'C:\WINNT\Profiles\u08087\My Documents\Staff\Alexis'

def locate(pattern, root):
    """ Finds files that match the given pattern.
    
        This will not search any sub-directories.
    
    Args:
        pattern: A string containing the pattern to search, eg '*.csv'
        root: The path directory to search
    
    Returns: A list of file-path name strings of files that match the given pattern.
    """
    
    matches = []
    for file in os.listdir(root):
        if fnmatch.fnmatch(file, pattern):
            matches.append(os.path.join(path, file))
           
    return matches


#------------------------------------------------------------------------------    
assert (os.path.exists(path)), "Folder path not found"
ext = '*.csv'
files = locate(ext, path)
book = xlwt.Workbook()

# excel has tab-name size limitations of 31 characters
n_match = '(_ACT_)|(_NSW_)|(_NT_)|(_QLD_)|(_SA_)|(_TAS_)|(_VIC_)|(_WA_)|(_ZERO_)'
tab_names = []
base_names = []

for n in range(len(files)):
    assert (os.path.exists(files[n])), "Path not valid"
    base_names.append(os.path.splitext(os.path.basename(files[n]))[0])
    find = re.search(n_match, base_names[n]) # will only find the first occurrence
    assert (type(find) != None), "String match not found for %s\n Possible matches %s" %(files[n], n_match)
    tab_names.append(find.group())
    # a small check for path existence. Should already be valid otherwise locate wouldn't find it.   
    csvread = csv.reader(open(files[n], 'r')) # Opening with default delimeter of ','
    sheet = book.add_sheet(tab_names[n])
    row = 0
    for line in csvread: # Reading line by line
        for col in range(len(line)): # Write each column value found
            sheet.write(row, col, line[col])
        row += 1

fn = re.search(n_match, base_names[0])
assert (type(find) != None), "String match not found for %s\n Possible matches %s" %(files[n], n_match)
fname = base_names[0][0:fn.start()+1] + 'area_stats.xls'
outname = os.path.join(path,fname)

book.save(outname)
            
    
