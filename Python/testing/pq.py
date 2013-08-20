#!/usr/bin/env python

"""Pixel quality utilities.

Test implementation of pixel quality utilities.

Requires Python 2.6+.

Author: Roger Edberg (roger.edberg@ga.gov.au)
"""

import bits
import pprint


# Dictionary defining significant bits for each pixel quality metric.

PQ_BITMASKS = {
    'Band1_Sat'      :  0b0000000000000001,
    'Band2_sat'      :  0b0000000000000010,
    'Band3_Sat'      :  0b0000000000000100,
    'Band4_Sat'      :  0b0000000000001000,
    'Band5_Sat'      :  0b0000000000010000,
    'Band6_Sat'      :  0b0000000000100000,
    'Band62_Sat'     :  0b0000000001000000,
    'Band7_Sat'      :  0b0000000010000000,
    'Contiguity'     :  0b0000000100000000,
    'Land'           :  0b0000001000000000,
    'Cloud'          :  0b0000110000000000,
    'Cloud_Shadow'   :  0b0011000000000000,
    'Topo_Shadow'    :  0b0100000000000000,
    'Adjacent_Cloud' :  0b1000000000000000,  
}

# Dictionary mapping descriptions to values for each pixel quality metric.

PQ_VALUE_DICT = {

    
    'Band1_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band2_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band3_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band4_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band5_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band6_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band62_Sat' : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    'Band7_Sat'  : {  'Saturated' : 0b0, 'Not_Saturated' : 0b1, },
    
    'Contiguity' : {  'NonContiguous' : 0b0, 'Contiguous' : 0b1, },
    'Land' : {  'Sea' : 0b0, 'Land' : 0b1, },
    
    'Cloud' : {
        'Definite_Cloud' : 0b00,
        'Probably_Cloud' : 0b01,
        'Probably_Clear' : 0b10,
        'Definite_Clear' : 0b11,
    },
        
    'Cloud_Shadow' : {
        'Definte_shadow'  : 0b00,
        'Probably_Shadow' : 0b01,                            
        'Probably_clear'  : 0b10,
        'Confident_Clear' : 0b11,
    },
    'Topo_Shadow'     : {  'T_Shadow' : 0b0, 'No_T_Shadow' : 0b1, },
    'Adjacent_Cloud'  : {  'Adjacent' : 0b0, 'Not_Adjacent' : 0b1, }, }
                          

       


def print_pq_dict(pqdict):
    """Prints a pixel quality dictionary.

    Arguments:
        pqdict: pixel quality dictionary
    """

    print '{' + ', '.join(['%s=%s' % (k, bin(v)) for (k, v) in pqdict.iteritems()]) + '}'


def unpack(pqvalue):
    """Unpack a 16-bit (integer) pixel quality value.

    Arguments:
        pqvalue: pixel quality value (usually a 16-bit integer)

    Returns:
        Dictionary containing unpacked values for each pixel quality metric.
    """

    return {k : ((pqvalue & v) >> bits.lowest_set(v)) for k,v in PQ_BITMASKS.iteritems()}


def pack(pqdict):
    """Pack a pixel quality dictionary into a 16-bit pixel quality value.

    Arguments:
        pqdict: pixel quality dictionary

    Returns:
         Packed pixel quality value (usually a 16-bit integer.)
    """

    return sum((v << bits.lowest_set(PQ_BITMASKS[k])) for k,v in pqdict.iteritems())
    

def check_pq_dict(pqdict):
    """Check pixel quality dimetric values.

    Arguments:
        pqdict: pixel quality dictionary

    Returns:
         True if the dictionary contains all required entries, otherwise False.
    """

    # TODO could provide other verification or reporting services, e.g.
    #      logging bad values.

    return all((v in PQ_VALUE_DICT[k].values()) for k,v in pqdict.iteritems())
    




if __name__ == '__main__':

    import unittest

    class PQTester(unittest.TestCase):

        def setUp(self):
            self.x = 0b0111000000111011

        def test_bitmasks(self):
            m = sum([v for v in PQ_BITMASKS.itervalues()])
            self.assertEqual(bits.lowest_set(m), 0)
            self.assertEqual(bits.length(m), 16)
            self.assertEqual(m, 0b1111111111111111)

        def test_unpack(self):
            d = unpack(self.x)
            
            print
            pprint.pprint(d)
            
            self.assertEqual(sorted(d.keys()), sorted(PQ_BITMASKS.keys()))
            self.assertEqual(d['Topo_Shadow'], 0b1)
            self.assertEqual(d['Cloud_Shadow'], 0b11)

        def test_pack(self):
            d = {
                'Band1_Sat'   : 0b1,
                'Topo_Shadow' : 0b0,
                'Cloud'       : 0b01,
                'Land'        : 0b0,
            }
            pq = pack(d)
            self.assertEqual(pack(d), 0b0000010000000001)

        def xxtest_check_pq_dict(self):
            # bad value (0b1011)
            self.assertEqual(check_pq_dict({'VIUTILITY': 0b1011}), False)
            self.assertEqual(check_pq_dict({'VIUTILITY': 0b1101}), True)


    unittest.main()


