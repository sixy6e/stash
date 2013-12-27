import sys

# we should build this module in three steps:
# Unix/Linux:
# 1. python setup.py build --fcompiler=gnu95
# 2. python test.py
# If all tests have passed, then it is ok to install.
# 3. python setup.py install

# Windows
# 1. python setup.py build --fcompiler=gnu95 --compiler=mingw32
# 2. python test.py
# If all tests have passed, then it is ok to install.
# 3. python setup.py install

# Use distutils setup rather than setuptools setup as we need to compile Fortran
# code using F2PY
from numpy.distutils.core import setup, Extension
from numpy.distutils import fcompiler

# TODO Need to incorporate a complete fail and exit if the gnu95 compiler
# is not found.
avail_fcompilers = fcompiler.available_fcompilers_for_platform()
if ('gnu95' not in avail_fcompilers):
    print 'gnu95 compiler not found'
 
extra_compile_args=['--fcompiler=gnu95']
    
## setup the python module
setup(name="IDL_functions", # name of the package to import later
      version='1.0',
      author='Josh Sixsmith',
      author_email='joshua.sixsmith@ga.gov.au, josh.sixsmith@gmail.com',
      # Build fortran wrappers, uses f2py
      #ext_modules = [Extension('_idl_histogram', ['Src/IDL_Histogram.f90'],
      #                          files,
      #                         libraries=[],
      #                         library_dirs=[],
      #  		       include_dirs=['Src'],
      #                         extra_compile_args=extra_compile_args,
      #                         ),
      ext_modules = [
                     Extension('_idl_histogram',['Src/IDL_Histogram.f90']),
                     Extension('IDL_functions.tests.unit_test_IDL_Hist',['tests/unit_test_IDL_Hist.f90'])
                    ],
      
     ## Install these to their own directory
     package_dir = {'IDL_functions':'Lib', 'IDL_functions/tests':'tests'},
     packages = ["IDL_functions", 'IDL_functions/tests'],
     test_suite = ['IDL_functions.tests.unit_test_IDL_histogram', 'IDL_functions.tests.unit_test_IDL_hist_equal', 'IDL_functions.tests.unit_test_IDL_array_indices', 'IDL_functions.tests.unit_test_IDL_bytscl', 'IDL_functions.tests.unit_test_IDL_region_grow']
     )

