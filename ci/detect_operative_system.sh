#!/bin/bash
export CMAKI_INSTALL="${CMAKI_INSTALL:-$CMAKI_PWD/bin}"
export PATH=$CMAKI_INSTALL:$PATH
export COMPILER_BASENAME=$(basename ${CC})

cmaki_identifier > /dev/null 2>&1
if [ "$?"-ne 0]; then
  echo $COMPILER_BASENAME
else
  cmaki_identifier
fi
