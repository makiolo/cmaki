#!/bin/bash
export NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
export NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE="${MODE:-Debug}"
export CMAKI_INSTALL="${CMAKI_INSTALL:-$CMAKI_PWD/bin}"
export CMAKI_GENERATOR="${CMAKI_GENERATOR:-Unix Makefiles}"
export COVERAGE="${COVERAGE:-FALSE}"
export TESTS_VALGRIND="${TESTS_VALGRIND:-FALSE}"

echo "running in mode $MODE ... ($CC / $CXX)"
if [ -f "CMakeCache.txt" ]; then
	rm CMakeCache.txt
fi
if [ -d $CC/$MODE ]; then
	rm -Rf $CC/$MODE
fi
mkdir -p $CC/$MODE

# setup
cd $CC/$MODE
cmake ../.. -DCMAKE_INSTALL_PREFIX=$CMAKI_INSTALL -DCMAKE_BUILD_TYPE=$MODE -DFIRST_ERROR=1 -G"$CMAKI_GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL -D$COVERAGE -DTESTS_VALGRIND=$TESTS_VALGRIND
code=$?
exit $code
