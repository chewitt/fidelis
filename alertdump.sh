#!/bin/bash

# Simple script for bulk dumping alert PDFs between two dates from Fidelis CommandPost

HOST="x.x.x.x"       # hostname or IP address
USER="admin"         # username with API access
PASS="fidelis123$"   # password

SDATE="2022-01-01 00:00:00" # start dateTime of assessment
EDATE="2022-10-18 23:59:59" # end dateTime of assessment

# the commandpost maximum page size is 200,000 alerts in a single page
PSIZE="200000"

# obtain an access_token
TOKEN=$(curl -s -k -H "Content-Type:application/json;charset=UTF-8" \
             -X POST https://${HOST}/j/rest/v2/access/token/ \
             -d '{"user":"'"${USER}"'", "password":"'"${PASS}"'"}' | \
             jq -r '.access_token')

# find the total number of alerts between the s(tart)date and e(nd)date
TOTAL=$(curl -s -k -H "Content-Type:application/json;charset=UTF-8" \
             -X POST https://${HOST}/j/rest/v2/event/search \
             -H "x-uid: ${TOKEN}" \
             -d '{"allCommandPosts":false,"commandPosts":["Console"],"filter":{"composite":{"logic":"and","filters":[{"simple":{"column":"ALERT_ID","operator":">","value":"0"}}]}},"columns":["ALERT_ID"],"order":[{"column":"ALERT_TIME","direction":"DESC"}],"pagination":{"page":1,"size":"'"${PSIZE}"'"},"timeSettings":{"from":"'"${SDATE}"'","to":"'"${EDATE}"'","key":"custom","value":""},"groupBy":{"columns":[],"interval":"NA"}}' | \
             jq '.total')

# find and round up the number of pages to download
(( PAGES = ( ${TOTAL} / ${PSIZE} ) + 1 ))

# find the alertid(s) by iterating over all pages
PAGE=1
while [[ ${PAGE} -le ${PAGES} ]]; do
  ALERTLIST+=$(curl -s -k -H "Content-Type:application/json;charset=UTF-8" \
                   -X POST https://${HOST}/j/rest/v2/event/search \
                   -H "x-uid: ${TOKEN}" \
                   -d '{"allCommandPosts":false,"commandPosts":["Console"],"filter":{"composite":{"logic":"and","filters":[{"simple":{"column":"ALERT_ID","operator":">","value":"0"}}]}},"columns":["ALERT_ID"],"order":[{"column":"ALERT_TIME","direction":"DESC"}],"pagination":{"page":"'"${PAGE}"'","size":"'"${PSIZE}"'"},"timeSettings":{"from":"'"${SDATE}"'","to":"'"${EDATE}"'","key":"custom","value":""},"groupBy":{"columns":[],"interval":"NA"}}' | \
                   jq -r '.aaData[].ALERT_ID' | awk '{printf("%s ", $0)}')
  (( PAGE+=1 ))
done

# convert the list to an array and sort
ALERTS=($ALERTLIST)
IFS=$'\n' ALERTS=($(sort <<<"${ALERTS[*]}"))
unset IFS

# print how many alerts there are
echo "There are ${#ALERTS[@]} alerts to download"

# guesstimate the download time @ 6 seconds per document
SECS=( ${#ALERTS[@]} * 6 )
echo "Dumping is estimated to take $(date -d@${SECS} -u +%H:%M:%S) to complete"

# prompt for continue y/n
read -p "Continue? " -n 1 -r
echo # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# iterate through the alerts and download them
REMAINING=( ${#ALERTS[@]} )

for ALERTID in "${ALERTS[@]}" ; do
  (( REMAINING-=1 ))
  echo "Downloading alert-${ALERTID}.pdf / ${REMAINING} alerts remaining"
  curl -k -H "Content-Type:application/json;charset=UTF-8" \
       -X GET https://${HOST}/j/rest/v1/alert/export/alertdetails/pdf?alertIds=${ALERTID} \
       -H "x-uid: ${TOKEN}" > "alert-${ALERTID}.pdf"
  echo ""
done

exit 0
