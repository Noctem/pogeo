#!/usr/bin/env python3

from os import environ
from sys import platform

from setuptools import setup, Extension

libraries = None
macros = None
include_dirs = ['geometry', 'geometry/s2', 'geometry/util/math', 'include']

if platform == 'win32':
    macros = [('PTW32_STATIC_LIB', None)]
    libraries = ['pthreadVC2', 'Advapi32', 'User32']
    extra_args = None
elif platform == 'darwin':
    extra_args = ['-stdlib=libc++', '-std=c++11']
    environ['CFLAGS'] = ' '.join(extra_args)
else:
    extra_args = ['-std=c++11']
    environ['CFLAGS'] = ' '.join(extra_args)

libs = [('s2', {
        'language': 'c++',
        'macros': macros,
        'include_dirs': include_dirs,
        'extra_compile_args': extra_args,
        'extra_link_args': extra_args,
        'libraries': libraries,
        'sources': [
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
            'geometry/s2regionunion.cc']}),
        ('_urlencode', {
            'language': 'c++',
            'include_dirs': ['include'],
            'extra_compile_args': extra_args,
            'extra_link_args': extra_args,
            'sources': ['lib/_urlencode.cpp']})]

try:
    from Cython.Build import cythonize
    file_ext = 'pyx'
except ImportError:
    file_ext = 'cpp'

exts = [Extension('pogeo.altitude',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/altitude.' + file_ext],
                  language='c++'),
        Extension('pogeo.const',
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  sources=['pogeo/const.' + file_ext],
                  language='c++'),
        Extension('pogeo.cellcache',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/cellcache.' + file_ext],
                  language='c++'),
        Extension('pogeo.geocoder',
                  include_dirs=include_dirs,
                  sources=['pogeo/geocoder.' + file_ext],
                  language='c++'),
        Extension('pogeo.location',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/location.' + file_ext],
                  language='c++'),
        Extension('pogeo.loop',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/loop.' + file_ext],
                  language='c++'),
        Extension('pogeo.polygon',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/polygon.' + file_ext],
                  language='c++'),
        Extension('pogeo.polyline',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/polyline.' + file_ext],
                  language='c++'),
        Extension('pogeo.rectangle',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/rectangle.' + file_ext],
                  language='c++'),
        Extension('pogeo.utils',
                  define_macros=macros,
                  extra_compile_args=extra_args,
                  extra_link_args=extra_args,
                  include_dirs=include_dirs,
                  libraries=libraries,
                  sources=['pogeo/utils.' + file_ext],
                  language='c++')]

if file_ext == 'pyx':
    exts = cythonize(exts)

setup(name='pogeo',
      version='0.4.0',
      description='Fast geography package.',
      long_description='A fast C++ extension for calculating cell IDs and distances.',
      url="https://github.com/Noctem/pogeo",
      author='David Christenson',
      author_email='mail@noctem.xyz',
      license='Apache',
      classifiers=[
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'Operating System :: OS Independent',
          'Programming Language :: C++',
          'Programming Language :: Cython',
          'Programming Language :: Python :: 3',
          'Programming Language :: Python :: 3.5',
          'Programming Language :: Python :: 3.6',
          'Topic :: Scientific/Engineering :: GIS'],
      keywords='pogeo geography S2 distance geo geometry',
      libraries=libs,
      packages=['pogeo', 'pogeo.geo'],
      package_data={'pogeo': ['altitude.pxd', 'cellcache.pxd', 'const.pxd', 'location.pxd', 'loop.pxd', 'polygon.pxd', 'polyline.pxd', 'rectangle.pxd', 'utils.pxd'],
                    'pogeo.geo': '*.pxd'},
      ext_modules=exts)
