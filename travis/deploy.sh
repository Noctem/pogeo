#!/usr/bin/env bash

set -e

macbuild() {
	pip3 install -U twine setuptools wheel
	rm -rf dist build
	if [[ "$1" = "sdist" ]]; then
		python3 setup.py sdist bdist_wheel
	else
		python3 setup.py bdist_wheel
	fi
	python3 setup.py install
	python3 test.py
	twine upload --skip-existing --config-file .pypirc -r pypi dist/*.whl dist/*.tar.gz
}

openssl aes-256-cbc -K "$encrypted_dc7bbf7cef27_key" -iv "$encrypted_dc7bbf7cef27_iv" -in travis/secrets.enc -out secrets.tar -d
tar -xf secrets.tar

if [[ "$DOCKER_IMAGE" ]]; then
	pip3 install -U twine
	twine upload --skip-existing --config-file .pypirc -r pypi wheelhouse/*.whl
	echo "Successfully uploaded Linux wheels."
else
	curl -L 'https://github.com/Noctem/pogeo-toolchain/releases/download/1.0/macos-openssl-static.tar.xz' -o openssl-static.tar.xz
	tar -xf openssl-static.tar.xz
	export OPENSSL_ROOT_DIR="$(pwd)/openssl-static"

	macbuild sdist
	echo "Successfully uploaded Python 3.6 wheel and source."

	cd travis
	brew uninstall python3
	brew install python35.rb
	cd ..
	echo "Successfully installed Python 3.5."

	pip3 install -U twine
	macbuild
	echo "Successfully uploaded Python 3.5 wheel."
fi
