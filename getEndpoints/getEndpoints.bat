@ECHO off

REM set api server/credential
set APIHOST="FQDN"
set APIUSER="USERNAME"
set APIPASS="PASSWORD"

REM obtain a valid authentication token
curl.exe -ksX GET -H "Accept: application/json" "https://%APIHOST%/Endpoint/api/authenticate?Username=%APIUSER%&Password=%APIPASS%" --output "token.json"

REM parse the JSON to extract the token
jq-win64.exe -r ".data.token" token.json > token.plain

REM import the token to a variable
set /p TOKEN=<token.plain

REM obtain the list of endpoints in JSON format
curl.exe -ksX POST -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer %TOKEN%" -d "*" "https://%APIHOST%/Endpoint/api/endpoints/AdvQuery?accessType=0" --output "endpoints.json"

REM parse the JSON list of endpoints and output to endpoints.txt
jq-win64.exe -r ".data.entities[].hostName" endpoints.json > endpoints.txt
