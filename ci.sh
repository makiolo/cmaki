#!/bin/bash
set -e

export CMAKI_PWD=$(pwd)

pip install --user pyyaml
pip install --user poster
pip install --user codecov

if [ -f "package.json" ]; then
  npm install npm-check-updates
  ./node_modules/.bin/ncu -u
  npm install
  npm test
else
  curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh | bash
  ./node_modules/cmaki/install.sh
  ./node_modules/cmaki/tests.sh
fi

if [ -f "cmaki.yml" ]; then
  # IDEA: interesting autogenerate cmaki.yml from package.json
  echo TODO: generate artifact and upload with cmaki_generator
fi
