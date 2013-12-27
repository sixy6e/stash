#!/usr/bin/env python

import os
import sys
import subprocess
import fnmatch

def locate(pattern, root):
    matches = []
    for path, dirs, files in os.walk(os.path.abspath(root)):
        for filename in fnmatch.filter(files, pattern):
            matches.append(os.path.join(path, filename))
    return matches

if __name__ == '__main__':
    dir_list = os.listdir(os.getcwd())
    if 'build' not in dir_list:
        print 'The build directory was not found. Please build the IDL_fucntions module first. Exiting...'
    else:
        # Change to the build directory
        os.chdir('build')

        # Find the unittest script
        test_file1 = locate('unit_test_IDL_histogram.py', os.getcwd())[0]
        test_file2 = locate('unit_test_IDL_hist_equal.py', os.getcwd())[0]
        test_file3 = locate('unit_test_IDL_array_indices.py', os.getcwd())[0]
        test_file4 = locate('unit_test_IDL_bytscl.py', os.getcwd())[0]
        test_file5 = locate('unit_test_IDL_region_grow.py', os.getcwd())[0]

        # Get the directory path that contains the unittest script and change to that directory
        dname = os.path.dirname(test_file1)
        os.chdir(dname)

        # Move up two directories from where unit_test_IDL_Hist.py was located
        os.chdir(os.pardir)
        os.chdir(os.pardir)

        # Now execute the unittest script from the command line
        subprocess.call(['python', test_file1])
        subprocess.call(['python', test_file2])
        subprocess.call(['python', test_file3])
        subprocess.call(['python', test_file4])
        subprocess.call(['python', test_file5])

