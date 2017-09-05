#!/bin/bash
set -e

export CMAKI_PWD="${CMAKI_PWD:-$PWD}"
export USE_CMAKI_IDENTIFIER=TRUE
export MODE="${MODE:-Debug}"
export CMAKI_IDENTIFIER_FOLDER=$CMAKI_PWD/cmaki_identifier
export PACKAGE=$(basename $(pwd))

# clean
$CMAKI_PWD/node_modules/cmaki/clean.sh

# setup
$CMAKI_PWD/node_modules/cmaki/setup.sh

# compile
$CMAKI_PWD/node_modules/cmaki/compile.sh

