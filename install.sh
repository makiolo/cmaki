#!/bin/bash
set -e

export CMAKI_PWD="${CMAKI_PWD:-$PWD}"
export USE_CMAKI_IDENTIFIER=TRUE
export MODE="${MODE:-Debug}"
export CMAKI_IDENTIFIER_FOLDER=$CMAKI_PWD/cmaki_identifier

# clean
$CMAKI_PWD/node_modules/cmaki/clean.sh

# identify
echo ---------- identify platform ----------
git clone https://github.com/makiolo/cmaki_identifier.git $CMAKI_IDENTIFIER_FOLDER
cd $CMAKI_IDENTIFIER_FOLDER
CMAKI_INSTALL=$CMAKI_PWD/node_modules/cmaki/ci npm install
cd -
$CMAKI_PWD/node_modules/cmaki/ci/$MODE/predef
echo ---------------------------------------

# setup
$CMAKI_PWD/node_modules/cmaki/setup.sh

# compile
$CMAKI_PWD/node_modules/cmaki/compile.sh
