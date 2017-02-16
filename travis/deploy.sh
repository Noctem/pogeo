#!/usr/bin/env bash

set -e

macbuild() {
	pip3 -U install twine setuptools wheel
	rm -rf dist build
	if [[ "$1" = "sdist" ]]; then
		python3 setup.py sdist bdist_wheel
	else
		python3 setup.py bdist_wheel
	fi
	python3 setup.py install
	python3 test.py
	for FILE in dist/*.whl dist/*.tar.gz; do
		gpg2 --batch --passphrase "$GPG_PASSPHRASE" -u 0x7F327613EF1E6B94 --yes --no-tty -o "${FILE}.asc" --sign "$FILE"
	done
	twine upload --config-file .pypirc -r pypi dist/*.whl dist/*.asc dist/*.tar.gz
}

openssl aes-256-cbc -K "$encrypted_dc7bbf7cef27_key" -iv "$encrypted_dc7bbf7cef27_iv" -in travis/secrets.enc -out secrets.tar -d
tar -xf secrets.tar

if [[ "$DOCKER_IMAGE" ]]; then
	pip3 install -U twine
	gpg2 --fast-import signing.asc
	for FILE in wheelhouse/*.whl; do
		gpg2 --batch --passphrase "$GPG_PASSPHRASE" -u 0x7F327613EF1E6B94 --yes --no-tty -o "${FILE}.asc" --sign "$FILE"
	done
	twine upload --config-file .pypirc -r pypi wheelhouse/*.whl wheelhouse/*.asc
	echo "Successfully uploaded Linux wheels."
else
	brew install gnupg2
	gpg2 --fast-import signing.asc

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

	macbuild
	pip3 install -U twine
	echo "Successfully uploaded Python 3.5 wheel."
fi
