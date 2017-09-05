#!/bin/bash
set -e

export CMAKI_PWD="${CMAKI_PWD:-$PWD}"
export USE_CMAKI_IDENTIFIER=TRUE
export MODE="${MODE:-Debug}"
export CMAKI_IDENTIFIER_FOLDER=$CMAKI_PWD/cmaki_identifier
export PACKAGE=$(basename $(pwd))

# clean
$CMAKI_PWD/node_modules/cmaki/clean.sh

# identify
if [ "$PACKAGE" != "cmaki_identifier" ]; then
  echo ---------- identify platform ----------
  if [ ! -d "$CMAKI_IDENTIFIER_FOLDER" ]; then
    git clone https://github.com/makiolo/cmaki_identifier.git $CMAKI_IDENTIFIER_FOLDER
    cd $CMAKI_IDENTIFIER_FOLDER
    CMAKI_INSTALL=$CMAKI_PWD/node_modules/cmaki/ci npm install
    cd -
  fi
  $CMAKI_PWD/node_modules/cmaki/ci/$MODE/predef
  echo ---------------------------------------
fi

# setup
$CMAKI_PWD/node_modules/cmaki/setup.sh

# compile
$CMAKI_PWD/node_modules/cmaki/compile.sh
