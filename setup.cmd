@echo off

if "%Configuration%" == "Release" (
    set MODE=Release
) else (
    set MODE=Debug
)

if "%Platform%" == "x64" (
    :: set GENERATOR=Visual Studio 14 2015 Win64
    set GENERATOR=Visual Studio 15 2017 Win64
) else (
    :: set GENERATOR=Visual Studio 14 2015
    set GENERATOR=Visual Studio 15 2017
)

echo running in mode %MODE% ...
md %MODE%
cd %MODE%

:: setup
cmake .. -DCMAKE_BUILD_TYPE=%MODE% -DFIRST_ERROR=1 -G"%GENERATOR%"
cd ..
