#!/bin/bash
set -e
export NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
export NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE=${MODE:-Debug}

GENERATOR="Unix Makefiles"

echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE
if [ -f "../../CMakeCache.txt" ]; then
	rm ../../CMakeCache.txt
fi

# setup
cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL

