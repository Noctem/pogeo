#!/usr/bin/env bash

set -e

macbuild() {
	pip3 install -U setuptools wheel cython twine
	rm -rf dist build
	if [[ "$1" = "sdist" && "$SOURCE" = TRUE ]]; then
		python3 setup.py sdist bdist_wheel
		python3 setup.py install
		python3 test.py
		twine upload --skip-existing dist/*.whl dist/*.tar.*
	else
		python3 setup.py bdist_wheel
		python3 setup.py install
		python3 test.py
		twine upload --skip-existing dist/*.whl
	fi
}

if [[ "$DOCKER_IMAGE" ]]; then
	pip3 install -U twine
	twine upload --skip-existing wheelhouse/*.whl
	echo "Successfully uploaded Linux wheels."
else
	curl -L 'https://github.com/Noctem/pogeo-toolchain/releases/download/1.0/macos-openssl-static.tar.xz' -o openssl-static.tar.xz
	tar -xf openssl-static.tar.xz
	export OPENSSL_ROOT_DIR="$(pwd)/openssl-static"

	macbuild sdist
	echo "Successfully uploaded Python 3.6 wheel and source."

	brew uninstall python3
	brew install https://raw.githubusercontent.com/Noctem/pogeo-toolchain/master/python35.rb
	echo "Successfully installed Python 3.5."

	macbuild
	echo "Successfully uploaded Python 3.5 wheel."
fi
