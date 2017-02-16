#!/usr/bin/env bash

set -e

macbuild() {
	rm -rf build dist
	if [[ "$1" = "sdist" ]]; then
		python3 setup.py sdist bdist_wheel
	else
		python3 setup.py bdist_wheel
	fi
	python3 setup.py install
	python3 test.py
}

if [[ -z "$DOCKER_IMAGE" && "$TRAVIS_OS_NAME" != "osx" ]]; then
	echo "Not a distributor."
	exit 0
elif [[ -z "$TRAVIS_TAG" ]]; then
	echo "Not a tag."
	exit 0
fi

pip3 -U install twine
openssl aes-256-cbc -K "$encrypted_0a601b1cd6e7_key" -iv "$encrypted_0a601b1cd6e7_iv" -in travis/.pypirc.enc -out .pypirc -d

if [[ "$DOCKER_IMAGE" ]]; then
	twine upload --config-file .pypirc -r pypi wheelhouse/*.whl
	echo "Successfully uploaded Linux wheels."
else
	curl -L 'https://github.com/Noctem/pogeo-toolchain/releases/download/1.0/macos-openssl-static.tar.xz' -o openssl-static.tar.xz
	tar -xf openssl-static.tar.xz
	export OPENSSL_ROOT_DIR="$(pwd)/openssl-static"
	macbuild sdist
	echo "Successfully uploaded Python 3.6 wheel and source."
	brew uninstall python3
	cd travis
	brew install python@3.5.rb
	echo "Successfully installed Python 3.5."
	cd ..
	macbuild
	pip3 -U install twine
	twine upload --config-file .pypirc -r pypi dist/*
	echo "Successfully uploaded Python 3.5 wheel."
fi
