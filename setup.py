#!/usr/bin/env python3

from os import environ
from sys import platform

from setuptools import setup, Extension
from Cython.Build import cythonize

macros = [('NDEBUG', None)]
include_dirs = ['geometry', 'geometry/s2', 'geometry/util/math']

if platform == 'win32':
    extra_args = []
    macros.append(('PTW32_STATIC_LIB', None))
    libraries = ['pthreadVC2']
else:
    extra_args = ['-std=c++11', '-O3']
    libraries = None
    if 'MANYLINUX' in environ:
        extra_args.extend(['-static-libgcc', '-static-libstdc++'])
    if platform == 'darwin':
        extra_args.append('-stdlib=libc++')


pogeo = cythonize(Extension('pogeo',
                  define_macros = macros,
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
                      'pogeo.pyx'
                  ],
                  include_dirs = include_dirs,
                  language='c++'))

setup (name='pogeo',
       version='0.3.1',
       description='Fast geography package.',
       long_description='A fast C++ extension for calculating cell IDs and distances.',
       url="https://github.com/Noctem/pogeo",
       author='David Christenson',
       author_email='mail@noctem.xyz',
       classifiers=[
           'Development Status :: 4 - Beta',
           'Intended Audience :: Developers',
           'Operating System :: OS Independent',
           'Programming Language :: C++',
           'Programming Language :: Cython',
           'Programming Language :: Python :: 3',
           'Programming Language :: Python :: 3.3',
           'Programming Language :: Python :: 3.4',
           'Programming Language :: Python :: 3.5',
           'Programming Language :: Python :: 3.6',
           'Topic :: Scientific/Engineering :: GIS'
       ],
       keywords='pogeo geography S2 distance geo',
       ext_modules=pogeo)
