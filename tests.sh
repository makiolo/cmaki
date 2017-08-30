#!/bin/bash
export NOCACHE_REMOTE="${NOCACHE_REMOTE:-FALSE}"
export NOCACHE_LOCAL="${NOCACHE_LOCAL:-FALSE}"
export NOCODECOV="${NOCODECOV:-FALSE}"
export COVERAGE="${COVERAGE:-FALSE}"
export CPPCHECK="${CPPCHECK:-FALSE}"
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"
export MODE="${MODE:-Debug}"

echo "running in mode $MODE ... ($CC / $CXX)"
mkdir -p $CC/$MODE
cd $CC/$MODE

# tests
ctest . --no-compress-output --output-on-failure -T Test -C $MODE -V
code=$?

# posttests
if [ "$COVERAGE" == "TRUE" ]; then
	if [[ "$CC" == "gcc" ]]; then
		if [[ "$MODE" == "Debug" ]]; then
			find ../.. -name "*.gcno" -o -name "*.gcda"
			lcov -c -i -d ../.. -o coverage.base
			# aggregate coverage
			lcov -c -d ../.. -o coverage.run
			# merge pre & run
			lcov -d ../.. -a coverage.base -a coverage.run -o coverage.info
			lcov -r coverage.info '/usr/*' -o coverage.info
			lcov -r coverage.info 'tests/*' -o coverage.info
			lcov -r coverage.info 'gtest/*' -o coverage.info
			lcov -r coverage.info 'gmock/*' -o coverage.info
			lcov -r coverage.info 'node_modules/*' -o coverage.info
			# lcov -l coverage.info
			genhtml --no-branch-coverage -o ../../coverage/ coverage.info
			if [ "$NOCODECOV" == "FALSE" ]; then
				bash <(curl -s https://codecov.io/bash) || echo "Codecov did not collect coverage reports"
			fi
			rm -f coverage.base coverage.run coverage.info
		fi
	fi
fi

if [ "$CPPCHECK" == "TRUE" ]; then
	if [[ "$CC" == "gcc" ]]; then
		if [[ "$MODE" == "Debug" ]]; then
			cppcheck -i ../../node_modules -i ../../$CC --inconclusive --check-config --max-configs=10 --enable=all -UDEBUG --inline-suppr ../..
		fi
	fi
fi

exit $code
