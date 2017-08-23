#!/bin/bash
set -e
pip install --user pyyaml
pip install --user poster
pip install --user codecov
if [ -f "package.json" ]; then
  npm install -g npm-check-updates
  ncu -u
  CMAKI_PWD=$(pwd) npm install
  npm test
else
  bash <(curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh)
  CMAKI_PWD=$(pwd) ./node_modules/cmaki/install.sh
  ./node_modules/cmaki/tests.sh
fi
if [ -f "cmaki.yml" ]; then
  # interesting autogenerate cmaki.yml from package.json (npm info)
  echo TODO: generate artifact and upload with cmaki_generator (npm run upload)
fi
