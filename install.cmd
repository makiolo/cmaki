@echo off

IF "%CMAKI_PWD%" EQU "" (
  echo CMAKI_PWD is empty
) ELSE (
  echo CMAKI_PWD have value: %CMAKI_PWD%
)

IF DEFINED CMAKI_PWD (
  echo CMAKI_PWD is defined
) ELSE (
  echo CMAKI_PWD is undefined
)

IF "%CMAKI_PWD2%" EQU "" (
  echo CMAKI_PWD2 is empty
) ELSE (
  echo CMAKI_PWD2 have value: %CMAKI_PWD2%
)

IF DEFINED CMAKI_PWD2 (
  echo CMAKI_PWD2 is defined
) ELSE (
  echo CMAKI_PWD2 is undefined
)

call node_modules\cmaki\clean.cmd

call node_modules\cmaki\setup.cmd
if %errorlevel% neq 0 exit /b %errorlevel%

call node_modules\cmaki\compile.cmd
if %errorlevel% neq 0 exit /b %errorlevel%
