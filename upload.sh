#!/bin/bash -e
export PACKAGE=$(basename $(pwd))
export YMLFILE=$(pwd)/cmaki.yml

cd $(pwd)/node_modules/cmaki_generator

git clone https://github.com/makiolo/cmaki_identifier.git
cd cmaki_identifier
CMAKI_PWD=$(pwd) CMAKI_INSTALL=$(pwd)/../node_modules/cmaki/ci npm install
cd -

./build ${PACKAGE} --yaml=${YMLFILE} -o --server=http://artifacts.myftp.biz:8080
