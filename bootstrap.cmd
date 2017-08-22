@echo off
IF EXIST node_modules\cmaki (
  echo .
) else (
  md node_modules\cmaki
  cd node_modules && git clone -q https://github.com/makiolo/cmaki.git && cd ..
  cd node_modules/cmaki && rm -Rf .git && cd ..\..
)
