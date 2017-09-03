#!/bin/bash
set -e

export CMAKI_PWD="${CMAKI_PWD:-$PWD}"
$CMAKI_PWD/node_modules/cmaki/clean.sh
$CMAKI_PWD/node_modules/cmaki/setup.sh
$CMAKI_PWD/node_modules/cmaki/compile.sh

