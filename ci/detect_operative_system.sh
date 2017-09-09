#!/bin/bash
export CMAKI_INSTALL="${CMAKI_INSTALL:-$CMAKI_PWD/bin}"
export PATH=$CMAKI_INSTALL:$PATH
cmaki_identifier

