#! /usr/bin/env python

import os
import sys
import argparse
import subprocess

def read_text_file(text_file=''):
    """
    Read text file into a list.
    Removes leading and trailing blanks and new line feeds.
    """
    if os.path.exists(text_file):
        f_open = open(text_file)
        f_read = f_open.readlines()
        f_open.close()
        f_strip = [i.strip() for i in f_read]
        return f_strip
    else:
        raise Exception('Error. No file with that name exists!')

def pbs_layout(L1T_scene, NBAR_out):

    text = """#!/bin/bash
#PBS -P v10
#PBS -q normal
#PBS -l walltime=02:00:00,ncpus=2,vmem=12940MB
#PBS -me
#PBS -M Joshua.Sixsmith@ga.gov.au

module load geotiff/1.3.0
module load hdf4/4.2.6_2012
module load proj
module load python/2.7.2
module load gdal/1.9.0

module use /short/v10/mitch-sys/opt/modules --append
module load py-dev-tools

export IMAGEPROCESSOR_ROOT=$/home/547/jps547/job_submissions/nbar/ga-neo-landsat-processor/
export OUTPUT_ROOT=%s

PYTHONPATH=$PYTHONPATH:$IMAGEPROCESSOR_ROOT:/short/v10/nbar/pyephem-3.7.5.1/lib/python2.7/site-packages

mkdir -p ${OUTPUT_ROOT}/work
mkdir -p ${OUTPUT_ROOT}/output

/home/547/jps547/job_submissions/nbar/ga-neo-landsat-processor/process.py --sequential --debug --work ${OUTPUT_ROOT}/work --process_level nbar --nbar-root ${OUTPUT_ROOT}/output --l1t %s
""" %(NBAR_out, L1T_scene)

    return text

def main(L1T_list, NBAR_list, dir_name, job_test):
    if (not os.path.exists(dir_name)):
        os.makedirs(dir_name)
    
    os.chdir(dir_name)

    l1t_dir_list  = read_text_file(text_file=L1T_list)
    nbar_dir_list = read_text_file(text_file=NBAR_list)
    
    for i in range(len(l1t_dir_list)):
        scene_id = l1t_dir_list[i].split(os.sep)[-1]
        job_name = os.path.join(dir_name, 'nbar_%s.bash' %scene_id)
        out_string = pbs_layout(l1t_dir_list[i], nbar_dir_list[i])
        out_file = open(job_name, 'w')
        out_file.write(out_string)
        out_file.close()

        # Check file existance
        if (not(os.path.exists(job_name))):
            print 'File %s does not exist (but should).' %job_name
            continue

        if job_test:
            print 'Checking correct qsub script calls:'
            print 'Testing qsub %s' %job_name
        else:
            subprocess.call(['qsub',job_name])

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Automatic PBS job submission for processing NBAR.')
    parser.add_argument('--l1t_list', required=True, help='Text file containing the list of input L1T directories')
    parser.add_argument('--nbar_list', required=True, help='Text file containing the list of NBAR output directories.')
    parser.add_argument('--job_dir', required=True, help='The directory from which to run/submit the jobs from.')
    parser.add_argument('--test', action='store_true', help='If set then the script will not submit any jobs. It will still create the actual job submission script file, but rather than submit, it will print the command line statement. Default = True.')

    parsed_args = parser.parse_args()

    l1t_list  = parsed_args.l1t_list
    nbar_list = parsed_args.nbar_list
    job_dir   = parsed_args.job_dir
    test      = parsed_args.test

    print 'Running in test mode?'
    print test
    print 'Input L1T list: %s' %l1t_list
    print 'Output NBAR directories: %s' %nbar_list
    print 'Jobs will be submitted from: %s' %job_dir
    main(l1t_list, nbar_list, job_dir, test)

