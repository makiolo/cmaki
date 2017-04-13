#!/bin/bash
set -e
./cmaki/setup.sh
./cmaki/compile.sh
./cmaki/tests.sh

