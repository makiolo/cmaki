#!/bin/bash
set -e
MODE=${1:-Debug}
COMPILER=${2:-clang}
if [[ $COMPILER == "clang" ]];
then
	export CC=clang-3.6
	export CXX=clang++-3.6
else
	export CC=gcc-4.9
	export CXX=g++-4.9
fi
echo "running in mode $MODE ... ($CC / $CXX)"
if [ -f "conanfile.txt" ];
then
	if [ ! -f "conanbuildinfo.cmake" ];
	then
		# fetch depends and generate conan cmake file
		conan install
	fi
fi
mkdir -p $CC/$MODE
cd $CC/$MODE
cmake ../.. -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_BUILD_TYPE=$MODE -DCMAKE_MODULE_PATH=$(pwd)/../../cmaki -DFIRST_ERROR=1
cmake --build . --config $MODE --target install -- -j8 -k || cmake --build . --config $MODE --target install -- -j1
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V

