#!/bin/bash

export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE="${MODE:-Debug}"
export CMAKI_INSTALL="${CMAKI_INSTALL:-$CMAKI_PWD/bin}"
export CMAKI_EMULATOR="${CMAKI_EMULATOR:-}"
# export PATH=$CMAKI_INSTALL:$PATH

ls $CMAKI_INSTALL
echo $CMAKI_EMULATOR $CMAKI_INSTALL/cmaki_identifier
echo $CMAKI_EMULATOR $CMAKI_INSTALL/cmaki_identifier

