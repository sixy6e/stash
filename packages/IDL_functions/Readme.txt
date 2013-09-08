Recommend using gnu95 as the fortran compiler.

Instructions for windows
building the package:
python setup.py build --compiler=mingw32 --fcompiler=gnu95

Testing the package:
python test.py
this should be run after building and prior to installation.
Installation can follow if all tests have passed

installing the package:
python setup.py install
use --prefix= /dir/to/install to install to a specific location. Defaults to the site-applications of your python
install path

If installing to the default python location, admin rights might be needed.


Instructions for UNIX/Linux
building the package:
python setup.py build --fcompiler=gnu95

Testing the package:
python test.py
this should be run after building and prior to installation.
Installation can follow if all tests have passed

installing the package:
python setup.py install
use --prefix= /dir/to/install to install to a specific location. Defaults to the site-applications of your python
install path

If installing to the default python location, super user rights may be needed, eg
sudo python setup.py install
