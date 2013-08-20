#!/usr/bin/env python

import sys
import argparse
import unittest


def x(arg):
    """Simple function"

    """

    if arg == 0:
        return 11

    if arg % 2:
        return arg

    return arg + 1


def tester(verbose=False):
    """Simple test function using bare assertions

    """

    assert x(1) == 1
    assert x(2) == 3

    value = x(0)
    if value != 11:
        sys.exit('Ouch! x(%d) returned a bad value: %d' % (0, value))

    for i in xrange(1, 101, 2):
        assert x(i) == i

    for i in xrange(2, 102, 2):
        assert x(i) == i + 1


class XTest(unittest.TestCase):
    """Unit test class for the x function.

    More info at http://docs.python.org/library/unittest.html#module-unittest
    """

    def test_odd_arg(self):
        self.assertEqual(x(1), 1)
        self.assertEqual(x(3), 3)

        for i in xrange(1, 1001, 2):
            self.assertEqual(x(i), i)

    def test_even_arg(self):
        self.assertEqual(x(2), 3)

        for i in xrange(2, 1002, 2):
            self.assertEqual(x(i), i + 1)

    def test_zero_arg(self):
        self.assertEqual(x(0), 11)




if __name__ == '__main__':

    tester()

    unittest.main()
