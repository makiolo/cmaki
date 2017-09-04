#!/bin/bash -e
PACKAGE=$(basename $(pwd))
YMLFILE=$(pwd)/cmaki.yml
(cd node_modules/cmaki_generator && ./build ${PACKAGE} --yaml=${YMLFILE} -o --server=http://artifacts.myftp.biz:8080)
