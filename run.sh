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
# setup
cmake ../.. -DCMAKE_BUILD_TYPE=$MODE -DFIRST_ERROR=1 -G"$GENERATOR" -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DNOCACHE_REMOTE=$NOCACHE_REMOTE -DNOCACHE_LOCAL=$NOCACHE_LOCAL -DCOVERAGE=$COVERAGE 
# compile
cmake --build . --config $MODE --target install -- -j8 -k || cmake --build . --config $MODE --target install -- -j1
# pretests
if [[ "$CC" == "gcc" ]]; then
	if [[ "$MODE" == "Debug" ]]; then
		# initial coverage
		lcov -c -i -d ../.. -o coverage.base
	fi
fi
# execute tests
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V
# posttests
if [[ "$CC" == "gcc" ]]; then
	if [[ "$MODE" == "Debug" ]]; then
		# aggregate coverage
		lcov -c -d ../.. -o coverage.run
		# merge pre & run
		lcov -d ../.. -a coverage.base -a coverage.run -o coverage.info
		lcov -r coverage.info '/usr/*' -o coverage.info
		lcov -l coverage.info
		genhtml --no-branch-coverage -o coverage/ coverage.info
		bash <(curl -s https://codecov.io/bash) || echo "Codecov did not collect coverage reports"
		rm -f coverage.base coverage.run coverage.info
	fi
fi
