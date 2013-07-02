Recommend using gnu95 as the fortran compiler.

Instructions for windows
building the package:
python setup.exe build --compiler=mingw32 --fcompiler=gnu95

installing the package:
python setup.exe install
use --prefix= /dir/to/install to install to a specific location. Defaults to the site-applications of your python
install path

If installing to the default python location, admin rights might be needed.


Instructions for UNIX/Linux
building the package:
python setup.exe build --fcompiler=gnu95

installing the package:
python setup.exe install
use --prefix= /dir/to/install to install to a specific location. Defaults to the site-applications of your python
install path

If installing to the default python location, super user rights may be needed, eg
sudo python setup.exe install