@echo off

pip install pyyaml
if %errorlevel% neq 0 exit /b %errorlevel%

pip install poster
if %errorlevel% neq 0 exit /b %errorlevel%

if exist node_modules\cmaki (rmdir /s /q node_modules\cmaki)
powershell -c "$source = 'https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.cmd'; $dest = $env:TEMP + '\bootstrap.cmd'; $WebClient = New-Object System.Net.WebClient; $WebClient.DownloadFile($source,$dest); Invoke-Expression $dest"
if %errorlevel% neq 0 exit /b %errorlevel%

set CMAKI_PWD=%CD%
call node_modules\cmaki\install.cmd
if %errorlevel% neq 0 exit /b %errorlevel%

call node_modules\cmaki\tests.cmd
if %errorlevel% neq 0 exit /b %errorlevel%
