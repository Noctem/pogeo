#!/bin/sh -x
# Continuous integration script for Travis

echo "## Building and installing libs2..."
cmake -Ds2_build_testing=ON -Ds2_build_python=ON geometry
make -j3
sudo make install

if [ "${TRAVIS_OS_NAME}" = "linux" ]; then
	# We really want to use the system version of Python.  Travis'
	# has broken distutils paths, and assumes a virtualenv.
	PATH="/usr/bin:${PATH}"
	which python2.7
	python2.7 -V
	python2.7 -v -c 'import s2'
fi

ctest -V
