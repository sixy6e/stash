#! /usr/bin/env python

import os
import sys
import argparse
import subprocess


def pbs_layout(year_month):

    text = '''#!/bin/bash
#PBS -P v10
#PBS -q normal
#PBS -l walltime=07:00:00,ncpus=1,vmem=3GB
#PBS -me
#PBS -M Joshua.Sixsmith@ga.gov.au

module load geotiff/1.3.0
module load hdf4/4.2.6_2012
module load proj
module load python/2.7.1
module load gdal/1.9.0

python /home/547/jps547/python/separate_FC_products.py --indir /g/data/v10/FC/%s
''' %year_month

    return text

def main(year, dir_name, job_test):
    job_run_dir = os.path.join(dir_name, year)
    if (not os.path.exists(job_run_dir)):
        os.makedirs(job_run_dir)
    
    os.chdir(job_run_dir)
    
    month = ['-01','-02','-03','-04','-05','-06','-07','-08','-09','-10','-11','-12']
    year_month = []
    
    for i in month:
        year_month.append(year + i)
    
    for ym in year_month:
        fname = os.path.join(job_run_dir, 'fc_rename_%s.bash' %ym)
        out_string = pbs_layout(ym)
        out_file = open(fname, 'w')
        out_file.write(out_string)
        out_file.close()
    
        # Check file existance
        if (not(os.path.exists(fname))):
            print 'File %s does not exist (but should).' %fname
            continue

        #sys_call = 'qsub %s' %fname 
        #os.system(sys_call)

        if job_test:
            print 'Checking correct qsub script calls:'
            print 'Testing qsub %s' %fname
        else:
            subprocess.call(['qsub',fname])

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Automatic PBS job submission for renaming Fractional Cover products.')
    parser.add_argument('--year', required=True, type=str, help='The year that is to be processed.')
    parser.add_argument('--job_dir', required=True, help='The directory from which to run/submit the jobs from.')
    parser.add_argument('--test', action='store_true', help='If set then the script will not submit any jobs. It will still create the actual job submission script file, but rather than submit, it will print the command line statement. Default = True.')

    parsed_args = parser.parse_args()

    yr       = parsed_args.year
    job_dir  = parsed_args.job_dir
    test = parsed_args.test

    print 'Running in test mode?'
    print test
    print 'Processing year: %s' %yr
    print 'Jobs will be submitted from: %s' %job_dir
    main(yr, job_dir, test)

