@echo off

IF "%CMAKI_PWD%" EQU "" (
  echo CMAKI_PWD is empty
) ELSE (
  echo CMAKI_PWD have value: %CMAKI_PWD%
)

call node_modules\cmaki\clean.cmd

call node_modules\cmaki\setup.cmd
if %errorlevel% neq 0 exit /b %errorlevel%

call node_modules\cmaki\compile.cmd
if %errorlevel% neq 0 exit /b %errorlevel%
