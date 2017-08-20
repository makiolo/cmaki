#!/bin/bash
set -e

env | sort

NODE_PATH="${NODE_PATH:-.}"
$NODE_PATH/node_modules/cmaki/clean.sh
$NODE_PATH/node_modules/cmaki/setup.sh
$NODE_PATH/node_modules/cmaki/compile.sh

