#!/bin/bash
# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

# Simple script to download FortiSOAR IOC data and create CSV for import to Fidelis Endpoint

SERVER="fortisoar.local"
GUID="733a3587-a0d9-48c2-8e40-96579243ccca" # collection
USER="fidelis"
PASS="fidelispass"
ROOT="/var/www/html" # nginx on ubuntu, rhel uses /usr/share/nginx/html
TEMP="/tmp"

URL="https://${SERVER}/api/taxii/1/collections/${GUID}/objects"

curl -k --user "${USER}:${PASS}" -o "${TEMP}/fortisoar-sha256.json" "${URL}" || exit 1

jq -r '.objects[] | {value, confidence} | join(", ")' "${TEMP}/fortisoar-sha256.json" > "${ROOT}/fortisoar-sha256.csv"

rm -f "${TEMP}/fortisoar-sha256.json"
chown www-data:www-data "${ROOT}/fortisoar-sha256.csv"
chmod 644 "${ROOT}/fortisoar-sha256.csv"

