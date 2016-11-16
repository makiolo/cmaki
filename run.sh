#!/bin/bash
set -e
MODE=${1:-Debug}

echo cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DCMAKE_MODULE_PATH=$(pwd)/../../cmaki -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL
NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
echo cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DCMAKE_MODULE_PATH=$(pwd)/../../cmaki -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL

if [[ "$OSTYPE" == "cygwin" ]]; then
	PATH=$(cygpath "E:\dev\gtc1\bin\cmake-3.4.3-win32-x86\bin"):$PATH
	GENERATOR="MinGW Makefiles"
	CC=mingw32-gcc
	CXX=mingw32-g++
else
	GENERATOR="Unix Makefiles"
fi

echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE
cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DCMAKE_MODULE_PATH=$(pwd)/../../cmaki -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL
cmake --build . --config $MODE --target install -- -j8 -k || cmake --build . --config $MODE --target install -- -j1
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V

