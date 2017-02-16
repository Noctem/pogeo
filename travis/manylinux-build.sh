#!/usr/bin/env bash

set -e -x

curl -L 'https://github.com/Noctem/pogeo-toolchain/releases/download/1.0/centos5-toolchain.tar.bz2' -o toolchain.tar.bz2

tar -C / -xf toolchain.tar.bz2

export PATH="/toolchain/bin:${PATH}"
export LD_LIBRARY_PATH="/toolchain/lib64:/toolchain/lib:${LD_LIBRARY_PATH}"
export CFLAGS="-I/toolchain/include -static-libgcc -static-libstdc++"
export CXXFLAGS="-I/toolchain/include -static-libgcc -static-libstdc++"
export OPENSSL_ROOT_DIR="/toolchain"

# Compile wheels
for PIP in /opt/python/cp3*/bin/pip; do
	"$PIP" wheel /io/ -w wheelhouse/
done

# Repair for manylinux compatibility
for WHL in wheelhouse/*.whl; do
	auditwheel repair "$WHL" -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/cp3*/bin; do
	"${PYBIN}/pip" install pogeo --no-index -f /io/wheelhouse
	"${PYBIN}/python" /io/test.py
done
