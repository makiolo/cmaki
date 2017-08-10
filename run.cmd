@echo off

if "%Configuration%" == "Release" (
	set MODE=Release
) else (
	set MODE=Debug
)

if "%Platform%" == "x64" (
  set GENERATOR=Visual Studio 14 2015 Win64
) else (
	set GENERATOR=Visual Studio 14 2015
)

cd cmaki
git pull origin master
cd ..

cd cmaki_generator
git pull origin master
cd ..

echo running in mode %MODE% ...
md %MODE%
cd %MODE%
cmake .. -DCMAKE_BUILD_TYPE=%MODE% -DFIRST_ERROR=1 -G"%GENERATOR%"
cmake --build . --config %MODE% --target install
ctest . --no-compress-output --output-on-failure -T Test -C %MODE% -V
cd ..
