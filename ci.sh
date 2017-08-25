#!/bin/bash
set -e

echo [0/3] preinstall
export CMAKI_PWD=$(pwd)
env | sort

if [ "$EUID" -e 0 ]; then
  pip install --user pyyaml
  pip install --user poster
  pip install --user codecov
fi

if [ -f "package.json" ]; then

  echo [1/3] prepare
  if [ "$EUID" -e 0 ]; then
	npm install -g npm-check-updates
	ncu -u
  else
	echo skipping execute "ncu" because not is root
  fi

  echo [2/3] compile
  npm install

  echo [3/3] run tests
  npm test
else
  echo [1/3] prepare
  curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh | bash

  echo [2/3] compile
  ./node_modules/cmaki/install.sh

  echo [3/3] run tests
  ./node_modules/cmaki/tests.sh
fi

if [ -f "cmaki.yml" ]; then
  echo [4/3] upload artifact
  # IDEA: interesting autogenerate cmaki.yml from package.json
  echo TODO: generate artifact and upload with cmaki_generator
fi

if [ -d "node_modules/.bin" ]; then
  echo list npm bin
  ls -ltr node_modules/.bin
fi
