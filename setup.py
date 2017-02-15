try:
    from setuptools import setup, Extension
except ImportError:
    from distutils.core import setup, Extension

from ctypes.util import find_library
from os.path import isdir, join, dirname
from os import environ
from sys import platform

extra_args = []

macros = [('S2_USE_EXACTFLOAT', None), ('ARCH_K8', None)]
include_dirs = ['geometry', 'geometry/s2', 'geometry/util/math']

if platform == 'win32':
    macros.append(('PTW32_STATIC_LIB', None))
    libraries = ['libeay32', 'pthreadVC2', 'Advapi32', 'User32']
    ssl_name = 'ssleay32'
else:
    if platform == 'darwin':
        extra_args = ['-stdlib=libc++', '-Wno-unused-local-typedef']
    else:
        extra_args.append('-Wno-ignore-qualifiers', '-fpermissive')
    extra_args.append('-std=c++11')
    libraries = ['ssl', 'crypto']
    ssl_name = 'ssl'

if 'OPENSSL_ROOT_DIR' in environ:
    openssl_dir = environ['OPENSSL_ROOT_DIR']
    openssl_libs = join(openssl_dir, 'lib')
elif 'OPENSSL_LIBS' in environ:
    openssl_libs = environ['OPENSSL_LIBS']
    openssl_dir = dirname(openssl_libs)
elif isdir('/usr/local/opt/openssl'):
    openssl_dir = '/usr/local/opt/openssl'
    openssl_libs = join(openssl_dir, 'lib')
else:
    openssl_lib = find_library(ssl_name)
    if not openssl_lib:
        if platform != 'win32':
            raise OSError('Could not find OpenSSL, please set OPENSSL_ROOT_DIR environment variable.')
        openssl_dir = None
    else:
        openssl_libs = dirname(openssl_lib)
        openssl_dir = dirname(openssl_libs)

if openssl_dir:
    library_dirs = [openssl_libs]
    include_dirs.append(join(openssl_dir, 'include'))
else:
    library_dirs = []

pogeo = Extension('pogeo',
                  define_macros = macros,
                  library_dirs = library_dirs,
                  libraries = libraries,
                  extra_compile_args = extra_args,
                  extra_link_args = extra_args,
                  sources = [
                      'geometry/base/int128.cc',
                      'geometry/base/logging.cc',
                      'geometry/base/stringprintf.cc',
                      'geometry/base/strtoint.cc',
                      'geometry/strings/split.cc',
                      'geometry/strings/stringprintf.cc',
                      'geometry/strings/strutil.cc',
                      'geometry/util/coding/coder.cc',
                      'geometry/util/coding/varint.cc',
                      'geometry/util/math/exactfloat/exactfloat.cc',
                      'geometry/util/math/mathlimits.cc',
                      'geometry/util/math/mathutil.cc',
                      'geometry/s1angle.cc',
                      'geometry/s2.cc',
                      'geometry/s2cellid.cc',
                      'geometry/s2latlng.cc',
                      'geometry/s1interval.cc',
                      'geometry/s2cap.cc',
                      'geometry/s2cell.cc',
                      'geometry/s2cellunion.cc',
                      'geometry/s2edgeindex.cc',
                      'geometry/s2edgeutil.cc',
                      'geometry/s2latlngrect.cc',
                      'geometry/s2loop.cc',
                      'geometry/s2pointregion.cc',
                      'geometry/s2polygon.cc',
                      'geometry/s2polygonbuilder.cc',
                      'geometry/s2polyline.cc',
                      'geometry/s2r2rect.cc',
                      'geometry/s2region.cc',
                      'geometry/s2regioncoverer.cc',
                      'geometry/s2regionintersection.cc',
                      'geometry/s2regionunion.cc',
                      'pogeo.cpp'
                  ],
                  include_dirs = include_dirs,
                  language='c++')

setup (name = 'pogeo',
       version = '0.1.1',
       description = 'Fast C++ extension for calculating cell IDs.',
       ext_modules = [pogeo])
