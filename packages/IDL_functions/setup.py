import sys

# we should build this module in two steps:
# unix:
# 1. python setup.py build --fcompiler=gnu95
# 2. python setup.py install
# windows
# 1. python setup.py build --fcompiler=gnu95 --compiler=mingw32
# 2. python setup.py install

# Gather up all the files we need.
files = ['Src/IDL_Histogram.f90',]

## scypy_distutils Script
from numpy.distutils.core import setup, Extension
from numpy.distutils import fcompiler

# need to incorporate a complete fail and exit if the gnu95 compiler
# is not found.
avail_fcompilers = fcompiler.available_fcompilers_for_platform()
if ('gnu95' not in avail_fcompilers):
    print 'gnu95 compiler not found'
 
extra_compile_args=['--fcompiler=gnu95']
    
## setup the python module
setup(name="IDL_functions", # name of the package to import later
      ## Build fortran wrappers, uses f2py
      ext_modules = [Extension('_idl_histogram',
                               files,
#                              libraries=[],
#                              library_dirs=[],
#   			       include_dirs=['Src'],
#                               extra_compile_args=extra_compile_args,
                               ),
                     ],
      
##      ## Install these to their own directory
     package_dir={'IDL_functions':'Lib'},
     packages = ["IDL_functions"],
      
     )
