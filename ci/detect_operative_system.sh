#!/bin/bash

export DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export MODE="${MODE:-Debug}"
$DIR_SCRIPT/$MODE/predef

