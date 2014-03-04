#! /usr/bin/env python

import os
import sys
import argparse
import subprocess
import datetime
import numpy

#import pdb

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
        raise Exception('Error. No file with that name exists! filename: %s' %text_file)

def get_process_list(input_list, jobs=150, floor=False):
    """
    Groups several jobs per node.
    Returns a list containing the chunks to process on each node, and the number of jobs per chunk.
    """
    if floor:
        list_len = len(input_list)
        node_jobs = int(numpy.floor(list_len / float(jobs)))
        xstart = numpy.arange(0, list_len, node_jobs)
        proc_list = []
        for xstep in xstart:
            if xstep + node_jobs < list_len:
                xend = xstep + node_jobs
            else:
                xend = list_len
            proc_list.append((xstep, xend))
    else:
        list_len = len(input_list)
        node_jobs = int(numpy.ceil(list_len / float(jobs)))
        xstart = numpy.arange(0, list_len, node_jobs)
        proc_list = []
        for xstep in xstart:
            if xstep + node_jobs < list_len:
                xend = xstep + node_jobs
            else:
                xend = list_len
            proc_list.append((xstep, xend))
    return proc_list, node_jobs

def pbs_layout(walltime):

    text = """#!/bin/bash
#PBS -P v10
#PBS -q normal
#PBS -l walltime=%s,ncpus=1,mem=3GB
#PBS -me
#PBS -M Joshua.Sixsmith@ga.gov.au

module load python/2.7.3
module load gdal
module load proj

module use /projects/u46/opt/modules/modulefiles
#module load IDL_functions
#module load pyephem
#module load numexpr
module load datacube

#export IMAGEPROCESSOR_ROOT=$/home/547/jps547/job_submissions/nbar/head/ga-neo-landsat-processor


""" %(walltime)

    return text

def main(cell_list, job_dir, out_dir, job_test, jobs, floor):
    """
    The main level program.
    """

    # Create the job path directory if needed
    if (not os.path.exists(job_dir)):
        os.makedirs(job_dir)

    # Create the results directory if needed
    if (not os.path.exists(out_dir)):
        os.makedirs(out_dir)

    # Change to the job submission directory
    os.chdir(job_dir)

    # Get the process list
    cell_job_list  = read_text_file(text_file=cell_list)

    # Calculate the how many process groups are needed
    process_groups, node_jobs = get_process_list(input_list=cell_job_list, jobs=jobs, floor=floor)

    # Total time; allowing for an extra job to be computed
    total_time = str(datetime.timedelta(hours=0.5) + datetime.timedelta(hours=node_jobs*0.5))
    pbs_str    = pbs_layout(walltime=total_time)

    for group in process_groups:
        xs = group[0]
        xe = group[1]

        pbs_str = pbs_layout(walltime=total_time)
        job_str = ''

        for i in range(xs,xe):
            cell = cell_job_list[i]
            #pdb.set_trace()
            x_cell  = cell.split('_')[0]
            y_cell  = cell.split('_')[1]

            # Establish a sub-directory system containing each cell
            out_cell_dir = os.path.join(out_dir, cell)
            if (not os.path.exists(out_cell_dir)):
                os.makedirs(out_cell_dir)

            job_str = 'python /home/547/jps547/git_repositories/my_code/Python/testing/test_pqa_stacker.py -x %s -y %s -o %s \n' %(x_cell, y_cell, out_cell_dir)

            echo_str = "echo 'Prcessing Cell: %s'\n" %cell

            pbs_str = pbs_str + echo_str + job_str

        job_name = os.path.join(job_dir, 'job_group_%i_to_%i.bash' %(xs, xe))
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


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Automatic PBS job submission for datacube processing.')
    parser.add_argument('--cell_list', required=True, help='Text file containing the list of Cells to process')
    parser.add_argument('--job_dir', required=True, help='The directory from which to run/submit the jobs from.')
    parser.add_argument('--out_dir', required=True, help='The directory where results will be output to.')
    parser.add_argument('--test', action='store_true', help='If set then the script will not submit any jobs. It will still create the actual job submission script file, but rather than submit, it will print the command line statement. Default = True.')
    parser.add_argument('--jobs', default=100, type=int, help='How many jobs to run concurrently. Default is 100.')
    parser.add_argument('--floor', action='store_true', help='If set then the number of concurrent jobs will be determined by floor division. Flooring will potentially yield more concurrent jobs than specifed using the --jobs argument. Ceiling division will potentially yield less concurrent jobs (safer measure). Default is ceiling division.')

    parsed_args = parser.parse_args()

    cell_list = parsed_args.cell_list
    job_dir   = parsed_args.job_dir
    out_dir   = parsed_args.out_dir
    test      = parsed_args.test
    jobs      = parsed_args.jobs
    floor     = parsed_args.floor

    print 'Running in test mode?'
    print test
    print 'Input Cell list: %s' %cell_list
    print 'Jobs will be submitted from: %s' %job_dir
    print 'Results will be written to: %s' %out_dir
    print 'Number of concurrent jobs: %i' %jobs

    main(cell_list, job_dir, out_dir, test, jobs, floor)
