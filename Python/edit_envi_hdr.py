#! /usr/bin/env python

import os
import numpy

# Author: Josh Sixsmith, joshua.sixsmith@ga.gov.au

def line_num_finder(array, string = "", offset=0):
    for i in (numpy.arange(len(array))+offset):
        if string in str(array[i]):
            return i

def edit_envi_hdr(envi_file, noData=None, band_names=None):
    """
    This is an older method of re-working an ENVI hdr file.
    3 other routines are now used and provide a more in-depth
    method of reading and writing ENVI hdr files.
    """
    hdr_fname = os.path.splitext(envi_file)[0] + '.hdr'
    # check file exists
    if os.path.exists(hdr_fname):
        # open hdr file for reading
        hdr_open = open(hdr_fname)
        hdr = hdr_open.readlines()
        # close the hdr file
        hdr_open.close()

        # find the number of bands. Used to check correct number of bnames
        fnb = line_num_finder(hdr, 'bands')
        sfind = hdr[fnb]
        nb  = int(sfind.split()[2])

        fbn = line_num_finder(hdr, 'band names')
        new_hdr = hdr[0:fbn+1]
        f_endbrace = line_num_finder(hdr, '}', offset=fbn)
        bn_stuff = hdr[fbn:f_endbrace+1]

        if band_names:
            if (len(band_names) != nb):
                raise Exception('Error, band names and number of bands do not match!')
            for i in range(1,nb+1):
                if (i == nb):
                    bname = band_names[i] + '}\n'
                else:
                    bname = band_names[i] + ',\n'
                new_hdr.append(bname)
        else:
            band_names = []
            for i in range(1,nb+1):
                if (i == nb):
                    band_names.append('Band %i}\n' %i)
                else:
                    band_names.append('Band %i,\n' %i)
            for bname in band_names:
                new_hdr.append(bname)

        # check that f_endbrace is the end of the file
        # if not, then get the extra stuff and append it
        hdr_len = len(hdr)
        if (hdr_len > (f_endbrace +1)):
            extra_hdr = hdr[f_endbrace+1]
            for i in range(len(extra_hdr)):
                new_hdr.append(extra_hdr[i])

        # append the data ignore value
        if noData:
            data_ignore = 'data ignore value = %s\n' %str(noData)
            new_hdr.append(data_ignore)

        # open the hdr file again for writing
        hdr_open = open(hdr_fname, 'w')

        for line in new_hdr:
            hdr_open.write(line)

        # close the hdr file
        hdr_open.close()

def read_envi_hdr(hdr_name=''):
    """
    Read the ENVI hdr file into a List.
    """
    if os.path.exists(hdr_name):
        hdr_open = open(hdr_name)
        hdr = hdr_open.readlines()
        hdr_open.close()
        return hdr
    else:
        raise Exception('Error. No file with that name exists!')

def modify_envi_dict(dict):
    """
    Modifies the specific keys (if they're existant within the dictionary.
    This function is called internally and is  therefore not necessary to be 
    called independently.
    Band names will be converted to a List. The band names and the description
    will have the {} characters removed. Leading and trailing blank spaces will
    also be removed from both keys.
    Using regular expression might be overkill, as all {} characters will
    be removed from each string.
    Numeric values for keys such as samples, lines, bands will be converted to
    integerse.
    This function can be expanded to include other ENVI header items that
    need reformatting.
    Also provides some basic input checks in regards to existance of necessary
    values such as samples, lines, bands.
    """
    if ('band names' in dict.keys()):
        bn = dict['band names'].split(',')
        bn  = [(re.sub('[{}]', '', item)).strip() for item in bn]
        dict['band names'] = bn
    if ('description' in dict.keys()):
        desc = dict['description']
        desc = (re.sub('[{}]', '', desc)).strip()
        dict['description'] = desc
    if ('samples' in  dict.keys()):
        dict['samples'] = int(dict['samples'])
    else:
        raise Exception('Error. The number of samples could not be found!')
    if ('lines' in dict.keys()):
         dict['lines'] = int(dict['lines'])
    else:
        raise Exception('Error. The number of lines could not be found!')
    if ('bands' in dict.keys()):
        dict['bands'] = int(dict['bands'])
    else:
        raise Exception('Error. The number of bands could not be found!')
    if ('byte order' in dict.keys()):
        dict['byte order'] = int(dict['byte order'])
    else:
        raise Exception('Error. The byte order could not be found!')
    if ('data type' in dict.keys()):
        dict['data type'] = int(dict['data type'])
    else:
        raise Exception('Error. The data type could not be found!')
    if ('header offset' in dict.keys()):
        dict['header offset'] = int(dict['header offset'])
    if ('x start' in dict.keys()):
        dict['x start'] = int(dict['x start'])
    if ('y start' in dict.keys()):
        dict['y start'] = int(dict['y start'])
    return dict

def create_envi_dict(hdr):
    """
    Create a dictionary containing the ENVI header information.
    Value modifications, and checks for required keys are handled in
    the modify_envi_dict() function. The dictionary is first parsed to
    modify_envi_dict() before being returned. 
    """
    if hdr[0].split()[0] != 'ENVI':
        raise Exception('Error. This is not a standard ENVI header file!')
    d = {}
    for line in range(1,len(hdr)):
        sp = hdr[line].split()
        if '=' in sp:
            idx = sp.index('=')
            key = sp[0]
            for i in range(1,idx):
                key = key + ' ' + sp[i]
            val = sp[idx+1]
            offset = idx+2
            for v in range(offset,len(sp[idx+2:])+offset):
                val = val + ' ' + sp[v]
            d[key] = val
        else:
            for v in range(len(sp)):
                val = val + ' ' + sp[v]
            d[key] = val
    d = modify_envi_dict(dict=d)
    return d

def prep_envi_header(dict):
    """
    Takes a dictionary containing ENVI header information and converts to a List
    in preperation for writing to disk.
    The key components are listed first, eg ENVI, description, samples, lines, 
    bands, then everything else with the band names coming last.
    """
    dict_cp = dict.copy()
    hdr_list = []
    hdr_list.append('ENVI\n')
    if ('description' in dict_cp):
        hdr_list.append('description = {\n')
        hdr_list.append(dict_cp['description'] + '}\n')
        del dict_cp['description']
    hdr_list.append('samples = %i\n' %(dict_cp['samples']))
    hdr_list.append('lines   = %i\n' %(dict_cp['lines']))
    hdr_list.append('bands   = %i\n' %(dict_cp['bands']))
    del dict_cp['samples'], dict_cp['lines'], dict_cp['bands']
    bn = False
    if ('band names' in dict_cp.keys()):
        bn = True
        bn_list = list(dict_cp['band names'])
        del dict_cp['band names']
        bn_list = [bname + ',\n' for bname in bn_list]
        bn_list[-1] = bn_list[-1].replace(',','}')
        bn_list.insert(0, 'band names = {\n')
    for key in dict_cp.keys():
        hdr_list.append('%s = %s\n' %(key, str(dict_cp[key])))
    if bn:
        hdr_list.extend(bn_list)
    return hdr_list

