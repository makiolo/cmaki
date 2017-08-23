#!/bin/bash
set -e
pip install --user pyyaml
pip install --user poster
pip install --user codecov
if [ -f "package.json" ]; then
  npm install -g npm-check-updates
  ncu -u
fi
bash <(curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh)
CMAKI_PWD=$(pwd) ./node_modules/cmaki/install.sh
./node_modules/cmaki/tests.sh
if [ -f "cmaki.yml" ]; then
  echo TODO: upload with cmaki_generator
fi
