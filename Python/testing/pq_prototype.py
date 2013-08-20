#!/usr/bin/env python

"""Pixel quality utilities.

Test implementation of pixel quality utilities.

Requires Python 2.6+.

Author: Roger Edberg (roger.edberg@ga.gov.au)
"""

import bits


# Dictionary defining significant bits for each pixel quality metric.

PQ_BITMASKS = {
    'MODLANDQA':  0b0000000000000011,
    'VIUTILITY':  0b0000000000111100,
    'AEROSOL':    0b0000000011000000,
    'ADJCLOUD':   0b0000000100000000,
    'BRDFCORR':   0b0000001000000000,
    'MIXEDCLOUD': 0b0000010000000000,
    'LANDWATER':  0b0011100000000000,
    'SNOWICE':    0b0100000000000000,
    'SHADOW':     0b1000000000000000,
}

# Dictionary mapping descriptions to values for each pixel quality metric.

PQ_VALUE_DICT = {
    'MODLANDQA': {
        'vi_produced_good_quality':   0b00,
        'vi_produced_check_other_qa': 0b01,
        'vi_produced_likely_cloud':   0b10,
        'pixel_not_produced':         0b11,
    },
  
    'VIUTILITY': {
        'highest_quality': 0b0000,
        'lower_quality_1': 0b0001,
        'lower_quality_2': 0b0010,
        'lower_quality_3': 0b0100,
        'lower_quality_4': 0b1000,
        'lower_quality_5': 0b1001,
        'lower_quality_6': 0b1010,
        'lowest_quality':  0b1100,
        'not_useful':      0b1101,
        'bad_L1B_data':    0b1110,
        'not_processed':   0b1111,
    },

    'AEROSOL': {
        'climatology': 0b00,
        'low':         0b01,
        'average':     0b10,
        'high':        0b11,
    },

    'ADJCLOUD': {
        'yes': 0b0,
        'no':  0b1,
    },

    'BRDFCORR': {
        'yes': 0b0,
        'no':  0b1,
    },

    'MIXEDCLOUD': {
        'yes': 0b0,
        'no':  0b1,
    },

    'LANDWATER': {
        'shallow_ocean':        0b000,
        'land':                 0b001,
        'shoreline':            0b010,
        'shallow_inland_water': 0b011,
        'ephemeral_water':      0b100,
        'deep_inland_water':    0b101,
        'continental_ocean':    0b110,
        'deep_ocean':           0b110,
    },

    'SNOWICE': { 
        'yes': 0b0,
        'no':  0b1,
    },

    'SHADOW': {
        'yes': 0b0,
        'no':  0b1,
    },
}




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
            self.x = 0b0100000000111011

        def test_bitmasks(self):
            m = sum([v for v in PQ_BITMASKS.itervalues()])
            self.assertEqual(bits.lowest_set(m), 0)
            self.assertEqual(bits.length(m), 16)
            self.assertEqual(m, 0b1111111111111111)

        def test_unpack(self):
            d = unpack(self.x)
            self.assertEqual(sorted(d.keys()), sorted(PQ_BITMASKS.keys()))
            self.assertEqual(d['MODLANDQA'], 0b11)
            self.assertEqual(d['VIUTILITY'], 0b1110)
            self.assertEqual(d['AEROSOL'], 0b00)
            self.assertEqual(d['SNOWICE'], 0b1)

        def test_pack(self):
            d = {
                'MODLANDQA':   0b01,
                'VIUTILITY':   0b0000,
                'AEROSOL':     0b00,
                'ADJCLOUD':    0b0,
                'BRDFCORR':    0b0,
                'MIXEDCLOUD':  0b0,
                'LANDWATER':   0b001,
                'SNOWICE':     0b0,
                'SHADOW':      0b0,
            }
            self.assertEqual(pack(d), 0b0000100000000001)

            d['SHADOW'] = 0b1
            self.assertEqual(pack(d), 0b1000100000000001)

            d['VIUTILITY'] = 0b1111
            d['MODLANDQA'] = 0b10
            self.assertEqual(pack(d), 0b1000100000111110)

            d['SHADOW'] = 0b0
            d['VIUTILITY'] = 0b0000
            d['MODLANDQA'] = 0b00
            d['LANDWATER'] = 0b000
            d['BRDFCORR'] = 0b1
            d['MIXEDCLOUD'] = 0b1
            self.assertEqual(pack(d), 0b0000011000000000)

        def test_check_pq_dict(self):
            # bad value (0b1011)
            self.assertEqual(check_pq_dict({'VIUTILITY': 0b1011}), False)
            self.assertEqual(check_pq_dict({'VIUTILITY': 0b1101}), True)


    unittest.main()


