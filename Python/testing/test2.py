import numpy

def testa():
    a = numpy.arange(10)
    return a

def testb():
    b = numpy.arange(10,20)
    return b

def testab(a,b):
    ab = a + b
    return ab

def test_all():
    a = testa()
    b = testb()
    ab = testab(a,b)
    print ab
