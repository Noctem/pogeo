#!/usr/bin/env bash

set -e -x

if [[ "$(uname -m)" = i686 ]]; then
	TOOLCHAIN_URL='https://github.com/Noctem/pogeo-toolchain/releases/download/v1.1/centos5-toolchain-i686.tar.bz2'
	export LD_LIBRARY_PATH="/toolchain/lib:${LD_LIBRARY_PATH}"
	MFLAG="-m32"
else
	TOOLCHAIN_URL='https://github.com/Noctem/pogeo-toolchain/releases/download/v1.1/centos5-toolchain-x86-64.tar.bz2'
	export LD_LIBRARY_PATH="/toolchain/lib64:/toolchain/lib:${LD_LIBRARY_PATH}"
	MFLAG="-m64"
fi

curl -L "$TOOLCHAIN_URL" -o toolchain.tar.bz2
tar -C / -xf toolchain.tar.bz2

export PATH="/toolchain/bin:${PATH}"
export CFLAGS="-I/toolchain/include -static-libgcc -static-libstdc++ ${MFLAG}"
export CXXFLAGS="-I/toolchain/include -static-libgcc -static-libstdc++ ${MFLAG}"

# Compile wheels
for PIP in /opt/python/cp3*/bin/pip; do
	"$PIP" install -U cython
	"$PIP" wheel /io/ -w wheelhouse/
done

# Repair for manylinux compatibility
for WHL in wheelhouse/*.whl; do
	auditwheel repair "$WHL" -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/cp3*/bin; do
	"${PYBIN}/pip" install pogeo --no-index -f /io/wheelhouse
	"${PYBIN}/python" /io/test/test.py
done
