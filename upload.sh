#!/bin/bash -e
export CMAKI_PWD=$(pwd)
export PACKAGE=$(basename $CMAKI_PWD)
export YMLFILE=$CMAKI_PWD/cmaki.yml
export CMAKI_IDENTIFIER_FOLDER=cmaki_identifier

mkdir -p node_modules/cmaki

cd $(pwd)/node_modules/cmaki_generator

echo ---------- identify platform (in upload) ----------
if [ ! -d "$CMAKI_IDENTIFIER_FOLDER" ]; then
  git clone https://github.com/makiolo/cmaki_identifier.git $CMAKI_IDENTIFIER_FOLDER
  cd $CMAKI_IDENTIFIER_FOLDER # enter $(pwd)/node_modules/cmaki_generator/cmaki_identifier
  CMAKI_PWD=$(pwd) CMAKI_INSTALL=$CMAKI_IDENTIFIER_FOLDER/../../cmaki/ci npm install
  cd -
fi
$CMAKI_PWD/node_modules/cmaki/ci/$MODE/predef
echo ----------------------------------------------------

./build ${PACKAGE} --yaml=${YMLFILE} --server=http://artifacts.myftp.biz:8080
