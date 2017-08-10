@echo off
echo APPVEYOR_REPO_NAME = %APPVEYOR_REPO_NAME%
cd node_modules\cmaki_generator
build github://makiolo/design-patterns-cpp14 -o --server=http://artifacts.myftp.biz:8080
cd ..

