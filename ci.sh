#!/bin/bash
set -e
bash <(curl -s https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.sh)
CMAKI_PWD=$(pwd) ./node_modules/cmaki/install.sh
./node_modules/cmaki/tests.sh
