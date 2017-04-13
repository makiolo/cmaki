#!/bin/bash
set -e
NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
# export CC="${CC:-clang}"
# export CXX="${CXX:-clang++}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE=${MODE:-Debug}

echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE

# tests
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V
# posttests
if [[ "$CC" == "gcc" ]]; then
	if [[ "$MODE" == "Debug" ]]; then
		find ../.. -name "*.cpp" -o -name "*.h"
		find ../.. -name "*.gcno" -o -name "*.gcda"
		lcov -c -i -d ../.. -o coverage.base
		# aggregate coverage
		lcov -c -d ../.. -o coverage.run
		# merge pre & run
		lcov -d ../.. -a coverage.base -a coverage.run -o coverage.info
		lcov -r coverage.info '/usr/*' -o coverage.info
		lcov -r coverage.info 'tests/*' -o coverage.info
		lcov -l coverage.info
		genhtml --no-branch-coverage -o ../../coverage/ coverage.info
		bash <(curl -s https://codecov.io/bash) || echo "Codecov did not collect coverage reports"
		rm -f coverage.base coverage.run coverage.info
	fi
fi

