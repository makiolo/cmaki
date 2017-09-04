#!/bin/bash -e
PROJECT_FOLDER=$(pwd)
(cd node_modules/cmaki_generator && ./build --rootdir=${PROJECT_FOLDER} -o --server=http://artifacts.myftp.biz:8080)
