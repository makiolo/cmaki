#!/bin/bash
set -e

export CMAKI_PWD="${CMAKI_PWD:-$PWD}"
export MODE="${MODE:-Debug}"
export CMAKI_IDENTIFIER_FOLDER=$CMAKI_PWD/cmaki_identifier
export PACKAGE=$(basename $(pwd))

# setup
$CMAKI_PWD/node_modules/cmaki/setup.sh

# compile
$CMAKI_PWD/node_modules/cmaki/compile.sh

