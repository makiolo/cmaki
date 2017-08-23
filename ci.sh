#!/bin/bash
set -e

export CMAKI_PWD=$(pwd)

pip install --user pyyaml
pip install --user poster
pip install --user codecov
if [ -f "package.json" ]; then
  npm install -g npm-check-updates
  ncu -u
  npm install
  npm test
else
  bash <(curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh)
  ./node_modules/cmaki/install.sh
  ./node_modules/cmaki/tests.sh
fi

if [ -f "cmaki.yml" ]; then
  # interesting autogenerate cmaki.yml from package.json (npm info)
  echo TODO: generate artifact and upload with cmaki_generator (npm run upload)
fi
