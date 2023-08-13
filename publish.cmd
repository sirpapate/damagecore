@echo off
REM This script will create a GMA file and publish it to the workshop.

FOR /F "tokens=*" %%g IN ('jq ".id" .\addon.json') do (SET ID=%%g)

if "%ID%" == "" goto no-id

gmad create -folder .\ -out .\addon.gma

if "%1" == "-m" goto with-message
if "%1" == "-message" goto with-message
if "%1" == "-msg" goto with-message

if "%1" == "" goto without-message

:with-message
gmpublish.exe update -id %ID% -addon .\addon.gma [-changes %2]
goto after

:without-message
gmpublish.exe update -id %ID% -addon .\addon.gma
goto after

:no-id
echo "No ID found in addon.json"
goto after

:after
del .\addon.gma