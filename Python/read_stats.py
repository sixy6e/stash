#! /usr/bin/env python

import os
import sys
import argparse

#Author: Josh Sixsmith; joshua.sixsmith@ga.gov.au

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser = argparse.ArgumentParser(description='Takes text file containing a list of file locations to individual text files and outputs a single text file containing the stats.  Assumes that line 1 is the header info.')

    parser.add_argument('-inf', help='Input file name.')
    parser.add_argument('-outf', help='Output file name.')

    parsed_args = parser.parse_args()
    infile = parsed_args.inf
    outfile = parsed_args.outf

    f = open(infile, 'r')
    mainf = f.readlines()
    f.close()

    outf = open(outfile, 'w')

    for line in mainf:
        if line == mainf[0]:
            f = open(line.rstrip(), 'r')
            data = f.readlines()
            f.close()
        else:
            f = open(line.rstrip(), 'r')
            h = f.readline()
            data += f.readlines()
            f.close()
  
    #print len(mainf)
    #print len(data)
    #print data[0]
    #print data[1]
    #print data[2]

    for statline in data:
        outf.write(statline)
        #print statline
    outf.close()



