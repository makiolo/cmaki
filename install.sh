#!/bin/bash
set -e
./node_modules/cmaki/clean.sh
./node_modules/cmaki/setup.sh
./node_modules/cmaki/compile.sh

