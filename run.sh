#!/bin/bash
set -e
NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
# export CC="${CC:-clang}"
# export CXX="${CXX:-clang++}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE=${MODE:-Debug}

if [[ "$OSTYPE" == "cygwin" ]]; then
	PATH=$(cygpath "E:\dev\gtc1\bin\cmake-3.4.3-win32-x86\bin"):$PATH
	GENERATOR="MinGW Makefiles"
	CC=mingw32-gcc
	CXX=mingw32-g++
else
	GENERATOR="Unix Makefiles"
fi

# coverage in debug
if [[ "$COVERAGE" == "Debug" ]]; then
	COVERAGE=TRUE
else
	COVERAGE=FALSE
fi
if [ -d cmaki ]; then
	(cd cmaki && git pull origin master)
fi
if [ -d cmaki_generator ]; then
	(cd cmaki_generator && git pull origin master)
fi
if [ -d metacommon ]; then
	(cd metacommon && git pull origin master)
fi
echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE
if [ -f "../../conanfile.txt" ]; then
	conan install ../..
fi
cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL -DCOVERAGE=$COVERAGE 
# -DCOMPILER_RT_BUILD_SHARED_ASAN=ON
cmake --build . --config $MODE --target install -- -j8 -k || cmake --build . --config $MODE --target install -- -j1
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V
if [[ "$CC" == "gcc" ]]; then
	if [[ "$MODE" == "Debug" ]]; then
		# generate coverage reports in gcc Debug
		lcov --directory . --capture --output-file coverage.info  # capture coverage info
		lcov --remove coverage.info '/usr/*' --output-file coverage.info  # filter out system
		lcov --list coverage.info  # debug info
		bash <(curl -s https://codecov.io/bash) || echo "Codecov did not collect coverage reports"
	fi
fi
