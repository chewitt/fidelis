#!/bin/bash

if [ -z $(which jq) ]; then
  echo "ERROR: This script requires jq!"
  exit 1
fi

APISERVER="FQDN"
APIUSER="USERNAME"
APIPASS="PASSWORD"

# obtain a valid authentication token
TOKEN=$(curl -sX GET --header 'Accept: application/json' "https://${APISERVER}/Endpoint/api/authenticate?Username=${APIUSER}&Password=${APIPASS}" | sed "s/{.*\"token\":\"\([^\"]*\).*}/\1/g")

# obtain the list of endpoints in JSON format
ENDPOINTS=$(curl -sX POST -H 'Content-Type: application/json' -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" -d '*' "https://${APISERVER}/Endpoint/api/endpoints/AdvQuery?accessType=0")

# parse the list of endpoints
echo "$ENDPOINTS" | jq ".data.entities[].hostName" | tr -d '"'
