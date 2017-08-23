#!/bin/bash
set -e

export CMAKI_PWD=$(pwd)

pip install --user pyyaml
pip install --user poster
pip install --user codecov

if [ -f "package.json" ]; then

  echo [1/3] prepare
  npm install npm-check-updates
  ./node_modules/.bin/ncu -u

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
  # IDEA: interesting autogenerate cmaki.yml from package.json
  echo TODO: generate artifact and upload with cmaki_generator
fi
