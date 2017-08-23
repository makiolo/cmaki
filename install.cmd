@echo off

IF DEFINED CMAKI_PWD (
  set CMAKI_PWD=%CMAKI_PWD%
) ELSE (
  set CMAKI_PWD=%CD%
)

call %CMAKI_PWD%\node_modules\cmaki\clean.cmd
call %CMAKI_PWD%\node_modules\cmaki\setup.cmd || echo error in setup.cmd && exit /b
call %CMAKI_PWD%\node_modules\cmaki\compile.cmd || echo error in compile.cmd && exit /b
