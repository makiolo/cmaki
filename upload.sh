#!/bin/bash -e
YMLFILE=$(pwd)/cmaki.yml
(cd node_modules/cmaki_generator && ./build --yaml=${YMLFILE} -o --server=http://artifacts.myftp.biz:8080)
