#!/bin/sh

set -e

# Continuous integration script for Travis
echo "## Building and installing libs2..."
cmake -Ds2_build_testing=ON geometry
make -j3
sudo make install
ctest -V
