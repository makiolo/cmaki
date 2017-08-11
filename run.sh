#!/bin/bash
set -e
./node_modules/cmaki/setup.sh
./node_modules/cmaki/compile.sh
./node_modules/cmaki/tests.sh

