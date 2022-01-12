@echo off

REM set api server/credential
set APIHOST="FQDN"
set APIUSER="USERNAME"
set APIPASS="PASSWORD"

REM clear old files
if exist endpoints.txt del /F endpoints.txt

REM obtain a valid authentication token
for /F "tokens=*" %%F in ('curl.exe -ksX GET -H "Accept: application/json" "https://%APIHOST%/Endpoint/api/authenticate?Username=%APIUSER%&Password=%APIPASS%" ^| jq-win64.exe -r ".data.token"') DO (
   set TOKEN=%%F
)

REM obtain endpoints list
for /F "tokens=*" %%E in ('curl.exe -ksX POST -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer %TOKEN%" -d "*" "https://%APIHOST%/Endpoint/api/endpoints/AdvQuery?accessType=0" ^| jq-win64.exe -r ".data.entities[].hostName"') DO (
   echo %%E >> endpoints.txt
)
