#!/bin/bash
NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE=${MODE:-Debug}

echo "running in mode $MODE ... ($CC / $CXX)"
cd $CC/$MODE

CORES=$(grep -c ^processor /proc/cpuinfo)
cmake --build . --config $MODE --target install -- -j$CORES -k VERBOSE=1 || cmake --build . --config $MODE --target install -- -j1 VERBOSE=1
code=$?
exit $code
