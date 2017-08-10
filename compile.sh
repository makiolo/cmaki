#!/bin/bash
set -e
NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE=${MODE:-Debug}

echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE

# compile
cmake --build . --config $MODE --target install -- -j8 -k VERBOSE=1 || cmake --build . --config $MODE --target install -- -j1 VERBOSE=1

