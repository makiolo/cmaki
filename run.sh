#!/bin/bash
set -e
MODE=${1:-Debug}
COMPILER=${2:-clang}
"${NOCACHE:?FALSE}"
if [[ $COMPILER == "clang" ]];
then
	export CC=clang-3.6
	export CXX=clang++-3.6
else
	export CC=gcc-4.9
	export CXX=g++-4.9
fi

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
cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DCMAKE_MODULE_PATH=$(pwd)/../../cmaki -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE=$NOCACHE
cmake --build . --config $MODE --target install -- -j8 -k || cmake --build . --config $MODE --target install -- -j1
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V

