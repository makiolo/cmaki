@echo off
set GENERATOR=Visual Studio 14 2015
set MODE=Debug
echo running in mode %MODE% ...
md %MODE%
cd %MODE%
cmake .. -DCMAKE_BUILD_TYPE=%MODE% -DFIRST_ERROR=1 -G"%GENERATOR%"
cmake --build . --config %MODE% --target install
ctest . --no-compress-output --output-on-failure -T Test -C %MODE% -V
cd ..
