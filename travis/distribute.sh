#!/usr/bin/env bash

set -e

if [[ -z "$DOCKER_IMAGE" && -z "$DIST" ]]; then
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
else
	rm -rf dist build
	curl 'https://github.com/Noctem/pogeo-toolchain/releases/download/1.0/macos-openssl-static.tar.xz' -o openssl-static.tar.xz
	tar -xf openssl-static.tar.xz
	export OPENSSL_ROOT_DIR="$(pwd)/openssl-static"
	python3 setup.py sdist bdist_wheel
	python3 setup.py install
	python3 test.py
	twine upload --config-file .pypirc -r pypi dist/*
fi
