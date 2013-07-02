#! /usr/bin/env python

import os
import sys
import re
import datetime

logfile_list = ['ACCA_LOGFILE.txt',
                'FMASK_LOGFILE.txt',
                'ACCA_CLOUD_SHADOW_LOGFILE.txt',
                'FMASK_CLOUD_SHADOW_LOGFILE.txt']

# Returns the required line from a list of strings
def linefinder(array, string = ""):
    '''Searches a list for the specified string.

       Args:
           array: A list containing searchable strings.
           string: User input containing the string to search.

       Returns:
           The line containing the found sting.
    '''

    for line in array:
        if string in str(line):
            return line

for fname in logfile_list:
    f = open(fname, 'r')
    log = f.readlines()
    f.close()

# get ACCA percent
f = open(logfile_list[0], 'r')
acca_log = f.readlines()
f.close()
find  = linefinder(acca_log,'Final Cloud Layer Percent')
acca_percent = float(find.split()[-1])

#get Fmask percent
f = open(logfile_list[1], 'r')
fmask_log = f.readlines()
f.close()
find  = linefinder(fmask_log,'Final Cloud Layer Percent')
fmask_percent = float(find.split()[-1])

#get ACCA cloud shadow
f = open(logfile_list[2], 'r')
acca_cloud_shadow_log = f.readlines()
f.close()
find  = linefinder(acca_cloud_shadow_log,'Cloud Shadow Percent')
acca_cloud_shadow_percent = float(find.split()[-1])

#get Fmask cloud shadow
f = open(logfile_list[3], 'r')
fmask_cloud_shadow_log = f.readlines()
f.close()
find  = linefinder(fmask_cloud_shadow_log,'Cloud Shadow Percent')
fmask_cloud_shadow_percent = float(find.split()[-1])


#extract which tests have been run
fname = 'LS7_ETM_PQ_P55_GAPQ01-002_114_077_20020421_1111111111111100.tif'
tests_run = list((os.path.splitext(fname)[0]).split('_')[-1])

run_not_run = {'0' : 'Not Run',
               '1' : 'Run'
              }
sat = fname.split('_')[0]

sensor_test = {'LS5': LS5_band6_run_not_run[tests_run[6]],
             'LS7': run_not_run[tests_run[6]]
            }
LS5_band6_run_not_run = {'0' : 'Not Run',
                         '1' : 'Duplicated Band61'
                        }

sat_band1  = run_not_run[tests_run[0]]
sat_band2  = run_not_run[tests_run[1]]
sat_band3  = run_not_run[tests_run[2]]
sat_band4  = run_not_run[tests_run[3]]
sat_band5  = run_not_run[tests_run[4]]
sat_band61 = run_not_run[tests_run[5]]
sat_band62 = sensor_test[sat]
sat_band7  = run_not_run[tests_run[7]]
contiguity = run_not_run[tests_run[8]]
land_sea   = run_not_run[tests_run[9]]
acca       = run_not_run[tests_run[10]]
fmask      = run_not_run[tests_run[11]]
acca_shad  = run_not_run[tests_run[12]]
fmask_shad = run_not_run[tests_run[13]]
empty_1    = run_not_run[tests_run[14]]
empty_2    = run_not_run[tests_run[15]]


