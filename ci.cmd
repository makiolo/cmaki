@echo off

echo [0/3] preinstall
set CMAKI_PWD=%CD%

pip install pyyaml
if %errorlevel% neq 0 exit /b %errorlevel%

pip install poster
if %errorlevel% neq 0 exit /b %errorlevel%

if exist package.json (
  
  echo [1/3] prepare
  npm install npm-check-updates
  call node_modules\.bin\ncu -u
  
  echo [2/3] compile
  npm install
  if %errorlevel% neq 0 exit /b %errorlevel%
  
  echo [3/3] run tests
  npm test
  if %errorlevel% neq 0 exit /b %errorlevel%

) else (

  echo [1/3] prepare
  if exist node_modules\cmaki (rmdir /s /q node_modules\cmaki)
  powershell -c "$source = 'https://raw.githubusercontent.com/makiolo/cmaki/master/bootstrap.cmd'; $dest = $env:TEMP + '\bootstrap.cmd'; $WebClient = New-Object System.Net.WebClient; $WebClient.DownloadFile($source,$dest); Invoke-Expression $dest"
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo [2/3] compile
  call node_modules\cmaki\install.cmd
  if %errorlevel% neq 0 exit /b %errorlevel%

  echo [3/3] run tests
  call node_modules\cmaki\tests.cmd
  if %errorlevel% neq 0 exit /b %errorlevel%

)

if exist "cmaki.yml" (
  echo [4/3] upload artifact
  # IDEA: interesting autogenerate cmaki.yml from package.json
  echo TODO: generate artifact and upload with cmaki_generator
)
