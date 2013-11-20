#! /usr/bin/env python

import os
import sys
import argparse
import subprocess
import datetime
import numpy

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

def get_process_list(input_list, jobs=150):
    """
    Groups several jobs per node.
    Returns a list containing the chunks to process on each node, and the number of jobs per chunk.
    """

    list_len = len(input_list)
    node_jobs = int(round(list_len / float(jobs)))
    xstart = numpy.arange(0, list_len, node_jobs)
    proc_list = []
    for xstep in xstart:
        if xstep + node_jobs < list_len:
            xend = xstep + node_jobs
        else:
            xend = list_len
        proc_list.append((xstep, xend))
    return proc_list, node_jobs

#def pbs_layout(L1T_scene, NBAR_out):
def pbs_layout(walltime):

    text = """#!/bin/bash
#PBS -P v10
#PBS -q normal
#PBS -l walltime=%s,ncpus=2,mem=12940MB
#PBS -me
#PBS -M Joshua.Sixsmith@ga.gov.au

module load python/2.7.3
module load hdf4/4.2.6
module load gdal
module load proj

module use /projects/u46/opt/modules/modulefiles
module load IDL_functions
module load pyephem
module load numexpr

export IMAGEPROCESSOR_ROOT=$/home/547/jps547/job_submissions/nbar/head/ga-neo-landsat-processor


""" %(walltime)

    return text

def main(L1T_list, NBAR_list, dir_name, job_test, jobs):
    if (not os.path.exists(dir_name)):
        os.makedirs(dir_name)
    
    os.chdir(dir_name)

    l1t_dir_list  = read_text_file(text_file=L1T_list)
    nbar_dir_list = read_text_file(text_file=NBAR_list)

    process_groups, node_jobs = get_process_list(input_list=l1t_dir_list, jobs=jobs)

    # Total time; allowing for an extra job to be computed
    total_time = str(datetime.timedelta(hours=1) + datetime.timedelta(hours=node_jobs))
    pbs_str    = pbs_layout(walltime=total_time)

    for group in process_groups:
        xs = group[0]
        xe = group[1]

        for i in range(xs,xe):
            BASE_OUT_ROOT = nbar_dir_list[i]
            WORK_ROOT     = os.path.join(BASE_OUT_ROOT, 'work')
            OUTPUT_ROOT   = os.path.join(BASE_OUT_ROOT, 'output')
            L1T_scene     = l1t_dir_list[i]

            if not (os.path.exists(WORK_ROOT)):
                os.makedirs(WORK_ROOT)
            if not (os.path.exists(OUTPUT_ROOT)):
                os.makedirs(OUTPUT_ROOT)

            nbar_str = '/home/547/jps547/job_submissions/nbar/head/ga-neo-landsat-processor/process.py --sequential --work %s --process_level nbar --nbar-root %s --l1t %s \n' %(WORK_ROOT, OUTPUT_ROOT, L1T_scene)

            echo_str = "echo 'Prcessing Scene: %s'" %L1T_scene

            pbs_str = pbs_str + nbar_str

        job_name = os.path.join(dir_name, 'nbar_group_%i_to_%i.bash' %(xs, xe))
        out_file = open(job_name, 'w')
        out_file.write(pbs_str)
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

    #for i in range(len(l1t_dir_list)):
    #    scene_id = l1t_dir_list[i].split(os.sep)[-1]
    #    job_name = os.path.join(dir_name, 'nbar_%s.bash' %scene_id)
    #    out_string = pbs_layout(l1t_dir_list[i], nbar_dir_list[i])
    #    out_file = open(job_name, 'w')
    #    out_file.write(out_string)
    #    out_file.close()

    #    # Check file existance
    #    if (not(os.path.exists(job_name))):
    #        print 'File %s does not exist (but should).' %job_name
    #        continue

    #    if job_test:
    #        print 'Checking correct qsub script calls:'
    #        print 'Testing qsub %s' %job_name
    #    else:
    #        subprocess.call(['qsub',job_name])

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Automatic PBS job submission for processing NBAR.')
    parser.add_argument('--l1t_list', required=True, help='Text file containing the list of input L1T directories')
    parser.add_argument('--nbar_list', required=True, help='Text file containing the list of NBAR output directories.')
    parser.add_argument('--job_dir', required=True, help='The directory from which to run/submit the jobs from.')
    parser.add_argument('--test', action='store_true', help='If set then the script will not submit any jobs. It will still create the actual job submission script file, but rather than submit, it will print the command line statement. Default = True.')
    parser.add_argument('--jobs', default=100, type=int, help='How many jobs to run concurrently.')

    parsed_args = parser.parse_args()

    l1t_list  = parsed_args.l1t_list
    nbar_list = parsed_args.nbar_list
    job_dir   = parsed_args.job_dir
    test      = parsed_args.test
    jobs      = parsed_args.jobs

    print 'Running in test mode?'
    print test
    print 'Input L1T list: %s' %l1t_list
    print 'Output NBAR directories: %s' %nbar_list
    print 'Jobs will be submitted from: %s' %job_dir
    print 'Number of concurrent jobs: %i' %jobs
    main(l1t_list, nbar_list, job_dir, test, jobs)

